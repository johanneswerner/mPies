#!/usr/bin/env python

import argparse
from obtain_sequences import use_amplicon

parser = argparse.ArgumentParser()
parser.add_argument("-g", "--genus_list", action="store",
                    dest="genus_list", required=True)
arguments = parser.parse_args()

res = use_amplicon.get_taxid(input_file=arguments.genus_list)
print(res)
