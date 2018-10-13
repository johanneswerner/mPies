# mPies: metaProteomics in environmental sciences

mPies is a tool to create suitable databases for metaproteomic analysis. 

This workflow uses three different databases for a metagenome (i) OTU-table, (ii) assembled-derived, (iii) and unassembled-derived to build a consensus of these databases and increase the mapping sensitivity.

## Installation

The easiest way is to use bioconda and create a new environment. 

```bash
conda create -n mpies python=2.7.15 numpy=1.15.2 diamond=0.9.22 hmmer=3.2.1 \
  krona=2.7 orfm=0.7.1 pplacer=1.1.alpha19 snakemake=5.3.0
source activate mpies
pip install singlem==0.11.0
mkdir bin
wget https://github.com/ctSkennerton/fxtract/releases/download/2.3/fxtract2.3-Linux-64bit-static \
  -O bin/fxtract
chmod +x bin/fxtract
PATH=$PATH:$PWD/bin
```

Otherwise you have to resolve the dependencies manually.

## Usage

The entire workflow is written in Snakemake.

## Data

The data used for making functional tests is from the OSD
