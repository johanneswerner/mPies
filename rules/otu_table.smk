SAMPLES = ["OSD14subset"]
RUN_SINGLEM = True

if RUN_SINGLEM:
    rule generate_otu_table:
        input:
            expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=SAMPLES),
            expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=SAMPLES),
            expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=SAMPLES)
        output:
            temp("{sample}/singlem/singlem_otu.tsv")
        log:
            "{sample}/log/{sample}_singlem.log"
        params:
            mode="pipe"
        threads:
            28
        shell:
            "./appimages/singlem.AppImage {params.mode} --sequences {input} --otu_table {output} --threads {threads} > {log} 2>&1"

    rule obtain_tax_list:
        input:
            expand("{sample}/singlem/singlem_otu.tsv", sample=SAMPLES)
        output:
            "{sample}/amplicon/taxlist.txt"
        params:
            mode="parse_singlem",
            cutoff=2
        shell:
            "./main.py -v {params.mode} -t {input} -u {output} -c {params.cutoff}"

    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/taxlist.txt", sample=SAMPLES)
        output:
            temp("{sample}/proteome/{sample}_amplicon.faa")
        params:
            mode="amplicon"
        shell:
            "./main.py -v {params.mode} -g {input} -p {output}"

else:
    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/genuslist_test.txt", sample=SAMPLES)
        output:
            temp("{sample}/proteome/{sample}_amplicon.faa")
        params:
            mode="amplicon"
        shell:
            "./main.py -v {params.mode} -g {input} -p {output}"

rule get_amplicon_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_amplicon.faa", sample=SAMPLES)
    output:
        touch("checkpoints/amplicon_proteome.done")
