library(tidyverse)
library(glue)
sample <- "adni"; sample <- "dian"; sample <- "gsa1234567"

q.path <- glue("sandbox/output/{sample}_1kG_merged.5.Q")
pcs.path <- glue("sandbox/output/{sample}_1kG_pcs_pops.tsv")

q.path <-  snakemake@input[['Q']]
pcs.path <- snakemake@input[['pcs_pops']]

Q.dat.raw <- read_table2(q.path, col_names = c("K1","K2","K3","K4","K5"))
pcs <- read_tsv(pcs.path)

Q.dat <- bind_cols(pcs, Q.dat.raw)

Q.dat.long <- Q.dat %>%
  filter(pop == 'sample') %>%
  pivot_longer(c(K1,K2,K3,K4,K5), names_to = "K", values_to = "prop" ) %>%
  mutate(K = fct_relevel(K, c("K4","K1","K2","K3","K5"))) %>%
  arrange(K, prop) %>%
  mutate(iid = fct_inorder(iid))

plc <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")
admix = ggplot(Q.dat.long , aes(x = iid, y = prop, fill = K)) +
  geom_bar(position="fill", stat="identity", width = 1) +
  scale_fill_manual(name="Super Population",
                    values=plc,
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
admix

ggsave("plots/admixture.png", plot = admix, width = 12, height = 6, units = "in")
