#!/usr/bin/env python

import os
import urllib.parse
import urllib.request
from ete3 import NCBITaxa


def get_taxid(input_file):
    """
    The function `get_taxid` returns a list of tax IDs based on tax names.

    Each line of the input_file has a tax name on each line. The function
    `get_taxid` returns a list with tax IDs with the same length.

    Parameters:
      input_file: file with tax names on each line

    Returns:
      tax_list: unique list with tax IDs
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


def get_protein_sequences(tax_list, output_folder, reviewed=False):
    """
    The function `get_protein_sequences` fetches the proteomes for all tax IDs.

    The function takes a list of tax IDs and downloads the protein sequences
    for the descending organisms.

    Parameters:
      tax_list: unique list with tax IDs
      reviewed: use TrEMBL (False) or SwissProt (True)

    Returns:
      taxon_list: unique list with taxon IDs
    """

    for taxid in tax_list:
        filename = output_folder + "/" + str(taxid) + ".fasta"

        taxon_queries = ['taxonomy:"%s"' % tid for tid in [taxid]]
        taxon_query = ' OR '.join(taxon_queries)
        rev = " reviewed:%s" % reviewed if reviewed else ''

        url = 'http://www.uniprot.org/uniprot/'
        query = "%s%s" % (taxon_query, rev)
        params = {'query': query, 'force': 'yes', 'format': 'fasta'}
        data = urllib.parse.urlencode(params).encode("utf-8")
        print(taxid)
        (fname, msg) = urllib.request.urlretrieve(url=url, filename=filename, data=data)
        headers = {j[0]: j[1].strip() for j in [i.split(':', 1) for i in str(msg).strip().splitlines()]}

        if 'Content-Length' in headers and headers['Content-Length'] == 0:
            os.remove(filename)

    return
