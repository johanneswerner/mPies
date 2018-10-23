SAMPLES = ["OSD14"]
RUN_SINGLEM = True

if RUN_SINGLEM:
    rule generate_otu_table:
        input:
            "{sample}/reads/{sample}_R1.fastq.gz",
            "{sample}/reads/{sample}_R2.fastq.gz"
        output:
            "{sample}/singlem/singlem_otu.tsv"
        threads:
            28
        message:
            "Executing singlem with {threads} threads on the following input files: {input}, producing {output}."
        shell:
            "./appimages/singlem.AppImage pipe --sequences {input} --otu_table {output} --threads {threads}"

    rule obtain_tax_list:
        input:
            expand("{sample}/singlem/singlem_otu.tsv", sample=SAMPLES)
        output:
            "{sample}/amplicon/taxlist.txt"
        shell:
            "./main.py -v parse_singlem -t {input} -u {output}"

    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/taxlist.txt", sample=SAMPLES)
        output:
            "{sample}/proteome/{sample}_amplicon.faa"
        shell:
            "./main.py -v amplicon -g {input} -p {output}"

else:
    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/genuslist_test.txt", sample=SAMPLES)
        output:
            "{sample}/proteome/{sample}_amplicon.faa"
        shell:
            "./main.py -v amplicon -g {input} -p {output}"

rule get_amplicon_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_amplicon.faa", sample=SAMPLES)
    output:
        touch("checkpoints/amplicon_proteome.done")
