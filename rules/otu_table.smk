SAMPLES = ["OSD14"]

rule generate_otu_table:
    input:
        "input_data/{sample}_R1.fastq.gz",
        "input_data/{sample}_R2.fastq.gz"
    output:
        "output/{sample}_otu.tsv"
    shell:
        "singlem pipe --sequences {input} --otu_table {output}"

rule get_amplicon_proteome:
    input:
        expand("output/{sample}_otu.tsv", sample=SAMPLES)
    output:
        touch("checkpoints/get_amplicon_proteome.done")
