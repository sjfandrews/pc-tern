#!/usr/bin/Rscript
## ========================================================================== ##
## Make plots for model-based clustering of ancestral populations w/ ggplot
## ========================================================================== ##


## Infiles
Qdat1 = snakemake@input[["Qdat1"]]
Qdat2 = snakemake@input[["Qdat2"]]

## Outfile
p1.out = snakemake@output[["p1"]] # Output
p2.out = snakemake@output[["p2"]] # Output

message(
  "\ninput: ", Qdat1, Qdat2,
  "\noutput:" ,p2.out, p2.out, "\n"
)
message ("Loading packages")
library(dplyr)
library(tibble)
library(purrr)
library(forcats)
library(ggplot2)
library(ggthemes)
library(patchwork)
library(readr)
library(tidyr)
library(RColorBrewer)

message("Reading admixture file  \n")
dat1 <- read_table2(Qdat1)


Q.dat_long1 <- dat1 %>%
  pivot_longer(c(AFR,AMR,EAS,SAS,EUR), names_to = "K", values_to = "prop" ) %>%
  mutate(K = fct_relevel(K, c("EUR","AFR","AMR","EAS","SAS"))) %>%
    arrange(K, prop) %>%
     mutate(iid = fct_inorder(iid))
colour <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")
p1 <- ggplot(Q.dat_long1 , aes(x = iid, y = prop, fill = K)) +
  geom_bar(position="fill", stat="identity", width = 1) +
  scale_fill_brewer(palette = colour,
                    name="Super Population",
  theme_classic() + labs(x = "Indivuals", y = "Global Ancestry", color ="Super Population") +
  facet_grid(~fct_inorder(super_pop), switch = "x", scales = "free", space = "free")+
  theme(
  axis.text.x = element_blank(),
  axis.ticks.x=element_blank(),
  axis.title.y=element_blank(),
  axis.title.x =element_blank(),
  panel.grid.major.x = element_blank())

png(p1.out, units="in", width=10, height=6, res = 300)
p1
dev.off()


dat2 <- read_tsv(Qdat2)
Q.dat_long2 <- dat2 %>%
  pivot_longer(c(AFR,AMR,EAS,SAS,EUR), names_to = "K", values_to = "prop" ) %>%
  mutate(K = fct_relevel(K, c("EUR","AFR","AMR","EAS","SAS"))) %>%
    arrange(K, prop) %>%
    mutate(iid = fct_inorder(iid))


p2 <- ggplot(Q.dat_long2 , aes(x = iid, y = prop, fill = K)) +
  geom_bar(position="fill", stat="identity", width = 1) +
  scale_fill_brewer(palette = colour,
                      name = "Super Population") +
  theme_classic() + labs(x = "Indivuals", y = "Global Ancestry", color ="Super Population") +
  facet_grid(~fct_inorder(super_pop2), switch = "x", scales = "free", space = "free")+
  theme(
        axis.text.x = element_blank(),
         axis.ticks.x=element_blank(),
         axis.title.y=element_blank(),
         axis.title.x =element_blank(),
         panel.grid.major.x = element_blank())

png(p2.out, units="in", width=10, height=6, res = 300)
p2
dev.off()
