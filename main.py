#!/usr/bin/env python

import argparse
from obtain_sequences import use_amplicon

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--mode", choices=["amplicon", "assembled", "unassembled"], dest="mode",
                    required=True, help="mode for analysis (amplicon, assembled, unassembled)")
args = parser.parse_known_args()[0]
if args.mode == "amplicon":
    parser.add_argument("-b", "--remove_backup", action="store_false", dest="remove_backup",
                        required=False, help="remove backup files")
    parser.add_argument("-g", "--genus_list", action="store", dest="genus_list", required=True,
                        help="list of genera used for amplicon analysis")
    parser.add_argument("-n", "--names_dmp", action="store", dest="names_dmp", default=None,
                        required=False, help="location of names.dmp")
    parser.add_argument("-r", "--reviewed", action="store_true", dest="reviewed", required=False,
                        help="use all unreviewed TrEMBL hits (default) or only reviewed SwissProt")
    parser.add_argument("-t", "--taxonomy", action="store_false", dest="taxonomy", required=False,
                        help="add taxonomic lineage to fasta header")
parser.add_argument("-o", "--output_folder", action="store", dest="output_folder", required=True,
                    help="output folder")
args = parser.parse_args()

# run amplicon analysis
if args.mode == "amplicon":
    abspath_names_dmp = use_amplicon.get_names_dmp(names_dmp=args.names_dmp)
    tax_dict = use_amplicon.create_tax_dict(abspath_names_dmp)
    taxids = use_amplicon.get_taxid(input_file=args.genus_list)
    use_amplicon.get_protein_sequences(tax_list=taxids, output_folder=args.output_folder,
                                       ncbi_tax_dict=tax_dict, reviewed=args.reviewed,
                                       taxonomy_switch=args.taxonomy,
                                       remove_backup=args.remove_backup)

# run assembled metagenome analysis

# run unassembled metagenome analysis

# remove duplicates

# hash headers
