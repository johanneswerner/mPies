rule subset_sequences:
    input:
        #config["excel_file"],
        "{sample}/identified/{identified_id}.xlsx",
        "{sample}/proteome/metaproteome.hashed.faa"
    output:
        "{sample}/annotated/{identified_id}/proteome/metaproteome.subset.faa"
    params:
        mode=config["subset_sequences"]["mode"]
    log:
        "{sample}/log/mptk_subsetsequences_{identified_id}.log"
    shell:
        """
        ./main.py -v -e {log} {params.mode} -e {input[0]} -d {input[1]} -s {output}
        """

rule subset_sequences_done:
    input:
        expand("{sample}/annotated/{identified_id}/proteome/metaproteome.subset.faa", sample=config["sample"], identified_id=identified_ids)
    output:
        touch("checkpoints/subset_sequences.done")


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
