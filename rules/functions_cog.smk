rule run_diamond_cog:
    input:
        expand("{sample}/proteome/combined.mincutoff.nodup.hashed.faa", sample=config["sample"])
    output:
        expand("{sample}/functions/cog/combined.cog.diamond.tsv", sample=config["sample"])
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
          -k {params.maxtargetseqs} -e {params.score} --compress {params.compress} {params.sensitive} \
          -q {input} -o {output} > {log} 2>&1
        """

# rule parse_taxonomy:
#     input:
#         expand("{sample}/taxonomy/combined.megan.txt", sample=config["sample"])
#     output:
#         expand("{sample}/taxonomy/combined.tax.txt", sample=config["sample"])
#     params:
#         mode=config["taxonomy"]["parse_taxonomy"]["mode"],
#     shell:
#         "./main.py -v {params.mode} -m {input} -t {output}"

rule get_functions_cog_done:
    input:
        expand("{sample}/functions/cog/combined.cog.diamond.tsv", sample=config["sample"])
    output:
        touch("checkpoints/functions_cog.done")

