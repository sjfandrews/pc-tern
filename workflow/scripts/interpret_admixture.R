#!/usr/bin/Rscript
## ========================================================================== ##
## Assign ancestry for admixture output
## ========================================================================== ##

## Infiles
Qproj = snakemake@input[["Qproj"]]
Qsuper = snakemake@input[["Qsuper"]]
famfile.path = snakemake@input[["fam"]]
popfile.path = snakemake@input[["pops"]]
pcs.path = snakemake@input[["pcs"]]

## Outfile
# projected_interpret = snakemake@output[["projected_interpret"]] # Output
# projected_assign = snakemake@output[["projected_assign"]]

# supervised_interpret = snakemake@output[["supervised_interpret"]] # Output
supervised_assign = snakemake@output[["supervised_assign"]]

library(dplyr)
library(readr)
library(tidyr)

# Fam and popfiles 
## ======================================##
message("Reading pop file \n")
popfile <- read_table(popfile.path, col_names = FALSE) %>% 
  rename(super_pop = X1)

message("Reading fam fixed file \n")
famfile <- read_table2(famfile.path, col_names = FALSE) %>%
  rename(fid = X1, iid = X2) %>%
  bind_cols(popfile) %>% 
  select(fid, iid, super_pop)

message("Reading pcs file \n")
pcs <- read_tsv(pcs.path) %>% 
  rename(pca_super_pop = super_pop)

# Interpreting projected admixture output #
## ======================================##
message(" Reading projected admixture output \n")
tbl_proj.raw <- read_table(Qproj,col_names = FALSE)

message("Calculate the column mean, and assign the column with the max mean the ID \n")
tbl_proj <- tbl_proj.raw %>%
  bind_cols(filter(famfile, super_pop == "-") %>% select(-super_pop)) %>% 
  left_join(pcs %>% select(fid, iid, pca_super_pop), by = c('fid', 'iid')) 

message("Assign column with max mean to that group \n")

mean_proj <- tbl_proj %>% 
  group_by(pca_super_pop) %>% 
  summarise(k1 = mean(X1), 
            k2 = mean(X2), 
            k3 = mean(X3), 
            k4 = mean(X4), 
            k5 = mean(X5))

proj_labels <- mean_proj %>% select(starts_with("k")) %>%
  map_chr(., function(x){
    slice(mean_proj, which.max(x)) %>% pull(pca_super_pop)
  }) 
 
out_proj <- tbl_proj %>% 
  magrittr::set_names(c(proj_labels, 'fid', 'iid', 'pca_super_pop'))  %>% 
  relocate(fid, iid) %>%
  mutate(admixture_super_pop = case_when((EUR > 0.85 & EAS < 0.1 & SAS < 0.1 & AFR <0.1 & AMR <0.1) ~ "EUR",
                                         (EAS > 0.51) ~ "EAS",
                                         (SAS > 0.51) ~ "SAS",
                                         (AFR > 0.3 & EAS < 0.1 & SAS <0.1 & AFR > AMR) ~ "AFR",
                                         (AMR > 0.1 & EAS < 0.1 & SAS <0.1 ) ~ "AMR",
                                         TRUE~"Other")) 
  
# out_proj %>% 
#   tabyl(admixture_super_pop, pca_super_pop)

# Get means for each pop, assign column with max mean to that group
# labels=rep(0,ncol(tbl_proj))
# for (my_pop in unique(to_query$pca_super_pop)){
#   subset=to_query[to_query$pca_super_pop==my_pop,]
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
# 

# Interpreting supervised admixture output #
## ======================================##
message("Reading supervised admixture output \n")
tbl_super <- read_table(Qsuper,col_names = FALSE)

message("Calculate the column mean, and assign the column with the max mean the ID \n")
to_query <- tbl_super %>%
  bind_cols(popfile)

message("Assign column with max mean to that group \n")
oneKG = filter(to_query, super_pop != "-")

# Get means for each pop, assign column with max mean to that group
labels=rep(0,ncol(tbl_super))
for (my_pop in unique(oneKG$super_pop)){
  subset=oneKG[oneKG$super_pop==my_pop,]
  means=apply(subset[,colnames(tbl_super)],2,mean)
  print(means)
  ind=which(means==max(means))
  labels[ind]=my_pop
}

supervised_admixture <- tbl_super %>% 
  magrittr::set_colnames(., labels) %>%
  bind_cols(famfile) %>% 
  relocate(fid, iid) %>%
  mutate(admixture_super_pop = case_when((EUR > 0.85 & EAS < 0.1 & SAS < 0.1 & AFR <0.1 & AMR <0.1) ~ "EUR",
        (EAS > 0.51) ~ "EAS",
        (SAS > 0.51) ~ "SAS",
        (AFR > 0.3 & EAS < 0.1 & SAS <0.1 & AFR > AMR) ~ "AFR",
        (AMR > 0.1 & EAS < 0.1 & SAS <0.1 ) ~ "AMR",
        TRUE~"Other"))

out <- pcs %>%
  select(-FID) %>% 
  left_join(supervised_admixture, by = c('fid', 'iid'))
# 
# out %>% 
#   count(super_pop, pca_super_pop)
out %>%
  tabyl(admixture_super_pop, pca_super_pop)

message("Exporting out to ", supervised_assign, "\n")
out %>% write_tsv(supervised_assign)








































