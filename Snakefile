rule all:
    input:
        "input_data/OSD14_R1_shotgun_raw.fastq.gz",
        "input_data/OSD14_R2_shotgun_raw.fastq.gz"
    output:
        "output/otu_table.tsv"
    shell:
        "singlem pipe --sequences {input} --otu_table {output}"