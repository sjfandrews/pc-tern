library(tidyverse)
library(ggplot2)
library(cowplot)
library(ggtern)

pcs.path <- snakemake@input[['pcs']]
ref_superpops.path  <- snakemake@input[['ref_superpops']]
plot.out = snakemake@output[[1]]

pcs <- read_tsv(pcs.path)
ref <- read_table2(ref_superpops.path)

pops <- pcs %>% filter(pop != "sample") %>% arrange(super_pop) %>% distinct(super_pop)  %>% pull()

# Format data for ploting ternery PCA
dat.tern <- select(pcs, PC1, PC2, PC3)  %>%
  mutate(PC1 = PC1 + (min(PC1) * -1),
         PC2 = PC2 + (min(PC2) * -1),
         PC3 = PC3 + (min(PC3) * -1)) %>%
  as.matrix() %>%
  prop.table(., 1)  %>%
  as.data.frame() %>%
  bind_cols(select(pcs, iid, super_pop))

## Plot 1kg reference population only
plc <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")

dat.kg <- filter(dat.tern, iid %in% ref$IID)
ref.p <- ggplot(data=dat.kg, aes(x=PC1, y=PC2, z=PC3, colour = super_pop)) +
  coord_tern() +
  geom_point(size = 1) +
  scale_color_manual(values = plc) +
  theme_bw() +
  theme_showarrows() +
  theme_notitles()  +
  labs(color = "Reference - 1000 Genomes") +
  theme(text = element_text(size=10))

# ref.p

## Overlay sample on reference population pca space
plc2 <- c("grey75", "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")

dat.sample <- dat.tern %>% mutate(super_pop = ifelse(iid %in% ref$IID,"1kg", super_pop))
sample.p <- ggplot(data=dat.sample, aes(x=PC1, y=PC2, z=PC3, colour = super_pop)) +
  scale_color_manual(values = plc2, labels = c("Reference", pops)) +
  coord_tern() +
  geom_point(size = 1) +
  theme_bw() +
  theme_showarrows() +
  theme_notitles()  +
  labs(color = "Sample") +
  theme(text = element_text(size=10))

legend <- get_legend(
  # create some space to the left of the legend
  ggplotGrob(sample.p + theme(legend.box.margin = margin(0, 0, 0, 12), legend.title = element_blank()))
)

p1 <- plot_grid(
  ggplotGrob(ref.p + theme(legend.position="none", plot.margin=unit(c(-15,-7,-7,-7), "mm"))),
  ggplotGrob(sample.p + theme(legend.position="none", plot.margin=unit(c(-15,-7,-7,-7), "mm"))),
  legend,
  labels = c('Reference (1000 Genomes)', 'Sample'), label_size = 12, ncol = 3,
  rel_widths = c(1, 1, 0.25)
  )
# p1

ggsave(plot.out, plot = p1, width = 12, height = 6, units = "in")

## Admixture
#
# Q.dat_long <- samples %>%
#   pivot_longer(c(K1,K2,K3,K4,K5), names_to = "K", values_to = "prop" ) %>%
#   mutate(K = fct_relevel(K, c("K4","K1","K2","K3","K5"))) %>%
#   arrange(K, prop) %>%
#   mutate(iid = fct_inorder(iid),
#          ids = 1:nrow(.))
# c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")
# admix = ggplot(Q.dat_long , aes(x = iid, y = prop, fill = K)) +
#   geom_bar(position="fill", stat="identity", width = 1) +
#   scale_fill_manual(name="Super Population",
#                     values=plc,
#                     breaks=c("K2","K1","K5","K4","K3") ,
#                     labels=c("AFR", "AMR","EAS", "EUR", "SAS")) +
#   theme_classic() + labs(x = "Indivuals", y = "Global Ancestry", color ="Super Population") +
#   facet_grid(~fct_inorder(super_pop), switch = "x", scales = "free", space = "free")+
#   theme(
#     axis.text.x = element_blank(),
#     axis.ticks.x=element_blank(),
#     axis.title.y=element_blank(),
#     axis.title.x =element_blank(),
#     panel.grid.major.x = element_blank())
#
# ggsave("plots/admixture.png", plot = admix, width = 12, height = 6, units = "in")
#
#
# ## combine PCA & admixture
# pca.p <- ggplot(data=dat.sample, aes(x=PC1, y=PC2, z=PC3, colour = super_pop)) +
#   scale_color_manual(values = plc2, labels = c("Reference", pops)) +
#   coord_tern() +
#   geom_point(size = 1) +
#   theme_bw() +
#   theme_showarrows() +
#   theme_notitles()  +
#   labs(color = "Sample", title = "a) Genetic Ancestry") +
#   theme(text = element_text(size=10), legend.position = "bottom") +
#   guides(colour = guide_legend(nrow = 1))
#
# p_legend <- get_legend(
#   # create some space to the left of the legend
#   ggplotGrob(pca.p + theme(legend.box.margin = margin(0, 0, 0, 0), legend.title = element_blank()))
# )
#
# right_col <- plot_grid(ggplot() + theme_void(),
#                        admix + theme(legend.position="none"),
#                        admix + theme(legend.position="none"),
#                        ggplot() + theme_void(),
#                        nrow = 4, rel_heights = c(0.15, 1, 1, 0.15),
#                        labels = c("", "b) Global Ancestry", "c) Local Ancestry", ""),
#                        label_size = 10
#                        )
#
# p2 = plot_grid(
#   ggplotGrob(sample.p +
#                theme_hidelabels() +
#                theme(legend.position="bottom", plot.margin=unit(c(-15,-7,-7,-7), "mm")) +
#                guides(colour = guide_legend(nrow = 1))
#              ),
#   right_col,
#   ncol = 2,
#   rel_widths = c(0.75, 1),
#   labels = c("a) Genetic Ancestry", ""),
#   label_size = 10
# )
# p2
# ggsave("plots/pca_admixture.png", plot = p2, width = 12, height = 6, units = "in")
#
# plot_grid(p2, p_legend,
#   nrow = 2, rel_widths = c(1, 0.01)
# )
#
#
