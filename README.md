# mPies: metaProteomics in environmental sciences

mPies is a tool to create suitable databases for metaproteomic analysis. 

This workflow uses three different databases for a metagenome (i) OTU-table, (ii) assembled-derived, (iii) and unassembled-derived to build a consensus of these databases and increase the mapping sensitivity.

## Installation

The easiest way is to use bioconda and create a new environment. 

```bash
conda create -n mpies python=2.7.15 numpy=1.15.2
source activate mpies
pip install singlem==0.11.0
```

## Usage

The entire workflow is coded for Snakemake.

