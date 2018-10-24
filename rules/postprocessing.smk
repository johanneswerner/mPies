SAMPLES = ["OSD14"]

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
        expand("{sample}/proteome/{sample}_combined_min30.faa", sample=SAMPLES)
    shell:
        "perl helper_scripts/remove_short_sequences.pl 30 {input} > {output}"

rule remove_duplicates:
    input:
        expand("{sample}/proteome/{sample}_combined_min30.faa", sample=SAMPLES)
    output:
        expand("{sample}/proteome/{sample}_combined_min30_nodup.faa", sample=SAMPLES)
    log:
        expand("{sample}/log/{sample}_cdhit.log", sample=SAMPLES)
    shell:
        "cd-hit-dup -i {input} -o {output} 2> {log}"

rule postprocessing_done:
    input:
        expand("{sample}/proteome/{sample}_combined_min30_nodup.faa", sample=SAMPLES)
    output:
        touch("checkpoints/postprocessing.done")
