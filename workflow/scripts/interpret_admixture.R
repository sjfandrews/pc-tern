#!/usr/bin/Rscript
## ========================================================================== ##
## Assign ancestry for admixture output
## ========================================================================== ##

## Infiles
Qfile = snakemake@input[["Qfile"]]
famfile = snakemake@input[["fam"]]
popfile = snakemake@input[["pops"]]
pcs = snakemake@input[["pcs"]]
## Outfile
outfile = snakemake@output[[1]] # Output

message(
  "\ninput: ", Qfile, famfile,popfile,pcs,
  "\noutput:" ,outfile, "\n"
)
message ("Loading packages")
library(readr)
library(tidyr)
library(dplyr)

message("Reading admixture output \n")
tbl <- read_table(Qfile,col_names = FALSE)

message("Reading pop file\n")
popfile <- read_table(popfile, col_names = FALSE)
popfile <- unlist(popfile)

message("Reading fam fixed file\n")
famfile <- read_table(famfile, col_names = FALSE) %>%
  mutate(pop = popfile)

message("Reading pcs file\n")
  pcs <- read_tsv(pcs)
  fids <- pcs$fid
  ids <- pcs$iid
  super_pop <- pcs$super_pop

message("Calculate the column mean, and assign the column with the max mean the ID \n")
to_query <- tbl %>%
  mutate(pop = popfile)

message("Get 1000G samples \n")
ind_oneKG <- which(popfile!="-")
oneKG <- to_query[ind_oneKG,]

message("Assign column with max mean to that group \n")

# Get means for each pop, assign column with max mean to that group
labels=rep(0,ncol(tbl))
for (my_pop in unique(oneKG$pop)){
  subset=oneKG[oneKG$pop==my_pop,]
  means=apply(subset[,colnames(tbl)],2,mean)
  print(means)
  ind=which(means==max(means))
  labels[ind]=my_pop
}
pop <- unlist(popfile)
colnames(tbl)=labels
tbl <- tbl %>%
mutate(fid = fids, iid =ids, super_pop = super_pop) %>%
filter(pop == "-")

message("Save file \n")
tbl %>% write_tsv(outfile)
