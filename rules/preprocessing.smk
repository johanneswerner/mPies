rule run_trimmomatic:
    input:
        expand("{sample}/reads/{sample}_R1.fastq.gz", sample=config["sample"]),
        expand("{sample}/reads/{sample}_R2.fastq.gz", sample=config["sample"])
    output:
        expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
        expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
        temp(expand("{sample}/trimmed/{sample}_R1_trimmed_se.fastq.gz", sample=config["sample"])),
        temp(expand("{sample}/trimmed/{sample}_R2_trimmed_se.fastq.gz", sample=config["sample"]))
    params:
        mode="PE"
    log:
        expand("{sample}/log/{sample}_trimmomatic.log", sample=config["sample"])
    threads:
        28  
    shell:
        """
        trimmomatic {params.mode} -threads {threads} -phred33 {input[0]} {input[1]} \
          {output[0]} {output[2]} {output[1]} {output[3]} \
          ILLUMINACLIP:/data/miniconda3/envs/mpies/share/trimmomatic-0.38-1/adapters/TruSeq3-PE.fa:2:30:10 \
          LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 2> {log}
        """

rule combine_trimmed_reads:
    input:
        expand("{sample}/trimmed/{sample}_R1_trimmed_se.fastq.gz", sample=config["sample"]),
        expand("{sample}/trimmed/{sample}_R2_trimmed_se.fastq.gz", sample=config["sample"])
    output:
        expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
    shell:
        "cat {input[0]} {input[1]} > {output}"

rule preprocessing_done:
    input:
        expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
        expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
        expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
    output:
        touch("checkpoints/preprocessing.done")
