#!/usr/bin/Rscript
## ========================================================================== ##
## Make plots for model-based clustering of ancestral populations w/ ggplot
## ========================================================================== ##


## Infiles
Qdat = snakemake@input[["Qdat"]]


## Outfile
kplot.out = snakemake@output[["kplot"]] # Output

message(
  "\ninput: ", Qdat,
  "\noutput:", kplot.out , "\n"
)


message("Reading admixture file  \n")
Q.dat <- read_table2(Qdat)
Q.dat_long <- Q.dat %>%
filter(pop == 'sample') %>%
  pivot_longer(c(K1,K2,K3,K4, K5), names_to = "K", values_to = "prop" ) %>%
   mutate(K = fct_relevel(K, c("K4","K1","K2","K3","K5"))) %>%
    arrange(K, prop) %>%
     mutate(iid = fct_inorder(iid))

p1 <- ggplot(Q.dat_long , aes(x = iid, y = prop, fill = K)) +
  geom_bar(position="fill", stat="identity", width = 1) +
  scale_fill_brewer(palette = "Set1",
                      name="Super Population",
                      breaks=c("K1","K5","K3","K4","K2") ,
                      labels=c("AFR", "AMR","EAS", "EUR", "SAS")) +
  theme_classic() + labs(x = "Indivuals", y = "Global Ancestry", color ="Super Population") +
  facet_grid(~fct_inorder(super_pop), switch = "x", scales = "free", space = "free")+
  theme(
        axis.text.x = element_blank(),
         axis.ticks.x=element_blank(),
         axis.title.y=element_blank(),
         axis.title.x =element_blank(),
         panel.grid.major.x = element_blank())

ggsave(kplot.out, plot = p1, width = 12, height = 6, units = "in")
