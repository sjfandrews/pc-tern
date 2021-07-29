#!/usr/bin/Rscript
## ========================================================================== ##
## Make plots for model-based clustering of ancestral populations w/ ggplot
## ========================================================================== ##


## Infiles
Qdat = snakemake@input[["Qdat"]]


## Outfile
# p1.out = snakemake@output[["p1"]] # Output
p2.out = snakemake@output[["p2"]] # Output

message(
  "\ninput: ", Qdat,
  "\noutput:" ,p2.out, "\n"
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
Q.dat <- read_tsv(Qdat)
Q.dat

# Q.dat_long <- Q.dat %>%
# pivot_longer(c(K1,K2,K3,K4, K5), names_to = "K", values_to = "prop" ) %>%
# mutate(K = fct_relevel(K, c("K4","K1","K2","K3", "K5"))) %>%
#     arrange(K, prop) %>%
#      mutate(iid = fct_inorder(iid))
#
# p1 <- ggplot(Q.dat_long , aes(x = iid, y = prop, fill = K)) +
#   geom_bar(position="fill", stat="identity", width = 1) +
#   scale_fill_brewer(palette = "Set1",
#                     name="Super Population") +
#                     breaks=c("K1","K5","K3","K4","K2") ,
#                     labels=c("AFR", "AMR","EAS", "EUR", "SAS")) +
#   theme_classic() + labs(x = "Indivuals", y = "Global Ancestry", color ="Super Population") +
#   facet_grid(~fct_inorder(super_pop), switch = "x", scales = "free", space = "free")+
#   theme(
#   axis.text.x = element_blank(),
#   axis.ticks.x=element_blank(),
#   axis.title.y=element_blank(),
#   axis.title.x =element_blank(),
#   panel.grid.major.x = element_blank())
#      png(kplot.out, units="in", width=10, height=6, res = 300)
#      kplot
#      dev.off()

Q.dat_long2 <- Q.dat %>%
  pivot_longer(c(AFR,AMR,EAS,SAS,EUR), names_to = "K", values_to = "prop" ) %>%
  mutate(K = fct_relevel(K, c("EUR","AFR","AMR","EAS","SAS"))) %>%
  arrange(K, prop) %>%
  mutate(iid = fct_inorder(iid))
Q.dat_long2

p2 <- ggplot(Q.dat_long2 , aes(x = iid, y = prop, fill = K)) +
  geom_bar(position="fill", stat="identity", width = 1) +
  scale_fill_brewer(palette = "Set1",
                      name = "Super Population") +
                      #breaks=c("K1","K5","K3","K4","K2") ,
                      #labels=c("AFR", "AMR","EAS", "EUR", "SAS")) +
  theme_classic() + labs(x = "Indivuals", y = "Global Ancestry", color ="Super Population") +
  facet_grid(~fct_inorder(super_pop2), switch = "x", scales = "free", space = "free")+
  theme(
        axis.text.x = element_blank(),
         axis.ticks.x=element_blank(),
         axis.title.y=element_blank(),
         axis.title.x =element_blank(),
         panel.grid.major.x = element_blank())
# png(p1.out, units="in", width=10, height=6, res = 300)
# p1
# dev.off()

png(p2.out, units="in", width=10, height=6, res = 300)
p2
dev.off()
