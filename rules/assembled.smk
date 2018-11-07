ASSEMBLER = ["METASPADES"]

if "MEGAHIT" in ASSEMBLER:
    rule run_megahit:
        input:
            expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["samples"]),
            expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["samples"]),
            expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["samples"])
        output:
            expand("{sample}/assembly/{sample}_contigs.fa", sample=config["samples"]),
            temp(directory(expand("{sample}/megahit/", sample=config["samples"])))
        params:
            klist="21,33,55,77,99,127",
            memory=0.9
        log:
            expand("{sample}/log/{sample}_megahit.log", sample=config["samples"])
        threads:
            28  
        shell:
            """
            megahit -1 {input[0]} -2 {input[1]} -r {input[2]} --k-list {params.klist} --memory {params.memory} \
            -t {threads} -o output[1] --out-prefix {config[samples]}_megahit > {log} 2>&1
            mv {config[samples]}/megahit/{config[samples]}_megahit.contigs.fa {output[0]}
            """

elif "METASPADES" in ASSEMBLER:
    rule run_metaspades:
        input:
            expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["samples"]),
            expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["samples"]),
            expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["samples"])
        output:
            expand("{sample}/assembly/{sample}_contigs.fa", sample=config["samples"]),
            temp(directory(expand("{sample}/metaspades/", sample=config["samples"])))
        params:
            memory=230
        log:
            expand("{sample}/log/{sample}_metaspades.log", sample=config["samples"])
        threads:
            28
        shell:
            """
            spades.py -1 {input[0]} -2 {input[1]} -s {input[2]} -t {threads} -m {params.memory} -o {output[1]} \
              > {log} 2>&1
            mv {config[samples]}/metaspades/contigs.fasta {output[0]}
            """

rule run_prodigal:
    input:
        expand("{sample}/assembly/{sample}_contigs.fa", sample=config["samples"])
    output:
        temp(expand("{sample}/proteome/{sample}_assembled.faa", sample=config["samples"])),
        temp(expand("{sample}/proteome/{sample}_assembled.gbk", sample=config["samples"]))
    params:
        mode="meta"
    shell:
        """
        prodigal -p {params.mode} -i {input} -o {output[1]} -a {output[0]} -q
        """

rule get_assembled_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_assembled.faa", sample=config["samples"])
    output:
        touch("checkpoints/assembled_proteome.done")
