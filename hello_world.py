#!/usr/bin/env python

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--sunshine", action="store_true",
                    dest = "sunshine", default=False)
arguments = parser.parse_args()

if arguments.sunshine:
    print("hello sunshine")
