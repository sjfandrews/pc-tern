if(any(grepl("conda", .libPaths(), fixed = TRUE))){
  message("Setting libPaths")
.libPaths(c(.libPaths(),snakemake@params[["Rlib"]]))
}

library(tidyverse)
`%nin%` = negate(`%in%`)
library(bigutilsr)

# assign sample to cluster
## https://www.biorxiv.org/content/10.1101/2020.10.06.328203v2.full
## http://adomingues.github.io/2015/09/24/finding-closest-element-to-a-number-in-a-list/
find_cluster <- function(df){
  iid <- select(df, starts_with("PC"))
  mat <- bind_rows(clusters, iid) %>% dist(.)
  # mat
  clus <- as.matrix(mat)[6,1:5] %>% which.min()
  df %>% mutate(super_pop = pops[clus])
}

# ref_pops.path <- "GWASampleFiltering/reference/1kG_pops.txt"
# ref_superpops.path <- "GWASampleFiltering/reference/1kG_superpops.txt"
# vec.path <- "GWASampleFiltering/sandbox/output/gsa1234567_1kG_merged.eigenvec"

ref_pops.path <- snakemake@input[['ref_pops']]
ref_superpops.path <- snakemake@input[['ref_superpops']]
vec.path <- snakemake@input[['eigenvec']]
pcs.out.path <- snakemake@output[['pcs_pops']]

ref <- left_join(
  read_table2(ref_superpops.path) %>% rename(super_pop = Population),
  read_table2(ref_pops.path) %>% rename(pop = Population)
)

# Formating data
vec <- read_table2(vec.path, col_names = F) %>%
  rename(fid = X1, iid = X2, PC1 = X3, PC2 = X4, PC3 = X5, PC4 = X6, PC5 = X7, PC6 = X8, PC7 = X9, PC8 = X10, PC9 = X11, PC10 = X12) %>%
  left_join(ref, by = c('iid' = 'IID')) %>%
  mutate(super_pop = ifelse(is.na(super_pop), "sample", super_pop),
         pop = ifelse(is.na(pop), "sample", pop))

# Pull out 1000 genomes samples
kg <- filter(vec, iid %in% ref$IID)

# population names
pops <- kg %>% filter(pop != "sample") %>% arrange(super_pop) %>% distinct(super_pop)  %>% pull()

# find geometric median of each PC for each cluster
clusters <- kg %>%
  group_split(super_pop) %>%
  magrittr::set_names(pops) %>%
  map(., select, starts_with("PC")) %>%
  map(., bigutilsr::geometric_median) %>%
  bind_rows(.id = "iid")

# extract sample information and assign to cluster
samples <- vec %>%
  filter(., iid %nin% ref$IID) %>%
  group_split(iid) %>%
  map_df(., find_cluster)

pcs <- bind_rows(kg, samples)

write_tsv(pcs, pcs.out.path)
