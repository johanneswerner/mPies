#!/usr/bin/env python

"""
Check the input assembled fasta file for valid protein fasta.

The passed file will be validated if it is a correct protein fasta file.
"""

import logging
import os
from Bio import Alphabet
from Bio import SeqIO

module_logger = logging.getLogger("pies.use_amplicon")


def is_fasta(input_file, output_folder):
    """
    Check if input file is a valid fasta file.

    The function checks if the input file is a valid fasta file and if so generates a single line
    fasta file and copies it to the output folder.

    Parameters
    ----------
      input_fasta: input assembled metagenome fasta file
      output_folder: output folder

    Returns
    -------
      absolute path of single line protein fasta

    """
    logger = logging.getLogger("pies.use_assembled.is_fasta")
    with open(input_file, "r") as handle:
        fasta = SeqIO.parse(handle, "fasta", Alphabet.generic_protein)
        if any(fasta) is False:
            logger.error("Not a valid protein fasta file. Exiting ... ")
            raise TypeError("'%s' is not a valid protein fasta file." % input_file)
        else:
            output_fasta = os.path.join(output_folder, os.path.basename(input_file))
            with open(output_fasta, 'w') as output_fasta_open:
                for record in fasta:
                    sequence = str(record.seq)
                    output_fasta_open.write('>' + record.id + '\n' + sequence + '\n')
            return os.path.abspath(output_fasta)
