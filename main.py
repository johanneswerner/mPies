#!/usr/bin/env python

import argparse
import logging
import logging.config
import os
import sys
from pies import use_amplicon


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
            'default': {'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
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
                'maxBytes': 1024,
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
    # TODO: where to put log file? and how to overwrite an old log file? filemode in the function
    # above did not work out.
    logger = configure_logger(name='pies', log_file="pies.log", level="DEBUG")

    parser = argparse.ArgumentParser()
    parser.add_argument("-m", "--mode", choices=["amplicon", "assembled", "unassembled"],
                        dest="mode", required=True,
                        help="mode for analysis (amplicon, assembled, unassembled)")
    args = parser.parse_known_args()[0]
    if args.mode == "amplicon":
        parser.add_argument("-g", "--genus_list", action="store", dest="genus_list", required=True,
                            help="list of genera used for amplicon analysis")
        parser.add_argument("-n", "--names_dmp", action="store", dest="names_dmp", default=None,
                            required=False, help="location of names.dmp")
        parser.add_argument("-r", "--reviewed", action="store_true", dest="reviewed",
                            required=False,
                            help="use unreviewed TrEMBL hits (default) or only reviewed SwissProt")
        parser.add_argument("-t", "--taxonomy", action="store_false", dest="taxonomy",
                            required=False, help="add taxonomic lineage to fasta header")
    elif args.mode == "assembled":
        parser.add_argument("-p", "--assembled", action="store", dest="metagenome_assembled",
                            required=True, help="protein file of assembled metagenome")
    parser.add_argument("-o", "--output_folder", action="store", dest="output_folder",
                        required=True, help="output folder")
    parser.add_argument("-b", "--remove_backup", action="store_false", dest="remove_backup",
                        required=False, help="remove backup files")
    args = parser.parse_args()

    if os.path.exists(args.output_folder):
        logging.error("Output folder already exists. Exit code: 1. Exiting ...")
        # TODO: Which error can I raise instead of sys.exit(1)? I think it is reasonable to run
        # this program only on not existing output directories in order to avoid overriding.
        sys.exit(1)
    else:
        os.makedirs(args.output_folder)

    logger.info("pies (Proteomics in environmental science) started")
    logger.info("started amplicon analysis")
    if args.mode == "amplicon":
        abspath_names_dmp = use_amplicon.get_names_dmp(names_dmp=args.names_dmp)
        tax_dict = use_amplicon.create_tax_dict(abspath_names_dmp=abspath_names_dmp)
        taxids = use_amplicon.get_taxid(input_file=args.genus_list)
        use_amplicon.get_protein_sequences(tax_list=taxids, output_folder=args.output_folder,
                                           ncbi_tax_dict=tax_dict, reviewed=args.reviewed,
                                           add_taxonomy=args.taxonomy,
                                           remove_backup=args.remove_backup)
        fasta_file = use_amplicon.combine_fasta_files(fasta_folder=args.output_folder,
                                                      remove_single_files=True)

    logging.debug(fasta_file)

    # hash headers

    logger.info("Done and finished!")


if __name__ == "__main__":
    main()
