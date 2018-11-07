rule run_trimmomatic:
    input:
        expand("{sample}/reads/{sample}_R1.fastq.gz", sample=config["sample"]),
        expand("{sample}/reads/{sample}_R2.fastq.gz", sample=config["sample"])
    output:
        expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
        expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
        temp(expand("{sample}/trimmed/{sample}_R1_trimmed_se.fastq.gz", sample=config["sample"])),
        temp(expand("{sample}/trimmed/{sample}_R2_trimmed_se.fastq.gz", sample=config["sample"]))
    log:
        expand("{sample}/log/{sample}_trimmomatic.log", sample=config["sample"])
    params:
        mode=config["preprocessing"]["run_trimmomatic"]["mode"],
        illuminaclip=config["preprocessing"]["run_trimmomatic"]["illuminaclip"],
        leading=config["preprocessing"]["run_trimmomatic"]["leading"],
        trailing=config["preprocessing"]["run_trimmomatic"]["trailing"],
        slidingwindow=config["preprocessing"]["run_trimmomatic"]["slidingwindow"],
        minlen=config["preprocessing"]["run_trimmomatic"]["minlen"]
    threads:
        config["ressources"]["threads"]
    shell:
        """
        trimmomatic {params.mode} -threads {threads} -phred33 {input[0]} {input[1]} {output[0]} {output[2]} \
          {output[1]} {output[3]} ILLUMINACLIP:{params.illuminaclip} LEADING:{params.leading} \
          TRAILING:{params.trailing} SLIDINGWINDOW:{params.slidingwindow} MINLEN:{params.minlen} 2> {log}
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

