SAMPLES = ["OSD14"]
ASSEMBLER = ["MEGAHIT"]

if "MEGAHIT" in ASSEMBLER:
    rule run_megahit:
        input:
            "{sample}/reads/{sample}_R1.fastq.gz",
            "{sample}/reads/{sample}_R2.fastq.gz"
        output:
            "{sample}/assembly/{sample}_contigs.fa"
        threads:
            28  
        message:
            "Executing MEGAHIT assembly with {threads} threads on the following input files: {input}, producing {output}."
        shell:
            """
            megahit -1 {input[0]} -2 {input[1]} --k-list 21,33,55,77,99,127 --memory 0.9 -t {threads} -o {wildcards.sample}/megahit --out-prefix {wildcards.sample}_megahit
            mv {wildcards.sample}/megahit/{wildcards.sample}_megahit.contigs.fa {output}
            rm -rf {wildcards.sample}/megahit
            """

elif "METASPADES" in ASSEMBLER:
    rule run_metaspades:
        input:
            "{sample}/reads/{sample}_R1.fastq.gz",
            "{sample}/reads/{sample}_R2.fastq.gz"
        output:
            "{sample}/assembly/{sample}_contigs.fa"
        threads:
            28
        message:
            "Executing metaSPAdes assembly with {threads} threads on the following input files: {input}, producing {output}."
        shell:
            """
            spades.py -1 {input[0]} -2 {input[1]}  -t {threads} -m 230 -o {wildcards.sample}/metaspades
            mv {wildcards.sample}/metaspades/contigs.fasta {output}
            rm -rf {wildcards.sample}/metaspades
            """

rule run_prodigal:
    input:
        "{sample}/assembly/{sample}_contigs.fa"
    output:
        "{sample}/proteome/{sample}_assembled.faa"
    shell:
        """
        prodigal -p meta -i {input} -o {output}.gbk -a {output} -q
        rm {output}.gbk
        """

rule get_assembled_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_assembled.faa", sample=SAMPLES)
    output:
        touch("checkpoints/assembled_proteome.done")
