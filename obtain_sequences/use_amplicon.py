#!/usr/bin/env python

"""
Get the protein sequences for a list of genera.

The module uses a text file with a number of TaxIDs to download the protein sequences belonging to
the respective genera. The file `names.dmp` will be downloaded if it does not exist yet from the
NCBI FTP server. This file will be used to add the taxonomic lineage to the protein header.
Eventually, all protein sequences will be combined into one file.
"""

import os
import re
import sys
import tarfile
import urllib.parse
import urllib.request
from ete3 import NCBITaxa

NCBI = NCBITaxa()


def get_desired_ranks(taxid):
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
    if taxid == -1:
        return {"superkingdom": -1, "phylum": -1, "class": -1, "order": -1, "family": -1,
                "genus": -1}
    lineage = NCBI.get_lineage(taxid)
    lineage2ranks = NCBI.get_rank(lineage)
    ranks2lineage = dict((rank, taxid) for (taxid, rank) in lineage2ranks.items())
    for taxrank in ["superkingdom", "phylum", "class", "order", "family", "genus"]:
        if taxrank not in ranks2lineage:
            ranks2lineage[taxrank] = -1
    return ranks2lineage


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


def get_names_dmp(names_dmp=None):
    """
    Download names.dmp.

    The function downloades the names.dmp file if not already existing or if the file size is zero.

    Parameter
    ---------
      names_dmp: location of names.dmp (default: None)

    Returns
    -------
      absolute path of file names.dmp

    """
    if names_dmp is not None:
        if os.stat(names_dmp).st_size == 0:
            os.remove(names_dmp)
        else:
            return os.path.abspath(names_dmp)
    else:
        names_dmp = "names.dmp"
        if os.path.isfile("names.dmp"):
            if os.stat(names_dmp).st_size != 0:
                return os.path.abspath(names_dmp)
            else:
                os.remove(names_dmp)

    # TODO: @kerssema: Does this statement belong into a function? Or should I use the logging
    # module to only print this when debug flag is set?
    print("Downloading taxdump.tar.gz ...")
    urllib.request.urlretrieve("ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz",
                               filename="taxdump.tar.gz")
    tar = tarfile.open("taxdump.tar.gz")
    tar.extract("names.dmp")
    tar.close()
    os.remove("taxdump.tar.gz")

    return os.path.abspath("names.dmp")


def create_tax_dict(abspath_names_dmp):
    """
    Create a taxonomy dictionary with taxID as keys and tax names as values.

    The function uses names.dmp to create a tax dictionary to map taxIDs onto tax names.

    Parameter
    ---------
      abspath_names_dmp: absolute path of of names.dmp

    Returns
    -------
      ncbi_tax_dict: tax dictionary

    """
    ncbi_tax_dict = {}
    ncbi_tax_dict[-1] = -1
    # TODO: @kerssema: same as before? print statement inside function?
    print("creating tax dictionary ...")
    with open(abspath_names_dmp) as names_dmp_open:
        for line in names_dmp_open:
            curr_line = re.split(r"\t*\|\t*", line.rstrip())
            if curr_line[-2] == "scientific name":
                ncbi_tax_dict[int(curr_line[0])] = curr_line[1]

    return ncbi_tax_dict


def remove_linebreaks_from_fasta(fasta_file, remove_backup=True):
    """
    Remove all line breaks within sequences.

    The function `remove_linebreaks_from_fasta` reads a fasta file and removes all linebreaks from
    the sequences. The resulting fasta file is saved as the same name as the previous one (the old
    file gets backed up and deleted - this can be adjusted with a parameter).

    Parameter
    ---------
      fasta_file: input fasta file (multiline sequence)
      remove_backup: remove backup of old file (True)

    Returns
    -------
      None

    """
    try:
        with open(fasta_file, "r") as fasta_file_open:
            sequences = fasta_file_open.read()
            sequences = re.split("^>", sequences, flags=re.MULTILINE)
            del sequences[0]
    except IOError:
        print("Failed to open " + fasta_file)
        # TODO: set correct error code
        sys.exit(2)

    # TODO: check permission
    fasta_file_backup = fasta_file + ".multiline.bak"
    os.rename(fasta_file, fasta_file_backup)

    try:
        with open(fasta_file, "w") as fasta_file_sl:
            for fasta in sequences:
                try:
                    header, sequence = fasta.split("\n", 1)
                except ValueError:
                    print(fasta)
                header = ">" + header + "\n"
                sequence = sequence.replace("\n", "") + "\n"
                fasta_file_sl.write(header + sequence)
    except IOError:
        print("Failed to open " + fasta_file)
        sys.exit(3)

    # TODO: set correct error code
    if remove_backup:
        os.remove(fasta_file_backup)

    return


