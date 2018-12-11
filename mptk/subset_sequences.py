#!/usr/bin/env python

"""
Create sequence subset of identified sequences.

This module uses the result files of protein pilot and the generated database from the first step of mPies to create
a subset protein fasta file with only identified protein sequences.
"""

import logging
import pandas as pd
import re

logger = logging.getLogger("pies.subset_sequences")


def parse_proteinpilot_file(excel_file):
    """
    Parses the ProteinPilot result Excel file.

    The function parse_proteinpilot_file extracts the columns N, Accession, and Peptides(95%) from the UniProt results
    file.

    Parameters
    ----------
      excel_file: the ProteinPilot result excel file

    Returns
    -------
      df: a data frame with the kept columns

    """
    df = pd.read_excel(excel_file)
    # df = df.columns
    df = df[["N", "Accession", "Peptides(95%)"]]
    df["Accession"] = df["Accession"].str.split("|", expand=False).str[0]

    return df

