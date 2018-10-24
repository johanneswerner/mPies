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

rule postprocessing_done:
    input:
        expand("{sample}/proteome/{sample}_combined.faa", sample=SAMPLES)
    output:
        touch("checkpoints/postprocessing.done")
