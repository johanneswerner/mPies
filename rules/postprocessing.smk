rule combine_proteomes:
    input:
        expand("{sample}/proteome/{sample}_amplicon.faa", sample=config["sample"]),
        expand("{sample}/proteome/{sample}_assembled.faa", sample=config["sample"]),
        expand("{sample}/proteome/{sample}_unassembled.faa", sample=config["sample"])
    output:
        expand("{sample}/proteome/{sample}_combined.faa", sample=config["sample"])
    shell:
        "cat {input} > {output}"

rule remove_short_sequences:
    input:
        expand("{sample}/proteome/{sample}_combined.faa", sample=config["sample"])
    output:
        temp(expand("{sample}/proteome/{sample}_combined_min30.faa", sample=config["sample"]))
    params:
        min_length=config["postprocessing"]["remove_short_sequences"]["min_length"]
    shell:
        "perl helper_scripts/remove_short_sequences.pl {params.min_length} {input} > {output}"

rule remove_duplicates:
    input:
        expand("{sample}/proteome/{sample}_combined_min30.faa", sample=config["sample"])
    output:
        expand("{sample}/proteome/{sample}_combined_min30_nodup.faa", sample=config["sample"]),
        temp(expand("{sample}/proteome/{sample}_combined_min30_nodup.faa.clstr", sample=config["sample"])),
        temp(expand("{sample}/proteome/{sample}_combined_min30_nodup.faa2.clstr", sample=config["sample"]))
    log:
        expand("{sample}/log/{sample}_cdhit.log", sample=config["sample"])
    shell:
        "cd-hit-dup -i {input} -o {output[0]} > {log} 2>&1"

rule hash_headers:
    input:
        expand("{sample}/proteome/{sample}_combined_min30_nodup.faa", sample=config["sample"])
    output:
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.faa", sample=config["sample"]),
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.tsv", sample=config["sample"])
    params:
        mode=config["postprocessing"]["hash_headers"]["mode"],
        hash_type=config["postprocessing"]["hash_headers"]["hash_type"]
    shell:
        "./main.py -v {params.mode} -p {input} -s {output[0]} -t {output[1]} -x {params.hash_type}"

rule postprocessing_done:
    input:
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.faa", sample=config["sample"]),
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.tsv", sample=config["sample"])
    output:
        touch("checkpoints/postprocessing.done")

