#!/usr/bin/Rscript
## ========================================================================== ##
## Assign ancestry for admixture output w/ Helix oipeline
## ========================================================================== ##


## Infiles
Qfile = snakemake@input[["Qfile"]]
pops = snakemake@input[["pops"]]

## Outfile
output = snakemake@output[["output"]] # Output

message(
  "\ninput: ", Qfile,pops,
  "\noutput:", outfile , "\n"
)

message ("Loading packages")
library(dplyr)
library(tibble
library(readr)
library(tidyverse)

message("Reading admixture Qfile  \n")
Qfile <- read_table2(Qfile) %>%

message("Reading ancestry population file  \n")
pops <- read_tsv(pops) %>%
