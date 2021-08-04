set.seed(333)

dat <- read_tsv("data/1kg_pcs.tsv")

# UMAP 
## mtRef
set.seed(333)
train_umap_res = filter(dat, !str_detect(iid, "sample"))  %>% 
  # select(., starts_with("Dim")) %>%
  select(., PC1:PC3) %>%
  uwot::umap(., min_dist = 0.99, spread = 0.5, n_neighbor = 50, n_components = 2, init = "spectral", 
             verbose = TRUE, ret_model = TRUE)

train_umap_tab <- train_umap_res %>% 
  magrittr::use_series(embedding) %>% 
  as_tibble() %>% 
  magrittr::set_colnames(str_replace(colnames(magrittr::extract(.)), "V", "UMAP")) %>% 
  bind_cols(filter(dat, !str_detect(iid, "sample")))

## 1kg Predicted UMAP 
sample_umap_res <- filter(dat, str_detect(iid, "sample")) %>% 
  # select(., starts_with("Dim")) %>%
  select(., PC1:PC3) %>%
  uwot::umap_transform(., train_umap_res, verbose = TRUE)

sample_umap_tab <- sample_umap_res %>% 
  as_tibble() %>% 
  magrittr::set_colnames(str_replace(colnames(magrittr::extract(.)), "V", "UMAP")) %>% 
  bind_cols(filter(dat, str_detect(iid, "sample")))

dat.umap <- bind_rows(train_umap_tab, sample_umap_tab)

plc <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")

umap.kg <- filter(dat.umap, !str_detect(iid, "sample")) 
ref.umap <- ggplot(umap.kg, aes(x = UMAP1, y = UMAP2, colour = super_pop)) + 
  scale_color_manual(values = plc) + 
  geom_point(size = 0.25) + 
  guides(colour = guide_legend(override.aes = list(size=2))) +
  theme_bw() + 
  theme(text = element_text(size=10)) + 
  labs(title = 'Reference (1000 Genomes)')
ref.umap

plc2 <- c("grey75", "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00")
dat.sample <- dat.umap %>% mutate(super_pop = ifelse(str_detect(iid, "sample"), super_pop, "1kg"))
sampele.umap <- ggplot(dat.sample, aes(x = UMAP1, y = UMAP2, colour = super_pop)) + 
  scale_color_manual(values = plc2) + 
  geom_point(size = 0.25) + 
  guides(colour = guide_legend(override.aes = list(size=2))) +
  theme_bw() + 
  theme(text = element_text(size=10)) + 
  labs(title = 'Sample')
sampele.umap

legend <- get_legend(
  sampele.umap + theme(legend.box.margin = margin(0, 0, 0, 12), legend.title = element_blank())
)

p1 <- plot_grid(
  ref.umap + theme(legend.position="none"), 
  sampele.umap + theme(legend.position="none"), 
  legend, 
  ncol = 3, 
  rel_widths = c(1, 1, 0.25)
)
p1 

ggsave("~/downloads/umap.png", plot = p1, width = 12, height = 6, units = "in")
