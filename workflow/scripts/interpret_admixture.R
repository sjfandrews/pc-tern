#!/usr/bin/Rscript
## ========================================================================== ##
## Assign ancestry for admixture output
## ========================================================================== ##

## Infiles
Qraw = snakemake@input[["Qraw"]]
famfile.path = snakemake@input[["fam"]]
popfile.path = snakemake@input[["pops"]]
pcs.path = snakemake@input[["pcs"]]

## Outfile
supervised_assign = snakemake@output[["supervised_assign"]]

library(tidyverse)
library(plyr)
library(readr)
library(tidyr)
library(purrr)

# Fam and popfiles
## ======================================##
message("Reading pop file \n")
popfile <- read_table2(popfile.path, col_names = FALSE) %>%
  rename(super_pop = X1)

message("Reading fam fixed file \n")
famfile <- read_table2(famfile.path, col_names = FALSE) %>%
  rename(fid = X1, iid = X2) %>%
  bind_cols(popfile) %>%
  select(fid, iid, super_pop)

message("Reading pcs file \n")
pcs <- read_tsv(pcs.path) %>%
  rename(pca_super_pop = super_pop)

# Interpreting supervised admixture output #
## ======================================##
message("Reading supervised admixture output \n")
tbl_super.raw <- read_table2(Qraw,col_names = FALSE)

tbl_super <- tbl_super.raw %>% bind_cols(famfile) %>%
  left_join(pcs %>% select(fid, iid, pca_super_pop), by = c('fid', 'iid'))  %>%
  filter(super_pop == "-") %>% select(-super_pop)

mean_super <- tbl_super %>%
  group_by(pca_super_pop) %>%
  summarise(k1 = mean(X1),
            k2 = mean(X2),
            k3 = mean(X3),
            k4 = mean(X4),
            k5 = mean(X5))
super_labels <- mean_super %>% select(starts_with("k")) %>%
  map_chr(., function(x){
    slice(mean_super, which.max(x)) %>% pull(pca_super_pop)
  })

out_super <- tbl_super %>%
  magrittr::set_names(c(super_labels, 'fid', 'iid', 'pca_super_pop'))  %>%
  relocate(fid, iid) %>%
  mutate(admixture_super_pop = case_when((EUR > 0.85 & EAS < 0.1 & SAS < 0.1 & AFR <0.1 & AMR <0.1) ~ "EUR",
                                         (EAS > 0.51) ~ "EAS",
                                         (SAS > 0.51) ~ "SAS",
                                         (AFR > 0.3 & EAS < 0.1 & SAS <0.1 & AFR > AMR) ~ "AFR",
                                         (AMR > 0.1 & EAS < 0.1 & SAS <0.1 ) ~ "AMR",
                                         TRUE~"Other"))

message("Exporting out to ", supervised_assign, "\n")
out_super %>% write_tsv(supervised_assign)
