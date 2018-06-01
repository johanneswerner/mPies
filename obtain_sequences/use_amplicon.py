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


# import urllib.parse, urllib.request
#
# taxids = set(["146825"])
# taxon_queries = ['taxonomy:"%s"' % taxid for taxid in taxids]
# taxon_query = ' OR '.join(taxon_queries)
# # reviewed = True
# reviewed = False
# rev = " reviewed:%s" % reviewed if reviewed else ''
# url = 'http://www.uniprot.org/uniprot/'
# query = "%s%s" % (taxon_query, rev)
# params = {'query': query, 'force': 'yes', 'format': 'fasta'}
# data = urllib.urlencode(params)
# (fname, msg) = urllib.urlretrieve(url=url, filename="/tmp/out.fasta", data=data)
# headers = {j[0]: j[1].strip() for j in [i.split(':', 1) for i in str(msg).strip().splitlines()]}
# if 'Content-Length' in headers and headers['Content-Length'] == 0:
#     pass
