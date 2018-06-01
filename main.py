#!/usr/bin/env python

import argparse
from obtain_sequences import use_amplicon

parser = argparse.ArgumentParser()
parser.add_argument("-g", "--genus_list", action="store",
                    dest="genus_list", required=True)
parser.add_argument("-o", "--output_folder", action="store",
                    dest="output_folder", required=True)
args = parser.parse_args()

taxids = use_amplicon.get_taxid(input_file=args.genus_list)
use_amplicon.get_protein_sequences(taxids, args.output_folder)
