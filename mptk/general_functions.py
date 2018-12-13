#!/usr/bin/env python

"""
Provide general functions necessary for multiple modules

This module includes the functions `get_desired_ranks`, `get_names_dmp`, and `create_tax_dict` to download and access
the NCBI taxonomy.
"""

import gzip
import logging
import os
import pandas as pd
import re
import tarfile
import urllib.parse
import urllib.request
from ete3 import NCBITaxa

logger = logging.getLogger("pies.general_functions")
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
    ncbi_tax_dict = {}
    ncbi_tax_dict[-1] = -1
    logger.info("creating tax dictionary ...")
    with open(abspath_names_dmp) as names_dmp_open:
        for line in names_dmp_open:
            curr_line = re.split(r"\t*\|\t*", line.rstrip())
            if curr_line[3] == "scientific name":
                ncbi_tax_dict[int(curr_line[0])] = curr_line[1]

    return ncbi_tax_dict


def parse_uniprot_file(uniprot_file, uniprot_table, go_annotation=False):
    """
    Parse GO annotations from UniProt dat files.

    The function uses the dat file from the UniProt FTP Server and creates a tab-separated file with accession number
    and corresponding GO annotations.

    Parameters
    ----------
      uniprot_file: the zipped UniProt dat file

    Returns
    -------
      None

    """
    with gzip.open(uniprot_file, "rt") as f, gzip.open(uniprot_table, "wb") as uniprot_table_open:
        for line in f:
            if re.match(r"ID", line):
                id_field = line.split()[1]
            if go_annotation:
                if re.match(r"DR\s+GO;", line):
                    go_field = line.split(maxsplit=1)[1:]
                    go_field = go_field[0].split("; ")[1:3]
                    uniprot_table_open.write(bytes(id_field + "\t" + go_field[0] + "\t" + go_field[1] + "\n", encoding="utf-8"))
            else:
                if re.match(r"DE\s+RecName:", line):
                    proteinname = line.split(maxsplit=1)[1:]
                    proteinname_field = proteinname[0].split("=")[1].rstrip()
                    uniprot_table_open.write(bytes(id_field + "\t" + proteinname_field + "\n", encoding="utf-8"))

    return None


def parse_diamond_output(diamond_file):
    """
    Read the output table created by diamond and return a corresponding pandas data frame from it.

    The function `parse_diamond_output` reads the diamond table and returns a pandas data frame.

    Parameters
    ----------
      diamond_file: diamond output file

    Returns
    -------
      df: a pandas data frame of the diamond output

    """
    column_names = ["qseqid", "sseqid", "pident", "length", "mismatch", "gapopen", "qstart", "qend", "sstart", "send", "evalue", "bitscore"]
    df = pd.read_csv(diamond_file, sep="\t", header=None, names=column_names)

    return df


def map_protein_groups(diamond_file, excel_file, diamond_file_protein_groups):
    """
    Replaces protein ids with protein groups in diamond output file.

    The function `map_protein_groups` uses the protein groups from the ProteinPilot result file and maps them back on
    the diamond output file. The function creates an updated diamond file with protein groups in the first column.

    Parameters
    ----------
      diamond_file: diamond output file
      excel_file: the ProteinPilot result excel file
      diamond_file_protein_groups: diamond output file with protein groups as qseqid

    Returns
    -------
      None

    """
    column_names = ["qseqid", "sseqid", "pident", "length", "mismatch", "gapopen", "qstart", "qend", "sstart", "send", "evalue", "bitscore"]
    diamond_df = pd.read_csv(diamond_file, sep="\t", header=None, names=column_names)

    excel_df = pd.read_excel(excel_file)
    excel_df = excel_df[["N", "Accession"]]
    excel_df["Accession"] = excel_df["Accession"].str.split("|", expand=False).str[0]

    diamond_df = pd.merge(left=diamond_df, right=excel_df.set_index("Accession"), how="left", left_on="qseqid",
                          right_index=True, sort=False)
    diamond_df["qseqid"] = diamond_df["N"]
    diamond_df = diamond_df.drop("N", axis=1)
    diamond_df = diamond_df.sort_values(by=["qseqid", "bitscore"], ascending=[True, False])

    diamond_df.to_csv(diamond_file_protein_groups, sep="\t", encoding="utf-8", index=False, header=False)

    return None


def export_result_tables(excel_file, annotated_table, output_table):
    """
    The function `export_result_tables` merges the excel file with the annotations.

    The columns of interest from the Excel file are merged and exported with the annotations (including taxonomy
    inferred from MEGAN/LCA and function based on COG or UniProt).

    Parameters
    ----------
      excel_file: the ProteinPilot result excel file
      annotated_table: table containing protein group and annotation (taxonomy or function)
      output_table: file of merged table

    Returns
    -------
      None

    """
    excel_df = pd.read_excel(excel_file)
    excel_df = excel_df[["N", "Accession", "Peptides(95%)"]]
    excel_df["Accession"] = excel_df["Accession"].str.split("|", expand=False).str[0]

    df_annotated = pd.read_csv(annotated_table, sep="\t")
    merged_df = pd.merge(left=excel_df, right=df_annotated.set_index("protein_group"), how="left", left_on="N",
                         right_index=True, sort=False)

    merged_df.to_csv(output_table, sep="\t", encoding="utf-8", index=False, header=True)

    return None

