READS = ["R1", "R2"]

# rule create_train_dir:
#     input:
#         "/data/miniconda3/envs/mpies/bin/train/"
#     output:
#         "checkpoints/train_dir.done"
#     shell:
#         "ln -s {input} . && touch ${output}"

rule fastq2fasta:
    input:
        expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["samples"]),
        expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz",sample=config["samples"]),
        expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["samples"])
    output:
        temp(expand("{sample}/fasta_files/{sample}_R1_trimmed_pe.fasta", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/{sample}_R2_trimmed_pe.fasta", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/{sample}_trimmed_se.fasta", sample=config["samples"]))
    shell:
        """
        zcat {input[0]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[0]}
        zcat {input[1]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[1]}
        zcat {input[2]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[2]}
        """

rule run_fraggenescan:
    input:
        expand("{sample}/fasta_files/{sample}_R1_trimmed_pe.fasta", sample=config["samples"]),
        expand("{sample}/fasta_files/{sample}_R2_trimmed_pe.fasta", sample=config["samples"]),
        expand("{sample}/fasta_files/{sample}_trimmed_se.fasta", sample=config["samples"])
    output:
        temp(expand("{sample}/fasta_files/{sample}_R1_trimmed_pe_fgs.faa", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/{sample}_R2_trimmed_pe_fgs.faa", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/{sample}_trimmed_se_fgs.faa", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R1_trimmed_pe.ffn", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R2_trimmed_pe.ffn", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_trimmed_se.ffn", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R1_trimmed_pe.gff", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R2_trimmed_pe.gff", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_trimmed_se.gff", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R1_trimmed_pe.out", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R2_trimmed_pe.out", sample=config["samples"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_trimmed_se.out", sample=config["samples"]))
    params:
        train_file="illumina_1"
    log:
        log_r1=expand("{sample}/log/{sample}_fgs_r1.log", sample=config["samples"]),
        log_r2=expand("{sample}/log/{sample}_fgs_r2.log", sample=config["samples"]),
        log_se=expand("{sample}/log/{sample}_fgs_se.log", sample=config["samples"])
    threads:
        28
    shell:
        """
        run_FragGeneScan.pl -genome={input[0]} -out={config[samples]}/fasta_files/fgs_{config[samples]}_R1_trimmed_pe -complete=0 -train={params.train_file} -thread={threads} > {log.log_r1} 2>&1
        run_FragGeneScan.pl -genome={input[1]} -out={config[samples]}/fasta_files/fgs_{config[samples]}_R2_trimmed_pe -complete=0 -train={params.train_file} -thread={threads} > {log.log_r2} 2>&1
        run_FragGeneScan.pl -genome={input[2]} -out={config[samples]}/fasta_files/fgs_{config[samples]}_trimmed_se -complete=0 -train={params.train_file} -thread={threads} > {log.log_se} 2>&1
        mv {config[samples]}/fasta_files/fgs_{config[samples]}_R1_trimmed_pe.faa {output[0]}
        mv {config[samples]}/fasta_files/fgs_{config[samples]}_R2_trimmed_pe.faa {output[1]}
        mv {config[samples]}/fasta_files/fgs_{config[samples]}_trimmed_se.faa {output[2]}
        """

rule combine_results:
    input:
        expand("{sample}/fasta_files/{sample}_{read}_trimmed_pe_fgs.faa", read=READS, sample=config["samples"]),
        expand("{sample}/fasta_files/{sample}_trimmed_se_fgs.faa", sample=config["samples"]),
    output:
        temp(expand("{sample}/proteome/{sample}_unassembled.faa", sample=config["samples"]))
    shell:
        """
        cat {input} > {output}
        """

rule get_unassembled_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_unassembled.faa", sample=config["samples"])
    output:
        touch("checkpoints/unassembled_proteome.done")
