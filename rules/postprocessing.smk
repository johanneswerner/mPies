SAMPLES = ["OSD14subset"]

rule combine_proteomes:
    input:
        expand("{sample}/proteome/{sample}_amplicon.faa", sample=SAMPLES),
        expand("{sample}/proteome/{sample}_assembled.faa", sample=SAMPLES),
        expand("{sample}/proteome/{sample}_unassembled.faa", sample=SAMPLES)
    output:
        expand("{sample}/proteome/{sample}_combined.faa", sample=SAMPLES)
    shell:
        "cat {input} > {output}"

rule remove_short_sequences:
    input:
        expand("{sample}/proteome/{sample}_combined.faa", sample=SAMPLES)
    output:
        temp(expand("{sample}/proteome/{sample}_combined_min30.faa", sample=SAMPLES))
    params:
        min_length=30
    shell:
        "perl helper_scripts/remove_short_sequences.pl {params.min_length} {input} > {output}"

rule remove_duplicates:
    input:
        expand("{sample}/proteome/{sample}_combined_min30.faa", sample=SAMPLES)
    output:
        expand("{sample}/proteome/{sample}_combined_min30_nodup.faa", sample=SAMPLES),
        temp(expand("{sample}/proteome/{sample}_combined_min30_nodup.faa.clstr", sample=SAMPLES)),
        temp(expand("{sample}/proteome/{sample}_combined_min30_nodup.faa2.clstr", sample=SAMPLES))
    log:
        expand("{sample}/log/{sample}_cdhit.log", sample=SAMPLES)
    shell:
        "cd-hit-dup -i {input} -o {output[0]} > {log} 2>&1"

rule hash_headers:
    input:
        expand("{sample}/proteome/{sample}_combined_min30_nodup.faa", sample=SAMPLES)
    output:
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.faa", sample=SAMPLES),
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.tsv", sample=SAMPLES)
    params:
        mode="hashing"
    shell:
        "./main.py -v {params.mode} -p {input} -s {output[0]} -t {output[1]}"

rule postprocessing_done:
    input:
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.faa", sample=SAMPLES),
        expand("{sample}/proteome/{sample}_combined_min30_nodup_hashed.tsv", sample=SAMPLES)
    output:
        touch("checkpoints/postprocessing.done")
