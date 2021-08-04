#!/usr/bin/Rscript
## ========================================================================== ##
## Assign ancestry for admixture output
## ========================================================================== ##

## Infiles
Qproj = snakemake@input[["Qproj"]]
Qsuper = snakemake@input[["Qsuper"]]
famfile = snakemake@input[["fam"]]
popfile = snakemake@input[["pops"]]
pcs = snakemake@input[["pcs"]]

## Outfile
# projected_interpret = snakemake@output[["projected_interpret"]] # Output
# projected_assign = snakemake@output[["projected_assign"]]

supervised_interpret= snakemake@output[["supervised_interpret"]] # Output
supervised_assign = snakemake@output[["supervised_assign"]]

library(dplyr)
library(readr)
library(tidyr)

# Interpreting projected admixture output #
## ======================================##

message(" Reading projected admixture output \n")
tbl_proj <- read_table(Qproj,col_names = FALSE)

message("Reading pcs file \n")
  pcs <- read_tsv(pcs)%>%
  filter(pop == "sample")
  # fids <- pcs$fid
  # ids <- pcs$iid
  # super_pop <- pcs$super_pop
#
# message("Calculate the column mean, and assign the column with the max mean the ID \n")
# to_query <- tbl_proj %>%
#   mutate(pop = pcs$super_pop)
#
# message("Assign column with max mean to that group \n")
#
# # Get means for each pop, assign column with max mean to that group
# labels=rep(0,ncol(tbl_proj))
# for (my_pop in unique(to_query$pop)){
#   subset=to_query[to_query$pop==my_pop,]
#   means=apply(subset[,colnames(tbl_proj)],2,mean)
#   print(means)
#   ind=which(means==max(means))
#   labels[ind]=my_pop
# }
# colnames(tbl_proj)=labels
# tbl_proj <- tbl_proj %>%
# mutate(fid = pcs$fid, iid =pcs$iid, super_pop = pcs$super_pop)
#
# message("Exporting tbl to", interpret, "\n")
# tbl_proj %>% write_tsv(projected_interpret)
#
# # Assign ancestry for admixture output
# tbl_proj2 <- tbl %>%
#   mutate(super_pop2 = case_when((EUR > 0.85 & EAS < 0.1 & SAS < 0.1 & AFR <0.1 & AMR <0.1) ~ "EUR",
#         (EAS > 0.51) ~ "EAS",
#         (SAS > 0.51) ~ "SAS",
#         (AFR > 0.3 & EAS < 0.1 & SAS <0.1 & AFR > AMR) ~ "AFR",
#         (AMR > 0.1 & EAS < 0.1 & SAS <0.1 ) ~ "AMR",
#         TRUE~"Other"))
#
# message("Exporting tbl2 to ",projected_assign, "\n")
# tbl_proj2 %>% write_tsv(projected_assign)


# Interpreting supervised admixture output #
## ======================================##
message("Reading supervised admixture output \n")
tbl_super <- read_table(Qsuper,col_names = FALSE)

message("Reading pop file \n")
popfile <- read_table(popfile, col_names = FALSE)
popfile <- unlist(popfile)

message("Reading fam fixed file \n")
famfile <- read_table(famfile, col_names = FALSE) %>%
 mutate(pop = popfile)

message("Calculate the column mean, and assign the column with the max mean the ID \n")
to_query <- tbl_super %>%
  mutate(pop = popfile)

message("Assign column with max mean to that group \n")
ind_oneKG=which(popfile!="-")
oneKG=to_query[ind_oneKG,]

# Get means for each pop, assign column with max mean to that group
labels=rep(0,ncol(tbl_super))
for (my_pop in unique(oneKG$pop)){
  subset=oneKG[oneKG$pop==my_pop,]
  means=apply(subset[,colnames(tbl_super)],2,mean)
  print(means)
  ind=which(means==max(means))
  labels[ind]=my_pop
}
pop <- unlist(popfile)
colnames(tbl_super)=labels
tbl_super <- tbl_super %>%
mutate(fid = fids, iid =ids, super_pop = super_pop) %>%
filter(pop == "-")

message("Exporting tbl to", unsupervised_interpret, "\n")
tbl_super %>% write_tsv(unsupervised_interpret)

# Assign ancestry for admixture output
tbl_super2 <- tbl_super %>%
  mutate(super_pop2 = case_when((EUR > 0.85 & EAS < 0.1 & SAS < 0.1 & AFR <0.1 & AMR <0.1) ~ "EUR",
        (EAS > 0.51) ~ "EAS",
        (SAS > 0.51) ~ "SAS",
        (AFR > 0.3 & EAS < 0.1 & SAS <0.1 & AFR > AMR) ~ "AFR",
        (AMR > 0.1 & EAS < 0.1 & SAS <0.1 ) ~ "AMR",
        TRUE~"Other"))

message("Exporting tbl2 to ",unsupervised_assign, "\n")
tbl_super2 %>% write_tsv(unsupervised_assign)
