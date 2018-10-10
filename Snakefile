rule all:
    input:
        "input_data/{sample}_R1.fastq.gz",
        "input_data/{sample}_R2.fastq.gz"
    output:
        "output/{sample}_otu.tsv"
    shell:
        "singlem pipe --sequences {input} --otu_table {output}"