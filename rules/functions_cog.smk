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
        expand("{sample}/identified/Gel_based_Combined_DBs_small.xlsx", sample=config["sample"])
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
        expand("{sample}/identified/Gel_based_Combined_DBs_small.xlsx", sample=config["sample"]),
        expand("{sample}/functions/metaproteome.functions.cog.parsed_table.tsv", sample=config["sample"])
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

