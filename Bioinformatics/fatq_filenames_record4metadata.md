---
title: Getting multiple `fastq` filenames from sub-directories of samples
toc: TRUE
---

This code can be used, for example, when filling in metadata for an NCBI SRA Submission.

Below assumes a directory structure from a given sequencing experiment. We want a spreadsheet listing the filenames of all of the FASTQ files within each sub-directory of the current directory (e.g., Directory `XXX` contains sub-directories `ID1`, ID2`, etc. and each sub-directory is an individual sample with multiple short-read data files), such as the following structure:

```
XXX-
       |-ID1-
                 |-filename1.fq.gz
                 |-filename2.fq.gz
       |-ID2-
                 |-filename1.fq.gz
                 |-filename2.fq.gz
                 |-filename3.fq.gz
                 |-filename4.fq.gz
       |-ID3-
                 |-filename1.fq.gz
                 |-filename2.fq.gz
       .
       .
       .
       |-IDn-
                 |-filename1.fq.gz
                 |-filename2.fq.gz
```

The spreadsheet will have the first column labelled `library_ID` that contains the sub-directory names (prepended with an optional character string, see below). Subsequent columns are labelled `filename`, `filename2`, `filename3`, etc. 

__NOTE:__ if the sub-directories have an uneven number of files within them, the column names, generically `filenameX`, will only extend to the extent of the filenames in the first sub-directory as ordered by R. So in the example directory `XXX` above, imagine then there will only be 2 columns of `filenameX`, but the row for `ID2` filenames will extend into column 5 (1 for `library_ID` + 4 filenames). All columns 4 and higher will not have a header in the first row of the spreadsheet, but this could be accomplished manually with the spreadsheet software fill action.

# R code to create a spreadsheet with filenames

If this is being completed on an HPC (i.e., `Easley`) at Auburn University, then to launch `R` do the following 2 steps:

  - Initiate an interactive job with `salloc -N1 -n1`
  - Load the correct `R` module
    - list just modules matching "R" with `module spider -r ^R`
        - alternatively list _everything_ with `module avail` and find the section for `R`
    - load the latest/desired version of `R` with `module load R/4.4.0`
   
Then in `R`, run (note if launched in a terminal from the desired working directory the first step can be skipped or the directory contents can be checked with `system("ls")`):  



```{r fastq_getnames}
setwd("/path-to-where-output-will-be-written")  #<-- FIXME

# FIXME: specify the directory in which to look among sub-directories
dir_nm <- "/path-to-main-directory-for-sequencing-run" #<-- FIXME

output_fnm <- "output.tsv" #FIXME: new temporary filename to 

overwrite_not_append <- TRUE  # initially true to begin with
                              ## (FALSE will add at bottom of existing file)

# Any unique prefix to add to sub-directory names
subdir_prfx <- "Sample_"  #<-- TODO else leave as ""
################################################################################

# Get a list of the sub-directories
subdir_nms <- dir(dir_nm, full.names = FALSE, recursive = FALSE,
                  ignore.case = FALSE, include.dirs = FALSE)

for(s in subdir_nms){ 
  # get a list of FASTQ files in the sub-directory
  fastq_files <- data.frame(as.list(list.files(path = paste0(dir_nm, "/", s),
    pattern = "fq.gz",   
    full.names = FALSE)))
  names(fastq_files) <- paste0("filename", c("", seq(2, ncol(fastq_files))))

  out_rw <- cbind(library_ID = paste0(subdir_prfx, s), fastq_files)

  write.table(out_rw, file = output_fnm,
    append = !overwrite_not_append,
    quote = FALSE, sep = "\t",
    row.names = FALSE, col.names = overwrite_not_append)
    
  overwrite_not_append <- FALSE
}   



```   
