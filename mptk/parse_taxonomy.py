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
      output_file: path where to create output, a tab-separated table with accession number, taxonomic ranks, and
                   score values

    Returns
    -------
      None

    """
    column_names = ["id", "_blank", "d_name", "d_score", "p_name", "p_score", "c_name", "c_score", "o_name", "o_score",
                    "f_name", "f_score", "g_name", "g_score", "s_name", "s_score", "__blank"]
    df = pd.read_csv(input_file, sep=";", engine="python", header=None, names=column_names, usecols=list(range(17)))
    df.drop(df.columns[[1, -1]], axis=1, inplace=True)
    df.rename(columns={"id": "protein_group"}, inplace=True)

    df.to_csv(output_file, sep="\t", encoding="utf-8", index=False)

    return None


# mPies (metaProteomics in environmental sciences) creates annotated databases for metaproteomics analysis.
# Copyright 2018 Johannes Werner (Leibniz-Institute for Baltic Sea Research)
# Copyright 2018 Augustin Geron (University of Stirling)
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
#
