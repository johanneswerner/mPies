# mPies: metaProteomics in environmental sciences [![DOI](https://zenodo.org/badge/161555171.svg)](https://zenodo.org/badge/latestdoi/161555171)


mPies is a workflow to create annotated databases for metaproteomic analysis.

This workflow uses three different databases for a metagenome (i) OTU-table, (ii) assembled-derived, (iii) and
unassembled-derived to build a consensus of these databases and increase the mapping sensitivity.

If you use mPies for your research, please cite our publication:

Werner, J., Géron, A., Kerssemakers, J. et al. mPies: a novel metaproteomics tool for the creation of relevant protein databases and automatized protein annotation. Biol Direct 14, 21 (2019) doi: [10.1186/s13062-019-0253-x](https://doi.org/10.1186/s13062-019-0253-x)

## Installation

The easiest way is to use bioconda and create a new environment. For a faster installation, consider installing micromamba and replace `conda` with `mamba` in all runs.

```bash
conda env create -n mpies --file conda_env.yml
conda activate mpies
```

## Usage

mPies consists of two parts: database creation and annotation. Both parts are written in Snakemake.

```bash
# database creation
snakemake --snakefile database_creation.smk --configfile database_creation.json --cores 28

# annotation
snakemake --snakefile annotation.smk --configfile annotation.json --cores 28
```

### Detailed explanation of the mpies workflow

#### Database creation

##### Preprocessing

The preprocessing trims the raw reads and combines the single reads into one file.

##### Amplicon-derived proteome file

In order to create the amplicon-derived proteome file, there are two possibilities. If amplicon data is available,
then a text file with the taxon names (one per line) is used for downloading the proteomes from UniProt. If no
amplicon data is available, you can set the option `config["otu_table"]["run_singlem"]` to `true` and a taxon file is
created with SingleM (this tool detects OTU abundances based on metagenome shotgun sequencing data).

###### Important Note: SingleM

SingleM currently cannot be used as it uses orator as a dependency that still relies on Python 3.5. As long as this is not fixed (and since the last code edit in the orator Github repository is 3 years ago (state of this comment: September, 2022), it is not likely that this will happen anytime soon), SingleM cannot be used and is deactivated until further notice.

##### Functional-derived subset

It is also possible to create a subset derived from UniProt based not only on taxonomy but to also restrict the
gene and functional names instead of downloading the entire proteomes for the taxa of interest. To do so, a TOML file
should be created (see example below)

```toml
Taxonomy = [
    "Bacteria"
]
Gene_names = [
     "dnaK",
     "soxA"
]
Protein_names = [
    "Heat shock protein 70", # something commented
]
```

and the path needs to be set in the snakemake configuration (`config["functional_subset"]["toml_file"]`).

##### Assembled-derived proteome file

If only raw data is available, it is possible to run an assembly with MEGAHIT or metaSPAdes (set
`config["assembled"]["run_assembly"]` to `true` and config["assembled"]["assembler"] to `megahit` or `metaspades`).
Please keep in mind that assemblies can take a lot of time depending on the size of the dataset. If you already have an
assembly, set `config["assembled"]["run_assembly"]` to `false` and create a symlink of your assembly into
`{sample}/assembly/contigs.fa`. If you have no gene calling yet, remember to set
`config["assembled"]["run_genecalling"]` to `true`.

If you have both assembly and gene calling already performed, set `config["assembled"]["run_assembly"]` and
`config["assembled"]["run_genecalling"]` to `false` and create a symlink of the assembled proteome into
`{sample}/proteome/assembled.faa`.

##### Unassembled-derived proteome file

To create the unassembled-derived proteome file, FragGeneScan is used (and prior to that a fastq-to-fasta
conversion).

##### Postprocessing

During the postprocessing, the all three proteomes are combined into one file. Short sequences (< 30 amino acids)
are deleted and all duplicates are removed. Afterwards, the fasta headers are hashed to shorten the headers (and save
some disk space).

#### Annotation

##### Preprocessing

For now, the identified proteins are inferred from ProteinPilot. The resulting Excel file is used to create a protein
fasta file that only contains the identified proteins. Taxonomic and functional analysis are conducted for the
identified proteins.

##### Taxonomical annotation

The taxonomic analysis is performed with `blast2lca` from the MEGAN package. Per default, the taxonomic analysis is set
to false in the snake config file.

Some prerequisites are necessary to run the taxonomic analysis for the created proteome fasta file.

1. Download and unzip the file `prot_acc2tax-June2018X1.abin.zip` for MEGAN.

2. Download the `nr.gz` fasta file from NCBI (size: 40 GB).

```bash
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz.md5
md5sum -c nr.gz.md5
```

If the checksum does not match, the download was probably not complete. `wget -c` continues a partial download.

3. Create a diamond database of the file `nr.gz`.

```bash
diamond makedb --threads <number_of_threads> --in nr.gz --db nr.dmnd
```

4. Now you can set `config["taxonomy"]["run_taxonomy"]` to `true` and run `snakemake`. Remember to set the paths for the
diamond database, the binary of `blast2lca` and the path to the file `prot_acc2tax-Jun2018X1.abin`. Please note that
`diamond blastp` takes a very long time to execute.

##### Functional annotation

Different databases can be used to add functional annotation. Per default, the funtional annotation is set to `false`.

###### COG

In order to use the COG database, some prerequisites have to be fulfilled before.

1. Download the necessary files from the FTP server.

```bash
wget ftp://ftp.ncbi.nih.gov/pub/COG/COG2014/data/prot2003-2014.fa.gz
wget ftp://ftp.ncbi.nih.gov/pub/COG/COG2014/data/cog2003-2014.csv
wget ftp://ftp.ncbi.nih.gov/pub/COG/COG2014/data/cognames2003-2014.tab
wget ftp://ftp.ncbi.nih.gov/pub/COG/COG2014/data/fun2003-2014.tab
```

2. Create a diamond database of the file `prot2003-2014.fa.gz`.

```bash
diamond makedb --threads <number_of_threads> --in prot2003-2014.fa.gz --db cog.dmnd
```

3. Now you can set `config["functions"]["run_cog"]["run_functions_cog"]` to `true` and run `snakemake`. Remember to set
the paths for the diamond database and the files `cog_table`, `cog_names`, and `cog_functions`.

###### UniProt/GO

In order to use the GO ontologies included in the UniProt database (SwissProt or TrEMBL), some prerequisites have to
be fulfilled before.

1. Download the necessary files from the FTP server.

```bash
# SwissProt
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.dat.gz

# TrEMBL
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.fasta.gz
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.dat.gz
```

Please note that TrEMBL is quite large (29 GB for `uniprot_trembl.fasta.gz` and 78 GB for `uniprot_trembl.dat.gz`).

2. Create a diamond database of the fasta file (here the SwissProt database will be used)

```bash
diamond makedb --threads <number_of_threads> --in uniprot_sprot.fasta.gz --db sprot.dmnd
```

3. Use the dat file downloaded from UniProt to create a table with protein accessions and GO annotations

```bash
./main.py prepare_uniprot_files -u .../uniprot_sprot.dat.gz -t .../sprot.table.gz
```

Please note that input and output files must be/are compressed with gzip.

4. Now you can set `config["functions"]["run_uniprot"]["run_functions_uniprot"]` to `true` and run `snakemake`.

## Test data

The test data set is a subset from the Ocean Sampling Day (first 18,000 lines for each read file), Accession number
ERR770958 obtained from https://www.ebi.ac.uk/ena/data/view/ERR770958). The data is deposited in the test_data
directory of this repository.
