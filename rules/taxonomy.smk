rule run_diamond_tax:
    input:
        "{sample}/annotated/{identified_id}/proteome/metaproteome.subset.faa"
    output:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.diamond.tsv"
    params:
        mode=config["taxonomy"]["run_diamond"]["mode"],
        output_format=config["taxonomy"]["run_diamond"]["output_format"],
        diamond_database=config["taxonomy"]["run_diamond"]["diamond_database"],
        maxtargetseqs=config["taxonomy"]["run_diamond"]["max_target_seqs"],
        score=config["taxonomy"]["run_diamond"]["score"],
        compress=config["taxonomy"]["run_diamond"]["compress"],
        sensitive=config["taxonomy"]["run_diamond"]["sensitive"]
    log:
        "{sample}/log/diamond_{sample}_{identified_id}.log"
    threads:
        config["ressources"]["threads"]
    shell:
        """
        diamond {params.mode} -f {params.output_format} -p {threads} -d {params.diamond_database} \
          -k {params.maxtargetseqs} --min-score {params.score} --compress {params.compress} {params.sensitive} \
          -q {input} -o {output} > {log} 2>&1
        """

rule create_protein_groups_taxonomy:
    input:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.diamond.tsv",
        "{sample}/identified/{identified_id}.xlsx"
    output:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.tax.protein_groups.tsv"
    params:
        mode=config["taxonomy"]["protein_groups"]["mode"]
    log:
        "{sample}/log/mptk_proteingroups_taxonomy_{identified_id}.log"
    shell:
        "./main.py -v -z {log} {params.mode} -d {input[0]} -e {input[1]} -p {output}"

rule run_blast2lca:
    input:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.tax.protein_groups.tsv"
    output:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.megan.tsv"
    params:
        blast2lca_bin=config["taxonomy"]["run_blast2lca"]["binary"],
        input_format=config["taxonomy"]["run_blast2lca"]["input_format"],
        blast_mode=config["taxonomy"]["run_blast2lca"]["blast_mode"],
        acc2tax_file=config["taxonomy"]["run_blast2lca"]["acc2tax_file"]
    log:
        "{sample}/log/blast2lca_{sample}_{identified_id}.log"
    shell:
        """
        {params.blast2lca_bin} -i {input} -f {params.input_format} -m {params.blast_mode} -o {output} \
          -a2t {params.acc2tax_file} > {log} 2>&1
        """

rule parse_taxonomy:
    input:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.megan.tsv"
    output:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.parsed_table.tsv"
    params:
        mode=config["taxonomy"]["parse_taxonomy"]["mode"]
    log:
        "{sample}/log/mptk_parse_taxonomy_{identified_id}.log"
    shell:
        "./main.py -v -z {log} {params.mode} -m {input} -t {output}"

rule export_table_taxonomy:
    input:
        "{sample}/identified/{identified_id}.xlsx",
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.parsed_table.tsv"
    output:
        "{sample}/annotated/{identified_id}/taxonomy/metaproteome.tax.tsv"
    params:
        mode=config["export_tables"]["mode"]
    log:
        "{sample}/log/mptk_exporttable_taxonomy_{identified_id}.log"
    shell:
        "./main.py -v -z {log} {params.mode} -e {input[0]} -t {input[1]} -o {output}"

rule get_taxonomy_done:
    input:
        expand("{sample}/annotated/{identified_id}/taxonomy/metaproteome.tax.tsv", sample=config["sample"], identified_id=identified_ids)
    output:
        touch("checkpoints/taxonomy.done")


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
