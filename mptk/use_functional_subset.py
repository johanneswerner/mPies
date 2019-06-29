#!/usr/bin/env python

"""
Get the gene names and protein names for certain taxonomic groups.

The module uses a text file in TOML format to fetch all sequences from UniProt with certain gene or protein names and a certain taxonomy.
"""

import logging
import toml

logger = logging.getLogger("pies.use_functional_subset")


def search_lists_to_query_url(toml_file, search_prots, search_genes, tax_limits):
    """
    Return the query to download the sequences of interest from UniProt.

    Based on the list of protein, gene and taxonomic restrictions, the function creates a query that gets passed
    to the UniProt API.

    Parameters
    ----------
      search_prots: protein name subset
      search_genes: exact gene name subset
      tax_limits: taxonomy subset
      toml_file: the TOML file passed by the user

    Returns
    -------
      the query to pass to UniProt

    """
    toml_parsed = toml.load(toml_file)
    tax_limits = toml_parsed["Taxonomy"]
    search_prots = toml_parsed["Protein_names"]
    search_genes = toml_parsed["Gene_names"]

    return '( {taxlimit} ) AND ( {protquery} )'.format(
        taxlimit=' OR '.join([ 'taxonomy:"%s"' % t for t in tax_limits ]),
        protquery=' OR '.join(
           [ 'name:"%s"' % n for n in search_prots ]
           + [ 'gene_exact:"%s"' % g for g in search_genes ]
        ),
      )


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
