#!/usr/bin/env python

import argparse
import hashlib
import logging
import logging.config
import os
import sys
from mptk import general_functions, hash_headers, parse_singlem, use_amplicon, parse_taxonomy, parse_functions_cog, \
  parse_functions_uniprot


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
            'mptk': {
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

    subparsers = parser.add_subparsers(dest="mode",help="select the run mode")
    subparser_prepareuniprot = subparsers.add_parser("prepare_uniprot_files",
                                                     help="build a accession-GO-table based on UniProt dat file")
    subparser_singlem = subparsers.add_parser("parse_singlem", help="build genus list from singlem OTU table")
    subparser_amplicon = subparsers.add_parser("amplicon",
                                               help="use genus list (amplicons) or singlem (metagenome reads)")
    subparser_hashing = subparsers.add_parser("hashing", help="hash fasta headers")
    subparser_taxonomy = subparsers.add_parser("taxonomy", help="parse taxonomy results")
    subparser_functions_cog = subparsers.add_parser("functions_cog", help="parse diamond results against COG database")
    subparser_functions_uniprot = subparsers.add_parser("functions_uniprot",
                                                        help="parse diamond results against Uniprot database")

    subparser_prepareuniprot.add_argument("-u", "--uniprot_file", action="store", dest="uniprot_file", default=None,
                                          required=True, help="zipped uniprot dat file")
    subparser_prepareuniprot.add_argument("-t", "--uniprot_table", action="store", dest="uniprot_table", default=None,
                                          required=True, help="uniprot output table (accession - GO annotation)")

    subparser_singlem.add_argument("-n", "--names_dmp", action="store", dest="names_dmp", default=None,required=False,
                                   help="location of names.dmp")
    subparser_singlem.add_argument("-t", "--otu_table", action="store", dest="otu_table", required=True,
                                   help="OTU table generated by SingleM")
    subparser_singlem.add_argument("-l", "--level", action="store", dest="level", required=False, default="genus",
                                   help="taxonomic rank of OTU list (default: genus)")
    subparser_singlem.add_argument("-u", "--taxon_file", action="store", dest="taxon_file", required=False,
                                   default="taxon_list.txt", help="file with list of valid tax ids")
    subparser_singlem.add_argument("-c", "--cutoff", action="store", dest="cutoff", required=False, default=5,
                                   help="cutoff for reporting a taxonomic rank")

    subparser_amplicon.add_argument("-g", "--genus_list", action="store", dest="genus_list", required=True,
                                    help="list of genera used for amplicon analysis")
    subparser_amplicon.add_argument("-p", "--proteome_file", action="store", dest="proteome_file", required=True,
                                    help="proteome file")
    subparser_amplicon.add_argument("-n", "--names_dmp", action="store", dest="names_dmp", default=None,required=False,
                                    help="location of names.dmp")
    subparser_amplicon.add_argument("-r", "--reviewed", action="store_true", dest="reviewed", required=False,
                                    help="use unreviewed TrEMBL hits (default) or only reviewed SwissProt")
    subparser_amplicon.add_argument("-t", "--taxonomy", action="store_true", dest="taxonomy", required=False,
                                    help="add taxonomic lineage to fasta header")

    subparser_hashing.add_argument("-p", "--proteome_file", action="store", dest="proteome_file", required=True,
                                   help="proteome input file")
    subparser_hashing.add_argument("-s", "--hashed_proteome_file", action="store", dest="hashed_file", required=True,
                                   help="proteome output file with hashed headers")
    subparser_hashing.add_argument("-t", "--tsv_file", action="store", dest="tsv_file", required=True,
                                   help="proteome output file with hashed headers")
    subparser_hashing.add_argument("-x", "--hash_type", choices=["md5", "sha1"], dest="hash_type", default="md5",
                                   help="hash algorithm to use")

    subparser_taxonomy.add_argument("-m", "--megan_table", action="store", dest="megan_results", required=True,
                                   help="megan results file")
    subparser_taxonomy.add_argument("-t", "--output_table", action="store", dest="taxonomy_table", required=True,
                                   help="output table with parsed taxonomy")

    subparser_functions_cog.add_argument("-d", "--diamond_file", action="store", dest="diamond_file", required=True,
                                         help="diamond results file")
    subparser_functions_cog.add_argument("-t", "--cog_table", action="store", dest="cog_table", required=True,
                                         help="COG csv table")
    subparser_functions_cog.add_argument("-n", "--cog_names", action="store", dest="cog_names", required=True,
                                         help="COG names table")
    subparser_functions_cog.add_argument("-f", "--cog_functions", action="store", dest="cog_functions", required=True,
                                         help="COG functions table")
    subparser_functions_cog.add_argument("-e", "--export_table", action="store", dest="export_table", required=True,
                                         help="path for output table")

    subparser_functions_uniprot.add_argument("-d", "--diamond_file", action="store", dest="diamond_file",
                                             required=True, help="diamond results file")
    subparser_functions_uniprot.add_argument("-t", "--uniprot_table", action="store", dest="uniprot_table",
                                             required=True, help="compressed UniProt table")
    subparser_functions_uniprot.add_argument("-e", "--export_table", action="store", dest="export_table",
                                             required=True, help="path for output table")

    args = parser.parse_args()

    lvl = "INFO"
    if args.verbose:
        lvl = "DEBUG"
    logger = configure_logger(name='mpies', log_file="mpies.log", level=lvl)

    logger.info("(metaproteomics toolkit) started")

    if len(sys.argv) == 1:
        msg = "No parameter passed. Exiting..."
        logging.error(msg)
        parser.print_help(sys.stderr)
        raise ValueError(msg)

    if args.mode == "prepare_uniprot_files":
        logger.info("parsing UniProt file")
        general_functions.parse_uniprot_file(uniprot_file=args.uniprot_file, uniprot_table=args.uniprot_table)

    elif args.mode == "parse_singlem":
        logger.info("parsing OTU table")
        abspath_names_dmp = general_functions.get_names_dmp(names_dmp=args.names_dmp)
        tax_dict = general_functions.create_tax_dict(abspath_names_dmp=abspath_names_dmp)
        data_frame = parse_singlem.read_table(input_file=args.otu_table)
        tax_list = parse_singlem.calculate_abundant_otus(df=data_frame, level=args.level, cutoff=args.cutoff)
        validated_tax_list = parse_singlem.validate_taxon_names(taxon_names=tax_list, ncbi_tax_dict=tax_dict)
        parse_singlem.write_taxon_list(validated_taxon_names=validated_tax_list,
                                       taxon_file=args.taxon_file)

    elif args.mode == "amplicon":
        logger.info("started amplicon analysis")
        abspath_names_dmp = general_functions.get_names_dmp(names_dmp=args.names_dmp)
        tax_dict = general_functions.create_tax_dict(abspath_names_dmp=abspath_names_dmp)
        taxids = use_amplicon.get_taxid(input_file=args.genus_list)
        use_amplicon.get_protein_sequences(tax_list=taxids, output_file=args.proteome_file, ncbi_tax_dict=tax_dict,
                                           reviewed=args.reviewed, add_taxonomy=args.taxonomy)

    elif args.mode == "hashing":
        logger.info("hashing protein headers")
        hash_headers.write_hashed_protein_header_fasta_file(input_file=args.proteome_file, output_file=args.hashed_file,
                                                            tsv_file=args.tsv_file, hash_type=args.hash_type)

    elif args.mode == "taxonomy":
        logger.info("parsing megan taxonomy file")
        parse_taxonomy.parse_table(input_file=args.megan_results, output_file=args.taxonomy_table)

    elif args.mode == "functions_cog":
        logger.info("running COG analysis")
        cog_df = general_functions.parse_diamond_output(diamond_file=args.diamond_file)
        cog_df_merged = parse_functions_cog.join_tables(df=cog_df, cog_table=args.cog_table, cog_names=args.cog_names)
        cog_df_grouped = parse_functions_cog.group_table(df=cog_df_merged, cog_functions=args.cog_functions)
        parse_functions_cog.export_table(df=cog_df_grouped, output_file=args.export_table)

    elif args.mode == "functions_uniprot":
        logger.info("running Uniprot analysis")
        uniprot_df = general_functions.parse_diamond_output(diamond_file=args.diamond_file)
        uniprot_df_merged = parse_functions_uniprot.join_tables(uniprot_df, uniprot_table=args.uniprot_table)
        uniprot_df_grouped = parse_functions_uniprot.group_table(uniprot_df_merged)
        parse_functions_uniprot.export_table(df=uniprot_df_grouped, output_file=args.export_table)

    logger.info("Done and finished!")


if __name__ == "__main__":
    main()
