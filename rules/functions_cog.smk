rule run_diamond_cog:
    input:
        expand("{sample}/proteome/metaproteome.subset.faa", sample=config["sample"])
    output:
        temp(expand("{sample}/functions/metaproteome.cog.diamond.tsv", sample=config["sample"]))
    params:
        mode=config["functions"]["run_cog"]["run_diamond"]["mode"],
        output_format=config["functions"]["run_cog"]["run_diamond"]["output_format"],
        diamond_database=config["functions"]["run_cog"]["run_diamond"]["diamond_database"],
        maxtargetseqs=config["functions"]["run_cog"]["run_diamond"]["max_target_seqs"],
        score=config["functions"]["run_cog"]["run_diamond"]["score"],
        compress=config["functions"]["run_cog"]["run_diamond"]["compress"],
        sensitive=config["functions"]["run_cog"]["run_diamond"]["sensitive"]
    log:
        expand("{sample}/log/diamond_functions_cog.log", sample=config["sample"])
    threads:
        config["ressources"]["threads"]
    shell:
        """
        diamond {params.mode} -f {params.output_format} -p {threads} -d {params.diamond_database} \
          -k {params.maxtargetseqs} --min-score {params.score} --compress {params.compress} {params.sensitive} \
          -q {input} -o {output} > {log} 2>&1
        """

rule create_protein_groups_cog:
    input:
        temp(expand("{sample}/functions/metaproteome.cog.diamond.tsv", sample=config["sample"])),
        config["excel_file"]
    output:
        temp(expand("{sample}/functions/metaproteome.cog.protein_groups.tsv", sample=config["sample"]))
    params:
        mode=config["functions"]["protein_groups"]["mode"]
    shell:
        "./main.py -v {params.mode} -d {input[0]} -e {input[1]} -p {output}"

rule parse_functions_cog:
    input:
        expand("{sample}/functions/metaproteome.cog.protein_groups.tsv", sample=config["sample"])
    output:
        temp(expand("{sample}/functions/metaproteome.functions.cog.parsed_table.tsv", sample=config["sample"]))
    params:
        mode=config["functions"]["run_cog"]["parse_functions_cog"]["mode"],
        cog_tables=config["functions"]["run_cog"]["cog_table"],
        cog_names=config["functions"]["run_cog"]["cog_names"],
        cog_functions=config["functions"]["run_cog"]["cog_functions"]
    shell:
        """
        ./main.py -v {params.mode} -d {input} -t {params.cog_tables} -n {params.cog_names} -f {params.cog_functions} \
          -e {output}
        """

rule export_table_functions_cog:
    input:
        config["excel_file"],
        temp(expand("{sample}/functions/metaproteome.functions.cog.parsed_table.tsv", sample=config["sample"]))
    output:
        expand("{sample}/functions/metaproteome.functions.cog.tsv", sample=config["sample"])
    params:
        mode=config["export_tables"]["mode"]
    shell:
        "./main.py -v {params.mode} -e {input[0]} -t {input[1]} -o {output}"

rule get_functions_cog_done:
    input:
        expand("{sample}/functions/metaproteome.functions.cog.tsv", sample=config["sample"])
    output:
        touch("checkpoints/functions_cog.done")


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
