---
title: Checking `md5sums` after transferring sequence data
toc: TRUE
---


Below assumes a directory structure where we are IN a directory from a given sequencing experiment. There is information about the sequence data in the current directory (e.g., md5sums, quality control output, etc.) then a directory (call it `XXX`) with the sequence data in the following structure

```
XXX-
   |
    -soapnuke-
             |
             -clean-
                   |-ID1-
                        |-filename1.fq.gz
                        |-filename2.fq.gz
                   |-ID2-
                        |-filename1.fq.gz
                        |-filename2.fq.gz
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


# Get and store md5sums in a directory

Get all of md5sum values for files within a directory

  - generically this will be
```
cd /path-to-main-directory-for-sequencing-run 
find ./relative-path-to-directory -type f -exec md5sum '{}' \; > md5sum_curntLocatn_$(date "+%Y_%m_%d_%H%M%S").md5
```


# R code to compare two files of md5sums

If this is being completed on an HPC (i.e., `Easley`) at Auburn University, then to launch `R` do the following 2 steps:

  - Initiate an interactive job with `salloc -N1 -n1`
  - Load the correct `R` module
    - list just modules matching "R" with `module spider -r ^R`
        - alternatively list _everything_ with `module avail` and find the section for `R`
    - load the latest/desired version of `R` with `module load R/4.4.0`
   
Then in `R`, run (note if launched in a terminal from the desired working directory the first step can be skipped or the directory contents can be checked with `system("ls")`):  

```{r md5sum_compare}
setwd("/path-to-main-directory-for-sequencing-run") #<-- FIXME

exstng_fnm <- "md5sum_check.txt"   #FIXME: desired "gold standard" md5sums file
new_md5_fnm <- "md5sum_location_date.md5"  #FIXME: new md5sums file to check post-transfer

exstng <- read.table(exstng_fnm, header = FALSE)
new_md5 <- read.table(new_md5_fnm, header = FALSE)
# get a list of FASTQ files in the directory
fastq_files <- data.frame(path = as.character(list.files(pattern = "fq.gz",
  recursive = TRUE)))

# split off paths to leave just the last two parts (directory and filename)
exstng[, c("IDfldr", "fnm")] <- t(unlist(sapply(strsplit(exstng[, 2], split = "/"),
	FUN = tail, 2)))
new_md5[, c("IDfldr", "fnm")] <- t(unlist(sapply(strsplit(new_md5[, 2], split = "/"),
	FUN = tail, 2)))
fastq_files[, c("IDfldr", "fnm")] <- t(unlist(sapply(strsplit(fastq_files[, 1], split = "/"),
	FUN = tail, 2)))
 


# Go through each file:
## find it in the 2 md5sum files/lists
## check file name associated with same sample ID and md5sum

chkOut <- matrix(NA, nrow = nrow(fastq_files), ncol = 5,  #<-- to hold output
  dimnames = list(NULL, c("ID", "fileNm", "existing", "new", "chckPass")))
cnt <- 1  
for(fq in fastq_files$fnm){
  exstInd <- which(exstng$fnm == fq)
  newInd <- which(new_md5$fnm == fq)
   
  # check that filename is unique
  if(length(exstInd) > 1 | length(newInd) > 1){
    stop("non-unique filenames across multiple sub-directories")
  }
  
  # check the ID/directory name is the same
  if(exstng$IDfldr[exstInd] == new_md5$IDfldr[newInd]){
    chkOut[cnt, ] <- c(exstng$IDfldr[exstInd], fq,
      exstng$V1[exstInd], new_md5$V1[newInd],
      identical(exstng$V1[exstInd], new_md5$V1[newInd]))
  } else{
      warning("different ID folder names for file:", fq)
      chkOut[cnt, c("fileNm", "chckPass")] <- c(fq, FALSE)
    }

  cnt <- cnt + 1
}    

all(chkOut[, "chckPass"])  #<-- should be TRUE

write.table(chkOut, paste0("md5sum_CHECK_", format(Sys.time(), "%Y_%m_%d"), ".txt"),
  append = FALSE, quote = FALSE, row.names = FALSE, col.names = TRUE)
  
  
  
```

# change permissions on sequence data files to READ ONLY

If transferred the sequence data then make sure these files can't be changed by ensuring they are read only. Below recursively finds files and changes these to read only.

```
sudo find ./folder-in-directory -type f -exec chmod 644 {} +
```

--------------------------------------------------------------------------------


# Check an md5sum against value in file

Either the original or a subsequent set of md5sum can be checked with a newly generated set __as long as the paths are the same!__

  - generically use
```
md5sum -c md5sum_curnt.md5
```


