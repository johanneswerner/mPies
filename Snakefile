configfile: "snake.json"

inputs = []

include:
    "rules/preprocessing.smk"
inputs.append("checkpoints/preprocessing.done")

include:
    "rules/otu_table.smk"
inputs.append("checkpoints/amplicon_proteome.done")

include:
    "rules/assembled.smk"
inputs.append("checkpoints/assembled_proteome.done")

include:
    "rules/unassembled.smk"
inputs.append("checkpoints/unassembled_proteome.done")

include:
    "rules/postprocessing.smk"
inputs.append("checkpoints/postprocessing.done")

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
        touch('checkpoints/mpies.done')
