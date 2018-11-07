if config["assembled"]["assembler"] == "MEGAHIT":
    rule run_megahit:
        input:
            expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
        output:
            expand("{sample}/assembly/{sample}_contigs.fa", sample=config["sample"])
        params:
            klist=config["assembled"]["run_megahit"]["klist"],
            memory=config["ressources"]["megahit_memory"]
        log:
            expand("{sample}/log/{sample}_megahit.log", sample=config["sample"])
        threads:
            config["ressources"]["threads"]
        shell:
            """
            megahit -1 {input[0]} -2 {input[1]} -r {input[2]} --k-list {params.klist} --memory {params.memory} \
              -t {threads} -o {config[sample]}/megahit/ --out-prefix {config[sample]}_megahit > {log} 2>&1
            mv {config[sample]}/megahit/{config[sample]}_megahit.contigs.fa {output}
            rm -rf {config[sample]}/megahit/
            """

elif config["assembled"]["assembler"] == "METASPADES":
    rule run_metaspades:
        input:
            expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
        output:
            expand("{sample}/assembly/{sample}_contigs.fa", sample=config["sample"])
        params:
            memory=config["ressources"]["metaspades_memory"]
        log:
            expand("{sample}/log/{sample}_metaspades.log", sample=config["sample"])
        threads:
            config["ressources"]["threads"]
        shell:
            """
            spades.py -1 {input[0]} -2 {input[1]} -s {input[2]} -t {threads} -m {params.memory} \
              -o {config[sample]}/metaspades/ > {log} 2>&1
            mv {config[sample]}/metaspades/contigs.fasta {output}
            rm -rf {config[sample]}/metaspades/
            """

rule run_prodigal:
    input:
        expand("{sample}/assembly/{sample}_contigs.fa", sample=config["sample"])
    output:
        temp(expand("{sample}/proteome/{sample}_assembled.faa", sample=config["sample"])),
        temp(expand("{sample}/proteome/{sample}_assembled.gbk", sample=config["sample"]))
    params:
        mode=config["assembled"]["prodigal"]["mode"]
    shell:
        """
        prodigal -p {params.mode} -i {input} -o {output[1]} -a {output[0]} -q
        """

rule get_assembled_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_assembled.faa", sample=config["sample"])
    output:
        touch("checkpoints/assembled_proteome.done")

