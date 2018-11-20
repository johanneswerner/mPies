#!/usr/bin/env python

"""
Get the protein sequences for a list of genera.

The module uses a text file with a number of TaxIDs to download the protein sequences belonging to
the respective genera. The taxonomic lineage will be added to the protein header.
"""

import logging
import os
import re
import urllib.parse
import urllib.request
from ete3 import NCBITaxa
from pies import general_functions

logger = logging.getLogger("pies.use_amplicon")
NCBI = NCBITaxa()


def get_taxid(input_file):
    """
    Return a list of tax IDs based on tax names.

    Each line of the input_file has a tax name on each line. The function `get_taxid` returns a
    list with tax IDs with the same length.

    Parameters
    ----------
      input_file: file with tax names on each line

    Returns
    -------
      tax_list: unique list with tax IDs

    """
    names_list = []
    tax_list = []

    with open(input_file) as input_file_open:
        for line in input_file_open:
            names_list.append(line.rstrip())

    tax_dict = NCBI.get_name_translator(names_list)
    for key in tax_dict:
        tax_list.append(tax_dict[key][0])

    tax_list = list(set(tax_list))

    return tax_list


def add_taxonomy_to_fasta(fasta_file, ncbi_tax_dict):
    """
    Add taxonomy to headers.

    The function adds the complete taxonomic lineage to the fasta header (superkingdom, phylum,
    class, order, family, genus).

    Parameter
    ---------
      fasta_file: input fasta file
      ncbi_tax_dict: taxonomy dictionary generated by general_functions.create_tax_dict()

    Returns
    -------
      None

    """
    output_filename = os.path.splitext(fasta_file)[0] + "_tax.fasta"
    with open(fasta_file) as fasta_file_open, open(output_filename, "w") as output_file_open:
        for line in fasta_file_open:
            if line.startswith(">"):
                rx_match = re.search(r"OS=(\w+)\s", line)
                if rx_match:
                    taxid = rx_match.group(1)

                    res = []
                    for rank in ["superkingdom", "phylum", "class", "order", "family", "genus"]:
                        res.append(str(ncbi_tax_dict[get_desired_ranks(taxid)[rank]]))

                    header_extension = ", ".join(res)
                else:
                    header_extension = "not_found"
                output_file_open.write(line.rstrip() + " TAX=" + header_extension + "\n")
            else:
                output_file_open.write(line)
        
    return None


def get_protein_sequences(tax_list, output_file, ncbi_tax_dict, reviewed=False,
                          add_taxonomy=True, remove_backup=True):
    """
    Fetch the proteomes for all tax IDs.

    The function takes a list of tax IDs and downloads the protein sequences for the descending
    organisms.

    Parameters
    ----------
      tax_list: unique list with tax IDs
      output_file: output file for the downloaded protein sequences
      reviewed: use TrEMBL (False) or SwissProt (True)

    Returns
    -------
      None

    """
    logger.info("fetching protein sequences ...")
    filename = output_file

    taxon_queries = ['taxonomy:"%s"' % tid for tid in tax_list]
    taxon_query = ' OR '.join(taxon_queries)
    rev = " reviewed:%s" % reviewed if reviewed else ''

    url = 'https://www.uniprot.org/uniprot/'
    query = "%s%s" % (taxon_query, rev)
    params = {'query': query, 'force': 'yes', 'format': 'fasta'}
    data = urllib.parse.urlencode(params).encode("utf-8")
    logger.info("Taxid: " + str(tax_list))
    msg = urllib.request.urlretrieve(url=url, filename=filename, data=data)[1]
    headers = {j[0]: j[1].strip() for j in [i.split(':', 1)
                                                for i in str(msg).strip().splitlines()]}

    if 'Content-Length' in headers and headers['Content-Length'] == 0:
        os.remove(filename)

    if add_taxonomy:
        add_taxonomy_to_fasta(filename, ncbi_tax_dict)

    return

