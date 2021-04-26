library(tidyverse)
library(ggplot2)
library(cowplot)
library(ggtern)

dat <- read_tsv("data/1kg_pcs.tsv")
pops <- dat %>% filter(pop != "sample") %>% arrange(super_pop) %>% distinct(super_pop)  %>% pull()

# Format data for ploting ternery PCA
dat.tern <- select(dat, PC1, PC2, PC3)  %>% 
  mutate(PC1 = PC1 + (min(PC1) * -1), 
         PC2 = PC2 + (min(PC2) * -1), 
         PC3 = PC3 + (min(PC3) * -1)) %>% 
  as.matrix() %>% 
  prop.table(., 1)  %>%
  as.data.frame() %>%
  bind_cols(select(dat, iid, super_pop)) 

## Plot 1kg reference population only 
plc <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")

dat.kg <- filter(dat.tern, !str_detect(iid, "sample")) 
ref.p <- ggplot(data=dat.kg, aes(x=PC1, y=PC2, z=PC3, colour = super_pop)) + 
  coord_tern() + 
  geom_point(size = 1) + 
  scale_color_manual(values = plc) + 
  theme_bw() + 
  theme_showarrows() + 
  theme_notitles()  + 
  labs(color = "Reference - 1000 Genomes") + 
  theme(text = element_text(size=10))

ref.p

## Overlay sample on reference population pca space 
plc2 <- c("grey75", "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")

dat.sample <- dat.tern %>% mutate(super_pop = ifelse(str_detect(iid, "sample"), super_pop, "1kg"))
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
p1 

ggsave("output/pca_tern.png", plot = p1, width = 12, height = 6, units = "in")








































