#!/usr/bin/env python

import os
import re
import sys
import urllib.parse
import urllib.request
from ete3 import NCBITaxa

ncbi = NCBITaxa()


def get_desired_ranks(taxid):
    """
    Get taxonomic lineage on taxid for desired ranks.

    The function get_desired_ranks uses a taxid as input and returns a dict
    of ranks (superkingdom, phylum, class, order, family, genus, species) as
    keys and corresponding taxIDs as values.

    Parameters:
      taxid: TaxID (-1 represents unclassified)

    Returns:
      ranks2lineage: dict with ranks as keys and taxIDs as values
    """

    if taxid == -1:
        return {"superkingdom": -1, "phylum": -1, "class": -1, "order": -1,
                "family": -1, "genus": -1, "species": -1}
    lineage = ncbi.get_lineage(taxid)
    lineage2ranks = ncbi.get_rank(lineage)
    ranks2lineage = dict((rank, taxid)
                         for (taxid, rank) in lineage2ranks.items())
    for item in list(ranks2lineage):
        for taxrank in ["superkingdom", "phylum", "class", "order",
                        "family", "genus", "species"]:
            if taxrank not in ranks2lineage:
                ranks2lineage[taxrank] = -1
    return ranks2lineage


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
      output_folder: output folder for the downloaded protein sequences
      reviewed: use TrEMBL (False) or SwissProt (True)

    Returns:
      None
    """

    for taxid in tax_list:
        # TODO: use os module to concatenate folder and filename
        filename = output_folder + "/" + str(taxid) + ".fasta"

        taxon_queries = ['taxonomy:"%s"' % tid for tid in [taxid]]
        taxon_query = ' OR '.join(taxon_queries)
        rev = " reviewed:%s" % reviewed if reviewed else ''

        url = 'http://www.uniprot.org/uniprot/'
        query = "%s%s" % (taxon_query, rev)
        params = {'query': query, 'force': 'yes', 'format': 'fasta'}
        data = urllib.parse.urlencode(params).encode("utf-8")
        print(taxid)
        (fname, msg) = urllib.request.urlretrieve(url=url,
                                                  filename=filename, data=data)
        headers = {j[0]: j[1].strip()
                   for j in [i.split(':', 1)
                             for i in str(msg).strip().splitlines()]}

        if 'Content-Length' in headers and headers['Content-Length'] == 0:
            os.remove(filename)

        # TODO: @kerssema Can I call the function from here or would it be
        # nicer to call this in the main loop with a for loop over the
        # directory?
        # transform multiline sequences into singelline sequences

        remove_linebreaks_from_fasta(filename, remove_backup=True)

    return


def remove_linebreaks_from_fasta(fasta_file, remove_backup=True):
    """
    The function removes all line breaks within sequences.

    The function `remove_linebreaks_from_fasta` reads a fasta file and removes
    all linebreaks from the sequences. The resulting fasta file is saved as the
    same name as the previous one (the old file gets backed up and deleted -
    this can be adjusted with a parameter).

    Parameters:
      fasta_file: input fasta file (multiline sequence)
      remove_backup: remove backup of old file (True)

    Returns:
      None
    """
    try:
        with open(fasta_file, "r") as newFile:
            sequences = newFile.read()
            sequences = re.split("^>", sequences, flags=re.MULTILINE)
            del sequences[0]
    except IOError:
        print("Failed to open " + fasta_file)
        # TODO: set correct error code
        sys.exit(1)

    # TODO: check permission
    inFile_backup = fasta_file + ".bak"
    os.rename(fasta_file, inFile_backup)

    try:
        with open(fasta_file, "w") as newFasta:
            for fasta in sequences:
                try:
                    header, sequence = fasta.split("\n", 1)
                except ValueError:
                    print(fasta)
                header = ">" + header + "\n"
                sequence = sequence.replace("\n", "") + "\n"
                newFasta.write(header + sequence)
    except IOError:
        print("Failed to open " + fasta_file)
        sys.exit(2)

    # TODO: set correct error code
    if remove_backup:
        os.remove(inFile_backup)

    return


# import re
#
#
# ncbi_tax_dict = {}
# ncbi_tax_dict[-1] = -1
# with open("names.dmp") as f:
#     for line in f:
#         curr_line = re.split(r"\t*\|\t*", line.rstrip())
#         if curr_line[-2] == "scientific name":
#             ncbi_tax_dict[int(curr_line[0])] = curr_line[1]
#
# os.chdir("/data/projects/Stirling/Metaproteomics_Day_Night_Cycle/build_proteomic_database/proteome_data")
# for fileold in os.listdir("."):
#     rx_match = re.search(r"^(\d+)\.faa$", fileold)
#     if rx_match:
#         # print(file)
#         taxid = rx_match.group(1)
#
#         res = []
#         for rank in ["superkingdom", "phylum", "class", "order", "family", "genus"]:
#             res.append(str(ncbi_tax_dict[get_desired_ranks(taxid)[rank]]))
#
#         print(fileold)
#         header_extension = ", ".join(res)
#         filenewname = fileold.replace(".faa", "_headerext.faa")
#
#         filenew = open(filenewname, "w")
#         for line in open(fileold, "r"):
#             if line.startswith(">"):
#                 filenew.write(line.rstrip() + " TAX=" + header_extension + "\n")
#             else:
#                 filenew.write(line)
