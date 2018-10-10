include:
    "rules/otu_table"

inputs = []
inputs.append("get_amplicon_proteome.done")

rule ALL:
    input:
        inputs
    output:
        touch('checkpoints/mpies.done')
