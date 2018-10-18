include:
#    "rules/otu_table.smk",
    "rules/assembled.smk"

inputs = []
# inputs.append("checkpoints/get_amplicon_proteome.done")
inputs.append("checkpoints/get_assembled_proteome.done")

rule ALL:
    input:
        inputs
    output:
        touch('checkpoints/mpies.done')
