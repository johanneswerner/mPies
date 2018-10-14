#!/usr/bin/env python

import argparse
import logging
import logging.config
import os
from pies import parse_singlem, use_amplicon


def configure_logger(name, log_file, level="DEBUG"):
    """
    Creates the logger for the program.

    The function creates the basic configuration for the logging of all events.

    Parameter
    ---------
      name: name of the logger
      log_file: the output path for the log file
      level: the logging level (default: DEBUG)

    Returns
    -------
      the configured logger

    """
    logging.config.dictConfig({
        'version': 1,
        'formatters': {
            'default': {'format': '%(asctime)s - %(levelname)s - %(name)s - %(message)s',
                        'datefmt': '%Y-%m-%d %H:%M:%S'}
        },
        'handlers': {
            'console': {
                'level': level,
                'class': 'logging.StreamHandler',
                'formatter': 'default',
                'stream': 'ext://sys.stdout'
            },
            'file': {
                'level': level,
                'class': 'logging.handlers.RotatingFileHandler',
                'formatter': 'default',
                'filename': log_file,
                'maxBytes': 3145728,
                'backupCount': 3
            }
        },
        'loggers': {
            'pies': {
                'level': level,
                'handlers': ['console', 'file'],
            }
        },
        'disable_existing_loggers': False
    })

    return logging.getLogger(name)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("-v", "--verbose", action="store_true", dest="verbose", required=False, help="verbose output")

    subparsers = parser.add_subparsers(dest="mode",help="select the run mode (parse_singlem, amplicon)")
    subparser_singlem = subparsers.add_parser("parse_singlem", help="build genus list from singlem OTU table")
    subparser_amplicon = subparsers.add_parser("amplicon",
                                               help="use genus list (amplicons) or singlem (metagenome reads)")

    subparser_singlem.add_argument("-o", "--output_folder", action="store", dest="output_folder", required=True,
                                   help="output folder")
    subparser_singlem.add_argument("-t", "--otu_table", action="store", dest="otu_table", required=True,
                                   help="OTU table generated by SingleM")

    subparser_amplicon.add_argument("-o", "--output_folder", action="store", dest="output_folder", required=True,
                                    help="output folder")
    subparser_amplicon.add_argument("-g", "--genus_list", action="store", dest="genus_list", required=True,
                                    help="list of genera used for amplicon analysis")
    subparser_amplicon.add_argument("-n", "--names_dmp", action="store", dest="names_dmp", default=None,required=False,
                                    help="location of names.dmp")
    subparser_amplicon.add_argument("-r", "--reviewed", action="store_true", dest="reviewed", required=False,
                                    help="use unreviewed TrEMBL hits (default) or only reviewed SwissProt")
    subparser_amplicon.add_argument("-t", "--taxonomy", action="store_false", dest="taxonomy", required=False,
                                    help="add taxonomic lineage to fasta header")

    args = parser.parse_args()

    if args.verbose:
        logger = configure_logger(name='pies', log_file="pies.log", level="DEBUG")
    else:
        logger = configure_logger(name='pies', log_file="pies.log", level="ERROR")

    if os.path.exists(args.output_folder):
        msg = "Output folder already exists. Exiting ..."
        logging.error(msg)
        raise ValueError(msg)
    else:
        os.makedirs(args.output_folder)

    logger.info("pies (Proteomics in environmental science) started")
    if args.mode == "parse_singlem":
        logger.info("parsing OTU table")
        df = parse_singlem.read_table(input_file=args.otu_table)
        print(df)
    elif args.mode == "amplicon":
        logger.info("started amplicon analysis")
        abspath_names_dmp = use_amplicon.get_names_dmp(names_dmp=args.names_dmp)
        tax_dict = use_amplicon.create_tax_dict(abspath_names_dmp=abspath_names_dmp)
        taxids = use_amplicon.get_taxid(input_file=args.genus_list)
        use_amplicon.get_protein_sequences(tax_list=taxids, output_folder=args.output_folder,
                                           ncbi_tax_dict=tax_dict, reviewed=args.reviewed,
                                           add_taxonomy=args.taxonomy)


    logger.info("Done and finished!")


if __name__ == "__main__":
    main()
