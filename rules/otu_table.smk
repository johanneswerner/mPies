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
        "Executing singlem with {threads} threads on the following input files: {input}, producing {output}."
    shell:
        "./appimages/singlem.AppImage pipe --sequences {input} --otu_table {output} --threads {threads}"

rule obtain_tax_list:
    input:
        expand("{sample}/output/singlem_otu.tsv", sample=SAMPLES)
    output:
        "{sample}/output/taxlist.txt",
    shell:
        "./main.py -v parse_singlem -t {input} -u {output}"

rule obtain_proteome:
    input:
        expand("{sample}/output/taxlist.txt", sample=SAMPLES)
    output:
        "{sample}/output/proteomes.faa",
    shell:
        "./main.py -v amplicon -g {input} -p {output}"

rule get_amplicon_proteome_done:
    input:
        expand("{sample}/output/proteomes.faa", sample=SAMPLES)
    output:
        touch("checkpoints/get_amplicon_proteome.done")
