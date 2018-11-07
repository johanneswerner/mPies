RUN_SINGLEM = True

if RUN_SINGLEM:
    rule generate_otu_table:
        input:
            expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
        output:
            temp(expand("{sample}/singlem/singlem_otu.tsv", sample=config["sample"]))
        log:
            expand("{sample}/log/{sample}_singlem.log", sample=config["sample"])
        params:
            mode="pipe"
        threads:
            28
        shell:
            "./appimages/singlem.AppImage {params.mode} --sequences {input} --otu_table {output} --threads {threads} > {log} 2>&1"

    rule obtain_tax_list:
        input:
            expand("{sample}/singlem/singlem_otu.tsv", sample=config["sample"])
        output:
            expand("{sample}/amplicon/taxlist.txt", sample=config["sample"])
        params:
            mode="parse_singlem",
            cutoff=2
        shell:
            "./main.py -v {params.mode} -t {input} -u {output} -c {params.cutoff}"

    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/taxlist.txt", sample=config["sample"])
        output:
            temp(expand("{sample}/proteome/{sample}_amplicon.faa", sample=config["sample"]))
        params:
            mode="amplicon"
        shell:
            "./main.py -v {params.mode} -g {input} -p {output}"

else:
    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/genuslist_test.txt", sample=config["sample"])
        output:
            temp(expand("{sample}/proteome/{sample}_amplicon.faa", sample=config["sample"]))
        params:
            mode="amplicon"
        shell:
            "./main.py -v {params.mode} -g {input} -p {output}"

rule get_amplicon_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_amplicon.faa", sample=config["sample"])
    output:
        touch("checkpoints/amplicon_proteome.done")
