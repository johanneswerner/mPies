#!/usr/bin/env python

"""
Get the protein sequences for a list of genera.

The module uses a text file with a number of TaxIDs to download the protein sequences belonging to
the respective genera. The file `names.dmp` will be downloaded if it does not exist yet from the
NCBI FTP server. This file will be used to add the taxonomic lineage to the protein header.
Eventually, all protein sequences will be combined into one file.
"""

import logging
import os
import re
import tarfile
import urllib.parse
import urllib.request
from ete3 import NCBITaxa

module_logger = logging.getLogger("pies.use_amplicon")
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
    logger = logging.getLogger("pies.use_amplicon.get_desired_ranks")
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
    logger = logging.getLogger("pies.use_amplicon.get_taxid")
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
      absolute path of file names.dmpexampleApp.otherMod2

    """
    logger = logging.getLogger("pies.use_amplicon.get_names_dmp")
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

    logger.info("Downloading taxdump.tar.gz ...")
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

    Below, the first 10 lines of the current version of names.dmp are shown. The first column
    (`curr_line[0]`) represents the taxID, the second column (`curr_line[1]`) the name and the
    fourth column (`curr_line[3]`) if the name is a valid scientific name.

    ```
    $ head names.dmp

    1	|	all	|		|	synonym	|
    1	|	root	|		|	scientific name	|
    2	|	Bacteria	|	Bacteria <prokaryotes>	|	scientific name	|
    2	|	Monera	|	Monera <Bacteria>	|	in-part	|
    2	|	Procaryotae	|	Procaryotae <Bacteria>	|	in-part	|
    2	|	Prokaryota	|	Prokaryota <Bacteria>	|	in-part	|
    2	|	Prokaryotae	|	Prokaryotae <Bacteria>	|	in-part	|
    2	|	bacteria	|	bacteria <blast2>	|	blast name	|
    2	|	eubacteria	|		|	genbank common name	|
    2	|	not Bacteria Haeckel 1894	|		|	authority	|
    ```

    Parameter
    ---------
      abspath_names_dmp: absolute path of of names.dmp

    Returns
    -------
      ncbi_tax_dict: tax dictionary

    """
    logger = logging.getLogger("pies.use_amplicon.create_tax_dict")
    ncbi_tax_dict = {}
    ncbi_tax_dict[-1] = -1
    logger.info("creating tax dictionary ...")
    with open(abspath_names_dmp) as names_dmp_open:
        for line in names_dmp_open:
            curr_line = re.split(r"\t*\|\t*", line.rstrip())
            if curr_line[3] == "scientific name":
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
    logger = logging.getLogger("pies.use_amplicon.remove_linebreaks_from_fasta")
    fasta_file_backup = fasta_file + ".multiline.bak"
    os.rename(fasta_file, fasta_file_backup)
    # from https://stackoverflow.com/questions/50856538
    with open(fasta_file_backup, 'r') as f_input, open(fasta_file, 'w') as f_output:
        block = []

        for line in f_input:
            if line.startswith('>'):
                if block:
                    f_output.write(''.join(block) + '\n')
                    block = []
                f_output.write(line)
            else:
                block.append(line.strip())

        if block:
            f_output.write(''.join(block) + '\n')

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
    logger = logging.getLogger("pies.use_amplicon.add_taxonomy_to_fasta")
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
    logger = logging.getLogger("pies.use_amplicon.get_protein_sequences")
    logger.info("fetching protein sequences ...")
    for taxid in tax_list:
        filename = os.path.join(output_folder, str(taxid) + ".fasta")

        taxon_queries = ['taxonomy:"%s"' % tid for tid in [taxid]]
        taxon_query = ' OR '.join(taxon_queries)
        rev = " reviewed:%s" % reviewed if reviewed else ''

        url = 'http://www.uniprot.org/uniprot/'
        query = "%s%s" % (taxon_query, rev)
        params = {'query': query, 'force': 'yes', 'format': 'fasta'}
        data = urllib.parse.urlencode(params).encode("utf-8")
        logger.info("Taxid: " + str(taxid))
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
      fasta_path: absolute path of fasta file
      remove_single_files: removes the single fasta files after concatenating (default: True)

    Returns
    -------
      absolute file path

    """
    logger = logging.getLogger("pies.use_amplicon.combine_fasta_files")
    logger.info("combining fasta files ...")
    filenames = os.listdir(fasta_folder)
    complete_protein_file = os.path.join(os.path.abspath(fasta_folder), "proteins_amplicon.faa")
    with open(complete_protein_file, 'w') as outfile:
        for fname in filenames:
            current_file = os.path.join(fasta_folder, fname)
            with open(current_file) as infile:
                for line in infile:
                    outfile.write(line)
            if remove_single_files:
                os.remove(current_file)

    return complete_protein_file