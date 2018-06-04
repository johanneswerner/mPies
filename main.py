#!/usr/bin/env python

import argparse
from obtain_sequences import use_amplicon

parser = argparse.ArgumentParser()
parser.add_argument("-g", "--genus_list", action="store", dest="genus_list", required=True,
                    help="list of genera used for amplicon analysis")
parser.add_argument("-o", "--output_folder", action="store", dest="output_folder", required=True,
                    help="output folder")
parser.add_argument("-n", "--names_dmp", action="store", dest="names_dmp", default=None, required=False,
                    help="location of names.dmp")
args = parser.parse_args()

# TODO: exclusive list of arguments for amplicon, assmbled, not-assembled
# run amplicon analysis

## get unique list of taxids based on genus names
taxids = use_amplicon.get_taxid(input_file=args.genus_list)

## get protein sequences for taxids
use_amplicon.get_protein_sequences(taxids, args.output_folder)

## get names.dmp
use_amplicon.get_names_dmp(args.names_dmp)


## add taxonomy


# run assembled metagenome analysis

# run unassembled metagenome analysis

# remove duplicates

# hash headers
