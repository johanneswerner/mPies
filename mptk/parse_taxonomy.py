#!/usr/bin/env python

"""
Parse the MEGAN results table.

This module parses the MEGAN taxonomy table and creates a tab-separated table.
"""

import logging
import pandas as pd

logger = logging.getLogger("mptk.parse_taxonomy")


def parse_table(input_file, output_file):
    """
    Read the MEGAN results table and creates a tab-separated output table with the taxonomy results.

    The function `parse_table` reads the MEGAN taxonomy table produced by `blast2lca` from the MEGAN package.
    Unnecessary columns are removed and an output table is created

    Parameters
    ----------
      input_file: MEGAN taxonomy table
      output_file: a tab-separated table with accession number, taxonomic ranks, and score values

    Returns
    -------
      None

    """
    column_names = ["id", "_blank", "d_name", "d_score", "p_name", "p_score", "c_name", "c_score", "o_name", "o_score",
                    "f_name", "f_score", "g_name", "g_score", "s_name", "s_score", "__blank"],
    df = pd.read_csv(input_file, sep=";", engine="python", header=None, names=column_names, usecols=column_names)
    df.drop(df.columns[[1, -1]], axis=1, inplace=True)

    df.to_csv(output_file, sep="\t", encoding="utf-8", index=False)

    return None

