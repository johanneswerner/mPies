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


# mPies (metaProteomics in environmental sciences) creates annotated databases for metaproteomics analysis.
# Copyright 2018 Johannes Werner (Leibniz-Institute for Baltic Sea Research)
# Copyright 2018 Augustin Geron (University of Mons, University of Stirling)
# Copyright 2018 Sabine Matallana Surget (University of Stirling)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
