SAMPLES = ["OSD14"]
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
        "{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz",
        "{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz",
        "{sample}/trimmed/{sample}_trimmed_se.fastq.gz"
    output:
        "{sample}/reads_fasta/{sample}_R1_trimmed_pe.fasta",
        "{sample}/reads_fasta/{sample}_R2_trimmed_pe.fasta",
        "{sample}/reads_fasta/{sample}_trimmed_se.fasta"
    shell:
        """
        zcat {input[0]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[0]}
        zcat {input[1]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[1]}
        zcat {input[2]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[2]}
        """

rule run_fraggenescan:
    input:
        "{sample}/reads_fasta/{sample}_R1_trimmed_pe.fasta",
        "{sample}/reads_fasta/{sample}_R2_trimmed_pe.fasta",
        "{sample}/reads_fasta/{sample}_trimmed_se.fasta"
    output:
        "{sample}/reads_fasta/{sample}_R1_trimmed_pe_fgs.faa",
        "{sample}/reads_fasta/{sample}_R2_trimmed_pe_fgs.faa",
        "{sample}/reads_fasta/{sample}_trimmed_se_fgs.faa"
    params:
        train_file="illumina_1"
    log:
        log_r1="{sample}/log/{sample}_fgs_r1.log",
        log_r2="{sample}/log/{sample}_fgs_r2.log",
        log_se="{sample}/log/{sample}_fgs_se.log"
    threads:
        28
    shell:
        """
        run_FragGeneScan.pl -genome={input[0]} -out={wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R1_trimmed_pe -complete=0 -train={params.train_file} -thread={threads} > {log.log_r1} 2>&1
        run_FragGeneScan.pl -genome={input[1]} -out={wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R2_trimmed_pe -complete=0 -train={params.train_file} -thread={threads} > {log.log_r2} 2>&1
        run_FragGeneScan.pl -genome={input[2]} -out={wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_trimmed_se -complete=0 -train={params.train_file} -thread={threads} > {log.log_se} 2>&1
        mv {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R1_trimmed_pe.faa {output[0]}
        mv {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R2_trimmed_pe.faa {output[1]}
        mv {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_trimmed_se.faa {output[2]}
        """

rule combine_results:
    input:
        expand("{sample}/reads_fasta/{sample}_{read}_trimmed_pe_fgs.faa", read=READS, sample=SAMPLES),
        expand("{sample}/reads_fasta/{sample}_trimmed_se_fgs.faa", sample=SAMPLES),
    output:
        expand("{sample}/proteome/{sample}_unassembled.faa", sample=SAMPLES)
    shell:
        """
        cat {input} > {output}
        """
        # rm {input}
        # rm {wildcards.sample}/reads_fasta/*.ffn
        # rm {wildcards.sample}/reads_fasta/*.out
        # rm {wildcards.sample}/reads_fasta/*.gbk

rule get_unassembled_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_unassembled.faa", sample=SAMPLES)
    output:
        touch("checkpoints/unassembled_proteome.done")
