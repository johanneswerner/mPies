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

# mPies (metaProteomics in environmental sciences) creates annotated databases for metaproteomics analysis.
# Copyright 2018 Johannes Werner (Leibniz-Institute for Baltic Sea Research)
# Copyright 2018 Augustin Geron (University of Stirling)
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
