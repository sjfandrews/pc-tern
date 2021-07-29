#!/usr/bin/Rscript
## ========================================================================== ##
## Assign ancestry for admixture output w/ Helix oipeline
## ========================================================================== ##


## Infiles
infile = snakemake@input[[1]] # infile

## Outfile
outfile = snakemake@output[[1]] # Output

message(
  "\ninput: ", infile,
  "\noutput:", outfile , "\n"
)

message ("Loading packages")
library(dplyr)
library(readr)
library(tidyverse)

message("Reading admixture Qfile \n")
Qraw <- read_table2(infile)
Qfile <- Qraw %>%
  select(c(fid,iid,super_pop, pop, K1, K2, K3, K4, K5)) %>%
    filter(pop == 'sample') %>%
      rename(EUR = K4, AFR = K2, SAS = K3, AMR = K1, EAS= K5)%>%
        mutate(super_pop2 = case_when((EUR > 0.85 & EAS < 0.1 & SAS < 0.1 & AFR <0.1 & AMR <0.1) ~ "EUR",
                                (EAS > 0.6) ~ "EAS",
                                (SAS > 0.6) ~ "SAS",
                                (AFR > 0.3 & EAS < 0.1 & SAS <0.1 & AFR > AMR) ~ "AFR",
                                (AMR > 0.1 & EAS < 0.1 & SAS <0.1 ) ~ "AMR",
                                TRUE~"Other"))

message("Exporting Qfile to ", outfile, "\n")
Qfile %>% write_tsv(outfile)
