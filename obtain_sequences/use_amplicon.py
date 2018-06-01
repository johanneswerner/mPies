#!/usr/bin/env python

from ete3 import NCBITaxa


def get_taxid(input_file):
    """
    The function `get_taxid` returns a list of taxon IDs based on taxon names.

    Each line of the input_file has a taxon name on each line. The function
    `get_taxid` returns a list with taxids with the same length.

    Parameters:
      input_file: file with taxon names on each line

    Returns:
      taxon_list: unique list with taxon IDs
    """

    ncbi = NCBITaxa()
    names_list = []
    tax_list = []

    with open(input_file) as f:
        for line in f:
            names_list.append(line.rstrip())

    tax_dict = ncbi.get_name_translator(names_list)
    for key in tax_dict:
        tax_list.append(tax_dict[key][0])

    tax_list = list(set(tax_list))

    return tax_list