def add_taxonomy_to_fasta(fasta_file, ncbi_tax_dict, remove_backup=True):
    """
    Add taxonomy to headers.

    The function adds the complete taxonomic lineage to the fasta header (superkingdom, phylum,
    class, order, family, genus). The resulting fasta file is saved as the same name as the
    previous one (the old file gets backed up and deleted - this can be adjusted with a parameter).

    Parameter
    ---------
      fasta_file: input fasta file
      remove_backup: remove backup of old file (True)

    Returns
    -------
      None

    """
    rx_match = re.search(r"(\d+)\.fasta$", fasta_file)
    if rx_match:
        taxid = rx_match.group(1)

        res = []
        for rank in ["superkingdom", "phylum", "class", "order", "family", "genus"]:
            res.append(str(ncbi_tax_dict[get_desired_ranks(taxid)[rank]]))

        header_extension = ", ".join(res)

        fasta_file_backup = fasta_file + ".notax.bak"
        os.rename(fasta_file, fasta_file_backup)

        output_file = open(fasta_file, "w")
        for line in open(fasta_file_backup, "r"):
            if line.startswith(">"):
                output_file.write(line.rstrip() + " TAX=" + header_extension + "\n")
            else:
                output_file.write(line)

        if remove_backup:
            os.remove(fasta_file_backup)

    return None


def get_protein_sequences(tax_list, output_folder, ncbi_tax_dict, reviewed=False,
                          add_taxonomy=True, remove_backup=True):
    """
    Fetch the proteomes for all tax IDs.

    The function takes a list of tax IDs and downloads the protein sequences for the descending
    organisms.

    Parameters
    ----------
      tax_list: unique list with tax IDs
      output_folder: output folder for the downloaded protein sequences
      reviewed: use TrEMBL (False) or SwissProt (True)

    Returns
    -------
      None

    """
    print("fetching protein sequences ...")
    for taxid in tax_list:
        filename = os.path.join(output_folder, str(taxid) + ".fasta")

        taxon_queries = ['taxonomy:"%s"' % tid for tid in [taxid]]
        taxon_query = ' OR '.join(taxon_queries)
        rev = " reviewed:%s" % reviewed if reviewed else ''

        url = 'http://www.uniprot.org/uniprot/'
        query = "%s%s" % (taxon_query, rev)
        params = {'query': query, 'force': 'yes', 'format': 'fasta'}
        data = urllib.parse.urlencode(params).encode("utf-8")
        print(taxid)
        msg = urllib.request.urlretrieve(url=url, filename=filename, data=data)[1]
        headers = {j[0]: j[1].strip() for j in [i.split(':', 1)
                                                for i in str(msg).strip().splitlines()]}

        if 'Content-Length' in headers and headers['Content-Length'] == 0:
            os.remove(filename)

        # TODO: @kerssema Can I call the function from here or would it be
        # nicer to call this in the main loop with a for loop over the
        # directory?
        # transform multiline sequences into singelline sequences

        remove_linebreaks_from_fasta(filename, remove_backup)
        if add_taxonomy:
            add_taxonomy_to_fasta(filename, ncbi_tax_dict, remove_backup)

    return


def combine_fasta_files(fasta_folder, remove_single_files=True):
    """
    Combine all fasta files.

    The function concatenates all fasta files and removes the single files (default, can be set
    as parameter).

    Parameters
    ----------
      fasta_path:

    Returns
    -------
      absolute file path

    """
    print("combining fasta files ...")
    filenames = os.listdir(fasta_folder)
    complete_protein_file = os.path.join(fasta_folder, "proteins_amplicon.faa")
    with open(complete_protein_file, 'w') as outfile:
        for fname in filenames:
            current_file = os.path.join(fasta_folder, fname)
            with open(current_file) as infile:
                for line in infile:
                    outfile.write(line)
            if remove_single_files:
                os.remove(current_file)

    return complete_protein_file
