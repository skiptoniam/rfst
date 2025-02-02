# 18 metapopulation capacity models data list

source("R/spartan/spartan_settings.R")

library(magrittr)
library(tibble)
library(tidyr)
library(dplyr)
library(purrr)
library(raster)
library(sp)
library(sf)


load(file = "output/RData/00_controls.RData")
load(file = "output/RData/01_landscape_variables.RData")
load(file = "output/RData/14.1_sp_occ_metapop.RData")
load(file= "output/RData/17_mpc_predict_sdm.RData")

source.functions("R/functions")



threshold_max_sss <- pred_mpc[1:14,] %$%
  mapply(
    x = predmaps,
    sp = sp,
    FUN = get.threshold.max.sss,
    MoreArgs = list(
      y = pa_data_ch_model
    )
  )

thresholds <- tibble(
  sp = pred_mpc$sp[1:14],
  threshold_max_sss = threshold_max_sss
)


dispersal_dist <- tribble(
  ~sp, ~ddist,
  "acno", 10000,
  "cipu", 2000,
  "grba", 50,
  "isob", 500,
  "lese", 50,
  "lois", 10000,
  "nico", 10000,
  "nist", 10000,
  "pear", 50,
  "pero", 2000,
  "psfu", 500,
  "psse", 200,
  "tyno", 10000,
  "wiva", 50
)

mpc_dat <- pred_mpc %>%
  full_join(
    y = thresholds,
    by = "sp"
  ) %>%
  full_join(
    y = dispersal_dist,
    by = "sp"
  )


save(
  mpc_dat,
  file = "/data/gpfs/projects/punim0995/rfst/output/RData/18.0_mpc_list.RData"
)
