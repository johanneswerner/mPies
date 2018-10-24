SAMPLES = ["OSD14"]


rule run_trimmomatic:
    input:
        "{sample}/reads/{sample}_R1.fastq.gz",
        "{sample}/reads/{sample}_R2.fastq.gz"
    output:
        "{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz",
        "{sample}/trimmed/{sample}_R1_trimmed_se.fastq.gz",
        "{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz",
        "{sample}/trimmed/{sample}_R2_trimmed_se.fastq.gz"
    log:
        "{sample}/log/{sample}_trimmomatic.log"
    threads:
        28  
    shell:
        """
        trimmomatic PE -threads {threads} -phred33 {input[0]} {input[1]} \
          {output[0]} {output[1]} {output[2]} {output[3]} \
          ILLUMINACLIP:/data/miniconda3/envs/mpies/share/trimmomatic-0.38-1/adapters/TruSeq3-PE.fa:2:30:10 \
          LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 2> {log}
        """

rule combine_trimmed_reads:
    input:
        "{sample}/trimmed/{sample}_R1_trimmed_se.fastq.gz",
        "{sample}/trimmed/{sample}_R2_trimmed_se.fastq.gz"
    output:
        "{sample}/trimmed/{sample}_trimmed_se.fastq.gz"
    shell:
        "cat {input[0]} {input[1]} > {output}"

rule preprocessing_done:
    input:
        expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=SAMPLES),
        expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=SAMPLES),
        expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=SAMPLES)
    output:
        touch("checkpoints/preprocessing.done")
