rule combine_proteomes:
    input:
        expand("{sample}/proteome/amplicon.faa", sample=config["sample"]),
        expand("{sample}/proteome/assembled.faa", sample=config["sample"]),
        expand("{sample}/proteome/unassembled.faa", sample=config["sample"])
    output:
        expand("{sample}/proteome/metaproteome.faa", sample=config["sample"])
    shell:
        "cat {input} > {output}"

rule remove_short_sequences:
    input:
        expand("{sample}/proteome/metaproteome.faa", sample=config["sample"])
    output:
        temp(expand("{sample}/proteome/metaproteome.mincutoff.faa", sample=config["sample"]))
    params:
        min_length=config["postprocessing"]["remove_short_sequences"]["min_length"]
    shell:
        "perl helper_scripts/remove_short_sequences.pl {params.min_length} {input} > {output}"

rule remove_duplicates:
    input:
        expand("{sample}/proteome/metaproteome.mincutoff.faa", sample=config["sample"])
    output:
        expand("{sample}/proteome/metaproteome.mincutoff.nodup.faa", sample=config["sample"]),
        temp(expand("{sample}/proteome/metaproteome.mincutoff.nodup.faa.clstr", sample=config["sample"])),
        temp(expand("{sample}/proteome/metaproteome.mincutoff.nodup.faa2.clstr", sample=config["sample"]))
    log:
        expand("{sample}/log/{sample}_cdhit.log", sample=config["sample"])
    shell:
        "cd-hit-dup -i {input} -o {output[0]} > {log} 2>&1"

rule hash_headers:
    input:
        expand("{sample}/proteome/metaproteome.mincutoff.nodup.faa", sample=config["sample"])
    output:
        expand("{sample}/proteome/metaproteome.hashed.faa", sample=config["sample"]),
        expand("{sample}/proteome/metaproteome.hashed.tsv", sample=config["sample"])
    params:
        mode=config["postprocessing"]["hash_headers"]["mode"],
        hash_type=config["postprocessing"]["hash_headers"]["hash_type"]
    shell:
        "./main.py -v {params.mode} -p {input} -s {output[0]} -t {output[1]} -x {params.hash_type}"

rule postprocessing_done:
    input:
        expand("{sample}/proteome/metaproteome.hashed.faa", sample=config["sample"]),
        expand("{sample}/proteome/metaproteome.hashed.tsv", sample=config["sample"])
    output:
        touch("checkpoints/postprocessing.done")


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
