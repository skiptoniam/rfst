# 09 fit distribution models

source("R/spartan/spartan_settings.R")

library(raster)
library(dplyr)
library(sf)
library(lubridate)
library(purrr)
library(tibble)
#library(future)
#library(furrr)
library(tidyr)
#library(future.apply)
library(dismo)
library(gbm)

load(file = "output/RData/00_controls.RData")
load(file = "output/RData/01_landscape_variables.RData")
load(file = "output/RData/02_species_occurrences.RData")
load(file = "output/RData/07_combined_variables.RData")
load(file = "output/RData/08_distribution_model_data.RData")

source.functions("R/functions")

#plan(multisession)


varlist <- c(
  "date",         # 01
  "PA",           # 02
  "lbm_prop",     # 03
  "lbm_biom",     # 04
  "ac_prop",      # 05
  "ac_biom",      # 06
  "ggf_prop",     # 07
  "ggf_biom",     # 08
  "ggd_prop",     # 09
  "ggd_prop_og",  # 10
  "ggd_biom",     # 11
  "ggd_biom_og",  # 12
  "prop_bio_regn",# 13
  "prop_bio_targ",# 14
  "prop_old_150", # 15
  "prop_old_200", # 16
  "prop_oge",     # 17
  "prop_oge_3h",  # 18
  "prop_oge_1k",  # 19
  "biom_oge",     # 20
  "biom_oge_3h",  # 21
  "biom_oge_1k",  # 22
  "harvest",      # 23
  "firesev",      # 24
  "max_age",      # 25
  "pb",           # 26
  "fi",           # 27
  "lo",           # 28
  "fihi",         # 29
  "lohi",         # 30
  "tsf",          # 31
  "tsl",          # 32
  "mort",         # 33
  "prec_djf_2019",# 34
  "prec_jja_2019",# 35
  "tmax_djf_2019",# 36
  "tmin_jja_2019",# 37
  "lvdaw",        # 38
  "lvdma",        # 39
  "lvdmi",        # 40
  "lvdsw",        # 41
  "ahr",          # 42
  "tho",          # 43
  "lon",          # 44
  "lat"           # 45
)




if(!all(colnames(distribution_model_data$dist_mod_dat[[1]]) == varlist)){
  stop("Varlist definition and variable layers are different")
}

sp_sdm_vars <- tribble(
  ~sp, ~ sdm_vars,
  "gyle", varlist[c(3:8, 10, 12, 17:22, 25, 34:45)],
  #"pevo", varlist[c(3:8, 10, 12, 18, 21, 25, 34:45)],
  "pevo", varlist[c(7, 10, 12, 25, 34:45)],
  "peau", varlist[c(3:8, 10, 12, 17:22, 25, 34:45)],
  "smle", varlist[c(3:8, 10, 12, 17:22, 25, 34:45)],
  "tyte", varlist[c(3:8, 10, 12, 17:22, 25, 34:45)],
  "vava", varlist[c(3:8, 10, 12, 17:22, 25, 34:45)]
)

sdm_data <- full_join(
  x = distribution_model_data,
  y = sp_sdm_vars,
  by = "sp"
) %>%
  mutate(
    weights = map(
      .x = pa_dat,
      .f = function(x){
        z <- x %>%
          group_by(PA) %>%
          mutate(
            npa = n()
          ) %>%
          ungroup %>%
          mutate(
            sump = length(which(PA == 1))
          ) %>%
          mutate(
            weight = sump/npa
          )
        
        result <- z$weight
        
        return(result)
      }
    )
  )


# LBP -----------------


sdm_gyle <- sdm_data %>%
  filter(sp == "gyle") %>%
  mutate(
    model_data = map2(
      .x = dist_mod_dat,
      .y = sdm_vars,
      .f = clean.model.data,
      na.omit = TRUE
    )
  ) %>%
  mutate(
    brt.fit = map(
      .x = model_data,
      .f = gbmstep,
      tree.complexity = 5,
      learning.rate = 0.03,
      #step.size = 1,
      bag.fraction = 0.5,
      prev.stratify = TRUE,
      verbose = FALSE,
      max.trees = 5000
    )
  ) %>%
  mutate(auc = map(.x = brt.fit,
                          .f = brt_auc)) %>%
  unnest(auc) %>%
  mutate(trees = map(.x = brt.fit, .f = ~ .$gbm.call$best.trees)) %>%
  unnest(trees)

# GG  -----------------
sdm_pevo <- sdm_data %>%
  filter(sp == "pevo") %>%
  mutate(
    model_data = map2(
      .x = dist_mod_dat,
      .y = sdm_vars,
      .f = clean.model.data,
      na.omit = TRUE
    ),
    model_data = map(
      .x = model_data,
      .f = function(x){
        
        z <- x %>%
          group_by(PA) %>%
          mutate(
            npa = n()
          ) %>%
          ungroup %>%
          mutate(
            sump = length(which(PA == 1))
          ) %>%
          mutate(
            site.weights = sump/npa
          ) %>%
          dplyr::select(
            -npa,
            -sump
          )  %>%
          as.data.frame
        
        return(z) 
      
      }
    )
  ) %>%
  mutate(
    brt.fit = map(
      .x = model_data,
      .f = gbmstep,
      tree.complexity = 4,
      learning.rate = 0.02,
      #step.size = 1,
      bag.fraction = 0.5,
      prev.stratify = TRUE,
      verbose = FALSE,
      max.trees = 5000
    )
  ) %>%
  mutate(auc = map(.x = brt.fit,
                          .f = brt_auc)) %>%
  unnest(auc) %>%
  mutate(trees = map(.x = brt.fit, .f = ~ .$gbm.call$best.trees)) %>%
  unnest(trees)


