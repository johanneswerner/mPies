rule run_diamond_uniprot:
    input:
        expand("{sample}/proteome/metaproteome.subset.faa", sample=config["sample"])
    output:
        temp(expand("{sample}/functions/metaproteome.uniprot.diamond.tsv", sample=config["sample"]))
    params:
        mode=config["functions"]["run_uniprot"]["run_diamond"]["mode"],
        output_format=config["functions"]["run_uniprot"]["run_diamond"]["output_format"],
        diamond_database=config["functions"]["run_uniprot"]["run_diamond"]["diamond_database"],
        maxtargetseqs=config["functions"]["run_uniprot"]["run_diamond"]["max_target_seqs"],
        score=config["functions"]["run_uniprot"]["run_diamond"]["score"],
        compress=config["functions"]["run_uniprot"]["run_diamond"]["compress"],
        sensitive=config["functions"]["run_uniprot"]["run_diamond"]["sensitive"]
    log:
        expand("{sample}/log/diamond_functions_uniprot.log", sample=config["sample"])
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
        expand("{sample}/functions/metaproteome.uniprot.diamond.tsv", sample=config["sample"]),
        config["excel_file"]
    output:
        temp(expand("{sample}/functions/metaproteome.uniprot.protein_groups.tsv", sample=config["sample"]))
    params:
        mode=config["functions"]["protein_groups"]["mode"]
    shell:
        "./main.py -v {params.mode} -d {input[0]} -e {input[1]} -p {output}"

rule parse_functions_uniprot:
    input:
        expand("{sample}/functions/metaproteome.uniprot.protein_groups.tsv", sample=config["sample"])
    output:
        temp(expand("{sample}/functions/metaproteome.functions.uniprot.parsed_table.tsv", sample=config["sample"]))
    params:
        mode=config["functions"]["run_uniprot"]["parse_functions_uniprot"]["mode"],
        uniprot_table=config["functions"]["run_uniprot"]["uniprot_proteinname_table"],
        go_annotation=config["functions"]["run_uniprot"]["parse_functions_uniprot"]["go_annotation"]
    shell:
        "./main.py -v {params.mode} -d {input} -t {params.uniprot_table} -e {output} {params.go_annotation}"

rule export_table_functions_uniprot:
    input:
        config["excel_file"],
        expand("{sample}/functions/metaproteome.functions.uniprot.parsed_table.tsv", sample=config["sample"])
    output:
        expand("{sample}/functions/metaproteome.functions.uniprot.tsv", sample=config["sample"])
    params:
        mode=config["export_tables"]["mode"]
    shell:
        "./main.py -v {params.mode} -e {input[0]} -t {input[1]} -o {output}"

rule get_functions_uniprot:
    input:
        expand("{sample}/functions/metaproteome.functions.uniprot.tsv", sample=config["sample"])
    output:
        touch("checkpoints/functions_uniprot.done")

