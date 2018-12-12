#!/usr/bin/env python

"""
Parse the results of the COG diamond output file.

This module parses the output of the diamond output table run against the COG database. The output is joined with
different files from the COG FTP server and creates a table with protein IDs and COG categories.
"""

import logging
import numpy as np
import pandas as pd
import re

logger = logging.getLogger("mptk.parse_functions_cog")


def join_tables(df, cog_table, cog_names):
    """
    Joins the data frame with the COG tables.

    This function performs left-join-operations of the data frame with the tables downloaded from the COG FTP server.

    Parameters
    ----------
      df: the data frame
      cog_table: the COG csv table downloaded from COG FTP (ftp://ftp.ncbi.nih.gov/pub/COG/COG2014/data/)
      cog_names: the COG names table

    Returns
    -------
      df_cog: the joined table

    """
    column_names_cog_table = ["domain_id", "genome_name", "protein_id", "protein_length", "domain_start", "domain_end",
                              "COG_id", "membership_class"]
    cog_table_df = pd.read_csv(cog_table, sep=",", header=None, names=column_names_cog_table, index_col=False)
    cog_table_df = cog_table_df[["domain_id", "COG_id"]]

    column_names_cog_names = ["COG_id", "functional_class", "COG_annotation"]
    cog_names_df = pd.read_csv(cog_names, sep="\t", header=None, names=column_names_cog_names, comment="#", encoding="latin1")
    cog_names_df = cog_names_df[["COG_id", "functional_class"]]

    df.sseqid = df.sseqid.str.extract("^gi\|(.+)\|ref\|", expand = True)
    df.sseqid = df.sseqid.astype(np.int64)
    df = df[["qseqid", "sseqid"]]
    df = df.merge(cog_table_df, how="left", left_on="sseqid", right_on="domain_id").drop("domain_id", 1)
    df = df.merge(cog_names_df, how="left", on="COG_id")

    # https://stackoverflow.com/a/53261482/5013084
    # split dataframe column after each letter into different columns (without delimiter)
    df = pd.DataFrame([(*x[0:-1], y) for x in df.values.tolist() for y in list(x[-1])], columns=df.columns)

    return df


def group_table(df, cog_functions):
    """
    Performs a group-by operation to count the occurences of the hits in the data frame.

    This function performs group-by operation with the diamond table to calculate the most abundant COG categories.

    Parameters
    ----------
      df: the data frame
      cog_functions: the COG functions table

    Returns
    -------
      df: the joined table

    """
    column_names_cog_functions = ["functional_class", "functional_name"]
    cog_functions_df = pd.read_csv(cog_functions, sep="\t", header=None, names=column_names_cog_functions, comment="#")

    df = df[["qseqid", "functional_class"]]
    df = df.groupby(["qseqid", "functional_class"]).size().reset_index(name='counts')
    df = df.merge(cog_functions_df, how="left", on="functional_class")
    cols = ["qseqid", "functional_class", "functional_name", "counts"]
    df = df[cols]
    df.sort_values(["qseqid", "counts"], ascending=[True, False], inplace=True)
    df.rename(columns={"qseqid": "protein_group"}, inplace=True)

    return df


def export_table(df, output_file):
    """
    Exports the data frame.

    This function exports the data frame as tab separated table.

    Parameters
    ----------
      df: the data frame
      output_file: file path for the output file

    Returns
    -------
      None

    """
    df.to_csv(output_file, sep="\t", encoding="utf-8", index=False)

    return None