pi_pevo <- brtpredict(
  variables = var_set$all_vars[[1]],
  model = sdm_pevo$brt.fit[[1]],
  scn_id = "TH19_rcp45_PB_01_ACCESS1-0_init",
  varset = "",
  species = "pevo",
  initial = TRUE
)

pp_pevo <- brtpredict(
  variables = var_set$all_vars[[1]],
  model = sdm_pevo$brt.fit[[1]],
  out_path = "/data/gpfs/projects/punim0995/rfst/output/",
  scn_id = "TH19_rcp45_PB_01_ACCESS1-0",
  varset = "",
  species = "pevo",
  initial = FALSE,
  pll = FALSE,
  ncores = 1
)


pp_pevo <- brtpredict(
  variables = var_set$all_vars[[1]],
  model = sdm_results$brt.fit[[1]],
  out_path = "/data/gpfs/projects/punim0995/rfst/output/",
  scn_id = "TH19_rcp45_PB_01_ACCESS1-0",
  varset = "",
  species = "pevo",
  initial = FALSE,
  pll = FALSE,
  ncores = 1
)

# YBG -----------------
sdm_peau <- sdm_data %>%
  filter(sp == "peau") %>%
  mutate(
    model_data = map2(
      .x = dist_mod_dat,
      .y = sdm_vars,
      .f = clean.model.data,
      na.omit = TRUE
    )
  ) %>%
  mutate(
    brt.fit = map(
      .x = model_data,
      .f = gbmstep,
      tree.complexity = 5,
      learning.rate = 0.02,
      #step.size = 1,
      bag.fraction = 0.5,
      prev.stratify = TRUE,
      verbose = FALSE,
      max.trees = 5000
    )
  ) %>%
  mutate(auc = map(.x = brt.fit,
                          .f = brt_auc)) %>%
  unnest(auc) %>%
  mutate(trees = map(.x = brt.fit, .f = ~ .$gbm.call$best.trees)) %>%
  unnest(trees)

# WFD -----------------
sdm_smle <- sdm_data %>%
  filter(sp == "smle") %>%
  mutate(
    model_data = map2(
      .x = dist_mod_dat,
      .y = sdm_vars,
      .f = clean.model.data,
      na.omit = TRUE
    )
  ) %>%
  mutate(
    brt.fit = map(
      .x = model_data,
      .f = gbmstep,
      tree.complexity = 7,
      learning.rate = 0.002,
      #step.size = 1,
      bag.fraction = 0.5,
      prev.stratify = TRUE,
      verbose = FALSE,
      max.trees = 5000
    )
  ) %>%
  mutate(auc = map(.x = brt.fit,
                          .f = brt_auc)) %>%
  unnest(auc) %>%
  mutate(trees = map(.x = brt.fit, .f = ~ .$gbm.call$best.trees)) %>%
  unnest(trees)

# SO  -----------------
sdm_tyte <- sdm_data %>%
  filter(sp == "tyte") %>%
  mutate(
    model_data = map2(
      .x = dist_mod_dat,
      .y = sdm_vars,
      .f = clean.model.data,
      na.omit = TRUE
    )
  ) %>%
  mutate(
    brt.fit = map(
      .x = model_data,
      .f = gbmstep,
      tree.complexity = 7,
      learning.rate = 0.005,
      #step.size = 1,
      bag.fraction = 0.5,
      prev.stratify = TRUE,
      verbose = FALSE,
      max.trees = 5000
    )
  ) %>%
  mutate(auc = map(.x = brt.fit,
                          .f = brt_auc)) %>%
  unnest(auc) %>%
  mutate(trees = map(.x = brt.fit, .f = ~ .$gbm.call$best.trees)) %>%
  unnest(trees)

# LM  -----------------
sdm_vava <- sdm_data %>%
  filter(sp == "vava") %>%
  mutate(
    model_data = map2(
      .x = dist_mod_dat,
      .y = sdm_vars,
      .f = clean.model.data,
      na.omit = TRUE
    )
  ) %>%
  mutate(
    brt.fit = map(
      .x = model_data,
      .f = gbmstep,
      tree.complexity = 7,
      learning.rate = 0.003,
      #step.size = 1,
      bag.fraction = 0.5,
      prev.stratify = TRUE,
      verbose = FALSE,
      max.trees = 5000
    )
  ) %>%
  mutate(auc = map(.x = brt.fit,
                          .f = brt_auc)) %>%
  unnest(auc) %>%
  mutate(trees = map(.x = brt.fit, .f = ~ .$gbm.call$best.trees)) %>%
  unnest(trees)

# -----------

sdm_results <- bind_rows(
  #sdm_gyle,
  sdm_pevo#,
  #sdm_peau,
  #sdm_smle,
  #sdm_tyte,
  #sdm_vava
)

# 
# sdm_results <- sdm_results %>%
#   filter(sp != "pevo") %>%
#   bind_rows(
#     sdm_pevo
#   ) %>%
#   arrange(sp)

# -----------
save(
  sdm_results,
  file = "output/RData/09_fit_distribution_models_3.RData"
)