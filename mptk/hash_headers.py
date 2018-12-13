#!/usr/bin/env python

"""
This module hashes the headers of the proteome file.
"""

import hashlib
import logging

logger = logging.getLogger("mptk.hashing")


def write_hashed_protein_header_fasta_file(input_file, output_file, tsv_file, hash_type):
    """
    Hash headers of proteome file.

    The function write_hashed_protein_header_fasta_file calculates the hash value for each proteome header and creates
    a fasta file with hashed headers. Hashing the protein headers is performed because several downstream software
    tools (e.g. ProteinPilot) are keeping not only the sequence but also the headers in-memory. Therefore, shorter
    fasta headers allow processing more reference protein sequences in one run.

    Additionally, a tsv file with two column is created that maps the hashed header
    to the original headers. The function returns None.

    Parameters
    ----------
      input_file: input proteome file
      output_file: output proteome file with hashed headers
      tsv_file: output tsv file
      hash_type: hash algorithm to use

    Returns
    -------
      None
    """
    h = hashlib.new(hash_type)

    with open(input_file) as input_file_open, open(output_file, "w") as output_file_open, open(tsv_file, "w") as tsv_file_open:
        for line in input_file_open:
            if line.startswith(">"):
                header_substring = line.rstrip()[1:]
                h.update(header_substring.encode("utf-8")) # .hexdigest()
                hashed_header = h.hexdigest()
                quoted_hashed_header = '\"' + hashed_header + '\"'
                output_file_open.write(">" + hashed_header + "\n")
                tsv_file_open.write(quoted_hashed_header + "\t" + header_substring + "\n")
            else:
                output_file_open.write(line)

    return

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
