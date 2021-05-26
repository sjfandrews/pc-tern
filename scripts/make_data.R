library(tidyverse)
# library(bigutilsr)
`%nin%` = Negate(`%in%`)

samp.path <- "data/integrated_call_samples_v3.20130502.ALL.panel"
samp <- read_table2(samp.path) %>% select(-X5)
vec.path <- "path/to/sample_1kG_merged.eigenvec"

# assign sample to cluster
## https://www.biorxiv.org/content/10.1101/2020.10.06.328203v2.full
## http://adomingues.github.io/2015/09/24/finding-closest-element-to-a-number-in-a-list/
find_cluster <- function(df,clusters_df){
  iid <- select(df, starts_with("PC"))
  mat <- bind_rows(clusters_df, iid) %>% dist(.)
  # mat
  clus <- as.matrix(mat)[6,1:5] %>% which.min()
  df %>% mutate(super_pop = pops[clus])
}

# Formating data
vec <- read_table2(vec.path, col_names = F) %>%
  rename(fid = X1, iid = X2, PC1 = X3, PC2 = X4, PC3 = X5, PC4 = X6, PC5 = X7, PC6 = X8, PC7 = X9, PC8 = X10, PC9 = X11, PC10 = X12) %>%
  left_join(samp, by = c('iid' = 'sample')) %>%
  mutate(super_pop = ifelse(is.na(super_pop), "sample", super_pop),
         pop = ifelse(is.na(pop), "sample", pop)) %>%
  select(-gender)

# Pull out 1000 genomes samples
kg <- filter(vec, iid %in% samp$sample)

# population names
pops <- kg %>% filter(pop != "sample") %>% arrange(super_pop) %>% distinct(super_pop) %>% pull()

# find geometric median of each PC for each cluster
clusters <- kg %>%
  group_split(super_pop) %>%
  magrittr::set_names(pops) %>%
  map(., select, starts_with("PC")) %>%
  map(., bigutilsr::geometric_median) %>%
  bind_rows(.id = "iid")

# extract sample information and assign to cluster
samples <- vec %>%
  filter(iid %in% samp$sample) %>%
  mutate(iid = paste0("sample_", 1:nrow(.))) %>%
  group_split(iid) %>%
  map_df(., find_cluster, clusters_df=clusters)

dat <- bind_rows(kg, samples)

write_tsv(dat, "data/1kg_pcs.tsv")
