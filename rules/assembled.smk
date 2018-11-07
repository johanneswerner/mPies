SAMPLES = ["OSD14subset"]
ASSEMBLER = ["MEGAHIT"]

if "MEGAHIT" in ASSEMBLER:
    rule run_megahit:
        input:
            "{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz",
            "{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz",
            "{sample}/trimmed/{sample}_trimmed_se.fastq.gz"
        output:
            "{sample}/assembly/{sample}_contigs.fa"
        params:
            klist="21,33,55,77,99,127",
            memory=0.9
        log:
            "{sample}/log/{sample}_megahit.log"
        threads:
            28  
        shell:
            """
            megahit -1 {input[0]} -2 {input[1]} -r {input[2]} \
              --k-list {params.klist} --memory {params.memory} -t {threads} \
              -o {wildcards.sample}/megahit --out-prefix {wildcards.sample}_megahit > {log} 2>&1
            mv {wildcards.sample}/megahit/{wildcards.sample}_megahit.contigs.fa {output}
            rm -rf {wildcards.sample}/megahit
            """

elif "METASPADES" in ASSEMBLER:
    rule run_metaspades:
        input:
            "{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz",
            "{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz",
            "{sample}/trimmed/{sample}_trimmed_se.fastq.gz"
        output:
            "{sample}/assembly/{sample}_contigs.fa"
        params:
            memory=230
        log:
            "{sample}/log/{sample}_metaspades.log"
        threads:
            28
        shell:
            """
            spades.py -1 {input[0]} -2 {input[1]} -s {input[2]} -t {threads} \
              -m {params.memory} -o {wildcards.sample}/metaspades > {log} 2>&1
            mv {wildcards.sample}/metaspades/contigs.fasta {output}
            rm -rf {wildcards.sample}/metaspades
            """

rule run_prodigal:
    input:
        "{sample}/assembly/{sample}_contigs.fa"
    output:
        temp("{sample}/proteome/{sample}_assembled.faa"),
        temp("{sample}/proteome/{sample}_assembled.gbk")
    params:
        mode="meta"
    shell:
        """
        prodigal -p {params.mode} -i {input} -o {output[1]} -a {output[0]} -q
        """

rule get_assembled_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_assembled.faa", sample=SAMPLES)
    output:
        touch("checkpoints/assembled_proteome.done")
