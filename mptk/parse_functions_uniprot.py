#!/usr/bin/env python

"""
Parse the results of the UniProt diamond output file.

This module parses the output of the diamond output table run against UniProt (either SwissProt or TrEMBL).
Afterwards, the output is joined with the GO categories of the protein (annotated by UniProt).
"""

import logging
import pandas as pd
import re

logger = logging.getLogger("mptk.parse_functions_uniprot")


def join_tables(df, uniprot_table, go_annotation):
    """
    Joins the data frame with the UniProt table.

    This function performs left-join-operations of the data frame with the processed UniProt table.

    Parameters
    ----------
      df: the data frame
      uniprot_table: the compressed Uniprot table *.dat.gz
                     (ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/)

    Returns
    -------
      df_uniprot: the joined table

    """
    if go_annotation:
        column_names_uniprot_table = ["uniprot_id", "GO_id", "GO_category"]
    else:
        column_names_uniprot_table = ["uniprot_id", "protein_name"]
    uniprot_table_df = pd.read_csv(uniprot_table, compression="gzip", sep="\t", header=None,
                                   names=column_names_uniprot_table, index_col=False)

    df.sseqid = df.sseqid.str.extract("^.{2}\|.+\|(.+)$", expand = True)
    df = df[["qseqid", "sseqid"]]

    df_uniprot = df.merge(uniprot_table_df, how="left", left_on="sseqid", right_on="uniprot_id").drop("uniprot_id", 1)

    return df_uniprot


def group_table(df, go_annotation=False):
    """
    Performs a group-by operation to count the occurences of the hits in the data frame.

    This function performs group-by operation with the diamond table to calculate the most abundant GO categories.

    Parameters
    ----------
      df: the data frame

    Returns
    -------
      df_uniprot: the joined table

    """
    if go_annotation:
        df = df[["qseqid", "GO_category"]]
        df_uniprot = df.groupby(["qseqid", "GO_category"]).size().reset_index(name='counts')
    else:
        df = df[["qseqid", "protein_name"]]
        df_uniprot = df.groupby(["qseqid", "protein_name"]).size().reset_index(name='counts')
    df_uniprot.sort_values(["qseqid", "counts"], ascending=[True, False], inplace=True)
    df_uniprot.rename(columns={"qseqid": "protein_group"}, inplace=True)
    df_uniprot["frac"] = df_uniprot["counts"]/df_uniprot.groupby("protein_group")["counts"].transform("sum")

    return df_uniprot


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


# mPies (metaProteomics in environmental sciences) creates annotated databases for metaproteomics analysis.
# Copyright 2018 Johannes Werner (Leibniz-Institute for Baltic Sea Research)
# Copyright 2018 Augustin Geron (University of Mons, University of Stirling)
# Copyright 2018 Sabine Matallana Surget (University of Stirling)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
