---
title: Downloading and checking a reference genome from NCBI
toc: true
---

Using the command line, here are the steps to download a reference genome and then check the md5sums. This will use the command line tool `datasets` from NCBI

### Install tools

```
conda create -n ncbi_datasets
conda activate ncbi_datasets
conda install -c conda-forge ncbi-datsets-cli
```

### Download datasets

  - First, change the directory to wherever the data should be stored
```
cd <<insert actual path here>>
```

  - Download: the example code below is to download the Vertebrate Genomes Project reference genome assembly for _Malaclemys terrapin pileata_.
    - The actual code can be found on the NCBI Genome page for whatever genome is desired (see the `datasets` tab and command line icon)

```
datasets download genome accession GCF_027887155.1 --include gff3,rna,cds,protein,genome,seq-report
```

  - unzip then see the directory and file structure
```
unzip -q ncbi_dataset.zip -d ./
tree
```

### Check md5sums

```
md5sum -c md5sum.txt > md5sumCheck_curntLocatn_$(date "+%Y_%m_%d_%H%M%S").txt
```
And check the file output: `nano md5sumCheck_curnt*`


