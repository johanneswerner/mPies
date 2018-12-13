READS = ["R1", "R2"]

# rule create_train_dir:
#     input:
#         "/data/miniconda3/envs/mpies/bin/train/"
#     output:
#         "checkpoints/train_dir.done"
#     shell:
#         "ln -s {input} . && touch ${output}"

rule fastq2fasta:
    input:
        expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
        expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz",sample=config["sample"]),
        expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
    output:
        temp(expand("{sample}/fasta_files/{sample}_R1_trimmed_pe.fasta", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/{sample}_R2_trimmed_pe.fasta", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/{sample}_trimmed_se.fasta", sample=config["sample"]))
    shell:
        """
        zcat {input[0]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[0]}
        zcat {input[1]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[1]}
        zcat {input[2]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[2]}
        """

rule run_fraggenescan:
    input:
        expand("{sample}/fasta_files/{sample}_R1_trimmed_pe.fasta", sample=config["sample"]),
        expand("{sample}/fasta_files/{sample}_R2_trimmed_pe.fasta", sample=config["sample"]),
        expand("{sample}/fasta_files/{sample}_trimmed_se.fasta", sample=config["sample"])
    output:
        temp(expand("{sample}/fasta_files/{sample}_R1_trimmed_pe_fgs.faa", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/{sample}_R2_trimmed_pe_fgs.faa", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/{sample}_trimmed_se_fgs.faa", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R1_trimmed_pe.ffn", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R2_trimmed_pe.ffn", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_trimmed_se.ffn", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R1_trimmed_pe.gff", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R2_trimmed_pe.gff", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_trimmed_se.gff", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R1_trimmed_pe.out", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_R2_trimmed_pe.out", sample=config["sample"])),
        temp(expand("{sample}/fasta_files/fgs_{sample}_trimmed_se.out", sample=config["sample"]))
    params:
        train_file=config["unassembled"]["run_fraggenescan"]["train_file"]
    log:
        log_r1=expand("{sample}/log/{sample}_fgs_r1.log", sample=config["sample"]),
        log_r2=expand("{sample}/log/{sample}_fgs_r2.log", sample=config["sample"]),
        log_se=expand("{sample}/log/{sample}_fgs_se.log", sample=config["sample"])
    threads:
        config["ressources"]["threads"]
    shell:
        """
        run_FragGeneScan.pl -genome={input[0]} -out={config[sample]}/fasta_files/fgs_{config[sample]}_R1_trimmed_pe \
          -complete=0 -train={params.train_file} -thread={threads} > {log.log_r1} 2>&1
        run_FragGeneScan.pl -genome={input[1]} -out={config[sample]}/fasta_files/fgs_{config[sample]}_R2_trimmed_pe \
          -complete=0 -train={params.train_file} -thread={threads} > {log.log_r2} 2>&1
        run_FragGeneScan.pl -genome={input[2]} -out={config[sample]}/fasta_files/fgs_{config[sample]}_trimmed_se \
          -complete=0 -train={params.train_file} -thread={threads} > {log.log_se} 2>&1
        mv {config[sample]}/fasta_files/fgs_{config[sample]}_R1_trimmed_pe.faa {output[0]}
        mv {config[sample]}/fasta_files/fgs_{config[sample]}_R2_trimmed_pe.faa {output[1]}
        mv {config[sample]}/fasta_files/fgs_{config[sample]}_trimmed_se.faa {output[2]}
        """

rule combine_results:
    input:
        expand("{sample}/fasta_files/{sample}_{read}_trimmed_pe_fgs.faa", read=READS, sample=config["sample"]),
        expand("{sample}/fasta_files/{sample}_trimmed_se_fgs.faa", sample=config["sample"]),
    output:
        temp(expand("{sample}/proteome/unassembled.faa", sample=config["sample"]))
    shell:
        """
        cat {input} > {output}
        """

rule get_unassembled_proteome_done:
    input:
        expand("{sample}/proteome/unassembled.faa", sample=config["sample"])
    output:
        touch("checkpoints/unassembled_proteome.done")


# mPies (metaProteomics in environmental sciences) creates annotated databases for metaproteomics analysis.
# Copyright 2018 Johannes Werner (Leibniz-Institute for Baltic Sea Research)
# Copyright 2018 Augustin Geron (University of Stirling)
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
