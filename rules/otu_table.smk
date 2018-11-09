SAMPLES = ["OSD14"]

rule generate_otu_table:
    input:
        "input_data/{sample}_R1.fastq.gz",
        "input_data/{sample}_R2.fastq.gz"
    output:
        "output/{sample}_singlem_otu.tsv"
    threads:
        28
    message:
        "Executing singlem with {threads} threads on the following files: {input}."
    shell:
        "./appimages/singlem.AppImage pipe --sequences {input} --otu_table {output} --threads {threads}"

rule get_amplicon_proteome:
    input:
        expand("output/{sample}_singlem_otu.tsv", sample=SAMPLES)
    output:
        touch("checkpoints/get_amplicon_proteome.done")
