rule run_diamond_uniprot:
    input:
        "{sample}/annotated/{identified_id}/proteome/metaproteome.subset.faa"
    output:
        "{sample}/annotated/{identified_id}/functions/metaproteome.uniprot.diamond.tsv"
    params:
        mode=config["functions"]["run_uniprot"]["run_diamond"]["mode"],
        output_format=config["functions"]["run_uniprot"]["run_diamond"]["output_format"],
        diamond_database=config["functions"]["run_uniprot"]["run_diamond"]["diamond_database"],
        maxtargetseqs=config["functions"]["run_uniprot"]["run_diamond"]["max_target_seqs"],
        score=config["functions"]["run_uniprot"]["run_diamond"]["score"],
        compress=config["functions"]["run_uniprot"]["run_diamond"]["compress"],
        sensitive=config["functions"]["run_uniprot"]["run_diamond"]["sensitive"]
    log:
        "{sample}/log/diamond_functions_uniprot_{sample}_{identified_id}.log"
    threads:
        config["ressources"]["threads"]
    shell:
        """
        diamond {params.mode} -f {params.output_format} -p {threads} -d {params.diamond_database} \
          -k {params.maxtargetseqs} --min-score {params.score} --compress {params.compress} {params.sensitive} \
          -q {input} -o {output} > {log} 2>&1
        """

rule create_protein_groups_uniprot:
    input:
        "{sample}/annotated/{identified_id}/functions/metaproteome.uniprot.diamond.tsv",
        "{sample}/identified/{identified_id}.xlsx"
    output:
        "{sample}/annotated/{identified_id}/functions/metaproteome.uniprot.protein_groups.tsv"
    params:
        mode=config["functions"]["protein_groups"]["mode"]
    log:
        expand("{sample}/log/mptk_proteingroups_uniprot_{identified_id}.log", sample=config["sample"])
    shell:
        "./main.py -v -e {log} {params.mode} -d {input[0]} -e {input[1]} -p {output}"

rule parse_functions_uniprot:
    input:
        "{sample}/annotated/{identified_id}/functions/metaproteome.uniprot.protein_groups.tsv",
        "{sample}/identified/{identified_id}.xlsx"
    output:
        "{sample}/annotated/{identified_id}/functions/metaproteome.functions.uniprot.parsed_table.tsv"
    params:
        mode=config["functions"]["run_uniprot"]["parse_functions_uniprot"]["mode"],
        uniprot_table=config["functions"]["run_uniprot"]["uniprot_table"],
        go_annotation=config["functions"]["run_uniprot"]["parse_functions_uniprot"]["go_annotation"]
    log:
        expand("{sample}/log/mptk_parsefunctions_uniprot_{identified_id}.log", sample=config["sample"])
    shell:
        "./main.py -v -e {log} {params.mode} -d {input[0]} -t {params.uniprot_table} -e {input[1]} -o {output} {params.go_annotation}"

rule export_table_functions_uniprot:
    input:
        "{sample}/identified/{identified_id}.xlsx",
        "{sample}/annotated/{identified_id}/functions/metaproteome.functions.uniprot.parsed_table.tsv"
    output:
        "{sample}/annotated/{identified_id}/functions/metaproteome.functions.uniprot.tsv"
    params:
        mode=config["export_tables"]["mode"]
    log:
        expand("{sample}/log/mptk_exporttables_uniprot_{identified_id}.log", sample=config["sample"])
    shell:
        "./main.py -v -e {log} {params.mode} -e {input[0]} -t {input[1]} -o {output}"

rule get_functions_uniprot:
    input:
        expand("{sample}/annotated/{identified_id}/functions/metaproteome.functions.uniprot.tsv", sample=config["sample"], identified_id=identified_ids)
    output:
        touch("checkpoints/functions_uniprot.done")


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
