# mPies: metaProteomics in environmental sciences

mPies is a tool to create suitable databases for metaproteomic analysis. 

This workflow uses three different databases for a metagenome (i) OTU-table, (ii) assembled-derived, (iii) and unassembled-derived to build a consensus of these databases and increase the mapping sensitivity.

## Installation

The easiest way is to use bioconda and create a new environment. 

```bash
conda create -n mpies --file conda_env.conf
source activate mpies
```

SingleM has been packaged by AppImage (due to the Python 2 dependency). Download [AppImage](https://github.com/probonopd/AppImageKit/releases) and build the image with

```bash
cd appimages
./appimage_singlem.sh
appimagetool-x86_64.AppImage singlem-x86_64.AppImage/ singlem.AppImage
```

## Usage

The entire workflow is written in Snakemake.

```bash
snakemake -j N # set N to desired number of cores, omit N to use available number of cores
```

TODO: snakemake config

## Data

The data used for making functional tests is from the OSD (Ocean Sampling Day)
