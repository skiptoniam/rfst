# 4.1 aggregate mortality

source("R/spartan/spartan_settings.R")


library(dplyr)
library(purrr)
library(tibble)
library(tidyr)
library(raster)
library(sp)
library(sf)
library(magrittr)

load(file = "output/RData/00_controls_eg.RData")
load(file = "output/RData/01_landscape_variables_eg.RData")
load(file = "output/RData/04_disturbance_variables_eg.RData")


source.functions("R/functions")

command_args <- commandArgs(trailingOnly = TRUE)

i <- as.numeric(command_args[1])


tsl <- lapply(
  X = disturbance_variables_eg$dist_vars[[i]],
  FUN = function(x){
    x$tsl
  }
)

tsl_agg <- lapply(
  X = tsl,
  FUN = raster::aggregate,
  fact = 2,
  fun = tsl.agg,
  na.rm = TRUE
) %>%
  brick

writeRaster(
  tsl_agg,
  filename = sprintf(
    fmt = "%s/tsl_agg4_%s.grd",
    "/data/gpfs/projects/punim1340/rfst_eg/output/tsl_aggregated",
    disturbance_variables_eg$yscn_id[i]
  ),
  overwrite = TRUE
)

tsl_agg <- brick(
  x = sprintf(
    fmt = "%s/tsl_agg4_%s.grd",
    "/data/gpfs/projects/punim1340/rfst_eg/output/tsl_aggregated",
    disturbance_variables_eg$yscn_id[i]
  )
)


tsl_table <- tibble(
  yscn_id = disturbance_variables_eg$yscn_id[i],
  tsl_agg = list(tsl_agg)
)

saveRDS(
  object = tsl_table,
  file = sprintf(
    fmt = "%s/tsl_agg_%s.Rds",
    "/data/gpfs/projects/punim1340/rfst_eg/output/spartan_RData/tsl_agg",
    disturbance_variables_eg$yscn_id[i]
  )
)

