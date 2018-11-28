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

