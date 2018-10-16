SAMPLES = ["OSD14"]

rule generate_otu_table:
    input:
        "{sample}/input_data/{sample}_R1.fastq.gz",
        "{sample}/input_data/{sample}_R2.fastq.gz"
    output:
        "{sample}/output/singlem_otu.tsv"
    threads:
        28
    message:
        "Executing singlem with {threads} threads on the following files: {input}."
    shell:
        "./appimages/singlem.AppImage pipe --sequences {input} --otu_table {output} --threads {threads}"

rule obtain_tax_list:
    input:
        expand("{sample}/output/singlem_otu.tsv", sample=SAMPLES)
    output:
        "{sample}/output/taxlist.txt",
    shell:
        "./main.py -v parse_singlem -t {input} -u {output}"

rule get_amplicon_proteome:
    input:
        expand("{sample}/output/taxlist.txt", sample=SAMPLES)
    output:
        touch("checkpoints/get_amplicon_proteome.done")
