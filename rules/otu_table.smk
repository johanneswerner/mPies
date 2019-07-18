if config["otu_table"]["run_singlem"]:
    rule generate_otu_table:
        input:
            expand("{sample}/trimmed/{sample}_R1_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_R2_trimmed_pe.fastq.gz", sample=config["sample"]),
            expand("{sample}/trimmed/{sample}_trimmed_se.fastq.gz", sample=config["sample"])
        output:
            temp(expand("{sample}/singlem/singlem_otu.tsv", sample=config["sample"]))
        log:
            expand("{sample}/log/singlem.log", sample=config["sample"])
        params:
            mode=config["otu_table"]["generate_otu_table"]["mode"]
        threads:
            config["ressources"]["threads"]
        shell:
            """
            /data/mPies/appimages/AppRun {params.mode} --sequences {input} --otu_table {output} --threads {threads} \
              > {log} 2>&1
            """

    rule obtain_tax_list:
        input:
            expand("{sample}/singlem/singlem_otu.tsv", sample=config["sample"])
        output:
            expand("{sample}/amplicon/taxlist.txt", sample=config["sample"])
        params:
            mode=config["otu_table"]["obtain_tax_list"]["mode"],
            cutoff=config["otu_table"]["obtain_tax_list"]["cutoff"]
        shell:
            "./main.py -v {params.mode} -t {input} -u {output} -c {params.cutoff}"

    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/taxlist.txt", sample=config["sample"])
        output:
            temp(expand("{sample}/proteome/amplicon.faa", sample=config["sample"]))
        params:
            mode=config["otu_table"]["obtain_proteome"]["mode"]
        shell:
            "./main.py -v {params.mode} -g {input} -p {output}"

else:
    rule obtain_proteome:
        input:
            expand("{sample}/amplicon/genuslist_test.txt", sample=config["sample"])
        output:
            temp(expand("{sample}/proteome/amplicon.faa", sample=config["sample"]))
        params:
            mode=config["otu_table"]["obtain_proteome"]["mode"]
        shell:
            "./main.py -v {params.mode} -g {input} -p {output}"

rule get_amplicon_proteome_done:
    input:
        expand("{sample}/proteome/amplicon.faa", sample=config["sample"])
    output:
        touch("checkpoints/amplicon_proteome.done")


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
