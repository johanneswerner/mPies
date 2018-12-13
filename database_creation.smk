configfile: "database_creation.json"

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

rule ALL:
    input:
        inputs
    output:
        touch('checkpoints/mpies.done')


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
