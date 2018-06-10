#!/usr/bin/env python

"""
Check the input assembled fasta file for valid protein fasta.

The passed file will be validated if it is a correct protein fasta file.
"""

import sys
from Bio import Alphabet
from Bio import SeqIO


def is_fasta(input_file):
    """
    Get taxonomic lineage on taxid for desired ranks.

    The function get_desired_ranks uses a taxid as input and returns a dict of ranks (superkingdom,
    phylum, class, order, family, genus, species) as keys and corresponding taxIDs as values.

    Parameters
    ----------
      taxid: TaxID (-1 represents unclassified)

    Returns
    -------
      ranks2lineage: dict with ranks as keys and taxIDs as values

    """
    with open(input_file, "r") as handle:
        fasta = SeqIO.parse(handle, "fasta", Alphabet.generic_protein)
        if any(fasta) is False:
            print(input_file + " is not a valid protein fasta file. Exit code: 4. Exiting ... ")
            sys.exit(4)
        else:
            return fasta
