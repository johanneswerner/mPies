if config["assembled"]["run_assembly"]:
    if config["assembled"]["assembler"] == "megahit":
        rule run_megahit:
            input:
                expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
                expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
                expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
            output:
                expand("{sample}/assembly/contigs.fa", sample=config["sample"])
            params:
                klist=config["assembled"]["run_megahit"]["klist"],
                memory=config["ressources"]["megahit_memory"]
            log:
                expand("{sample}/log/megahit.log", sample=config["sample"])
            threads:
                config["ressources"]["threads"]
            shell:
                """
                megahit -1 {input[0]} -2 {input[1]} -r {input[2]} --k-list {params.klist} --memory {params.memory} \
                  -t {threads} -o {config[sample]}/megahit/ --out-prefix {config[sample]}_megahit > {log} 2>&1
                mv {config[sample]}/megahit/{config[sample]}_megahit.contigs.fa {output}
                rm -rf {config[sample]}/megahit/
                """

    elif config["assembled"]["assembler"] == "metaspades":
        rule run_metaspades:
            input:
                expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
                expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
                expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
            output:
                expand("{sample}/assembly/contigs.fa", sample=config["sample"])
            params:
                memory=config["ressources"]["metaspades_memory"]
            log:
                expand("{sample}/log/metaspades.log", sample=config["sample"])
            threads:
                config["ressources"]["threads"]
            shell:
                """
                spades.py -1 {input[0]} -2 {input[1]} -s {input[2]} -t {threads} -m {params.memory} \
                  -o {config[sample]}/metaspades/ > {log} 2>&1
                mv {config[sample]}/metaspades/contigs.fasta {output}
                rm -rf {config[sample]}/metaspades/
                """

if config["assembled"]["run_genecalling"]:
    rule run_prodigal:
        input:
            expand("{sample}/assembly/contigs.fa", sample=config["sample"])
        output:
            expand("{sample}/proteome/assembled.faa", sample=config["sample"]),
            temp(expand("{sample}/proteome/assembled.gbk", sample=config["sample"]))
        params:
            mode=config["assembled"]["prodigal"]["mode"]
        shell:
            """
            prodigal -p {params.mode} -i {input} -o {output[1]} -a {output[0]} -q
            """

rule get_assembled_proteome_done:
    input:
        expand("{sample}/proteome/assembled.faa", sample=config["sample"])
    output:
        touch("checkpoints/assembled_proteome.done")


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
