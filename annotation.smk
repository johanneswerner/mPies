configfile: "annotation.json"

inputs = []

include:
    "rules/subset_sequences.smk"
inputs.append("checkpoints/subset_sequences.done")

if config["taxonomy"]["run_taxonomy"]:
    include:
        "rules/taxonomy.smk"
    inputs.append("checkpoints/taxonomy.done")

if config["functions"]["run_functions_cog"]:
    include:
        "rules/functions_cog.smk"
    inputs.append("checkpoints/functions_cog.done")
if config["functions"]["run_functions_uniprot"]:
    include:
        "rules/functions_uniprot.smk"
    inputs.append("checkpoints/functions_uniprot.done")

rule ALL:
    input:
        inputs
    output:
        touch("checkpoints/mpies.done")
