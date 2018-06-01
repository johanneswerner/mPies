#!/usr/bin/env python

from obtain_sequences import use_amplicon

res = use_amplicon.get_taxid(input_file="data/genus_list.txt")
print(res)
