# 00 project controls

source("R/spartan/spartan_settings.R")

library(dismo)
library(doMC)
library(dplyr)
library(foreach)
#library(future)
#library(future.apply)
library(gbm)
library(ggplot2)
library(lubridate)
library(lwgeom)
library(magrittr)
library(metacapa)
library(purrr)
library(raster)
library(rasterVis)
library(readr)
library(readxl)
library(rerddap)
library(rgdal)
#library(rlang)
library(sf)
library(steps)
library(tibble)
library(tidyr)
library(viridis)


source(file = "R/functions/source.functions.R")
source.functions("R/functions")

proj_path <- "/data/gpfs/projects/punim0995/rfst"

landis_path_eg <- "/data/scratch/projects/punim1340/landis_raw/east_gippsland/"

data_path <- "/data/gpfs/projects/punim0995/rfst/data"

out_path_eg <- "/data/gpfs/projects/punim1340/rfst_eg/output/"

#proj_path <- "/home/unimelb.edu.au/ryange/rfst"
# proj_path <- "D:/Users/ryan/Dropbox/Work/RFA_STEPS/rfst/"

year0 <- 2019

ntimesteps <- 50

#ncores <- 20
ncores <- 1

nreplicates <- 100


rep_list <- sprintf("%02d", 1:10)

harvest_scenario <- c("TH00", "TH19", "TH30")

rcp <- c("rcp45", "rcp85")

plan_burn <- c("PB", "NB")

yearid <- c("EG19", "EG20")

scn_table_eg <- expand.grid(
  yearid = yearid,
  harvest_scenario = harvest_scenario,
  rcp = rcp,
  plan_burn = plan_burn,
  scenario_replicate = rep_list
) %>%
  as_tibble %>%
  mutate(
    scenario = sprintf(
      "%s_%s_%s_%s",
      yearid,
      harvest_scenario,
      rcp,
      plan_burn
    ),
    yscn_id = sprintf(
      "%s_%s_%s_%s_%s",
      yearid,
      harvest_scenario,
      rcp,
      plan_burn,
      scenario_replicate
    ),
    scn_id = sprintf(
      "%s_%s_%s_%s",
      harvest_scenario,
      rcp,
      plan_burn,
      scenario_replicate
    ),
    dir = paste0(
      landis_path_eg,
      yscn_id
    ),
    th = sub(
      pattern = "TH",
      replacement = "",
      x = harvest_scenario
    ),
    rc = sub(
      pattern = "rcp",
      replacement = "",
      x = rcp
    ),
    pb = ifelse(
      plan_burn == "PB",
      TRUE,
      FALSE
    )
  ) %>%
  filter(
    plan_burn == "PB" |
      (harvest_scenario == "TH00" & rcp == "rcp45")
  ) %>%
  filter(
    rcp == "rcp45" |
      harvest_scenario == "TH00" |
      harvest_scenario == "TH30"
  ) %>%
  mutate(
    scn_no = case_when(
      th == "19" ~ 1,
      th == "30" & rc == "45" ~ 2,
      th == "30" & rc == "85" ~ 3,
      th == "00" & rc == "45" & pb ~ 4,
      th == "00" & rc == "85" & pb ~ 5,
      th == "00" & rc == "45" & !pb ~ 6
    )
  ) %>%
  arrange(
    yearid,
    scn_no
  ) #%>%
#filter(scenario_replicate == "01")




species_table_eg <- tibble(
  species = c(
    #"Gymnobelideus leadbeateri",
    "Petauroides volans",
    "Petaurus australis",
    "Potorous longipes",
    "Sminthopsis leucopus",
    "Tyto tenebricosa",
    "Varanus varius"
  )
) %>%
  mutate(
    gen = sub(
      pattern = " .*",
      replacement = "",
      x = species
    ) %>%
      tolower %>%
      substr(
        start = 1,
        stop = 2
      ),
    spe = sub(
      pattern = ".* ",
      replacement = "",
      x = species
    ) %>%
      substr(
        start = 1,
        stop = 2
      ),
    sp = paste0(
      gen,
      spe
    )
  ) %>%
  dplyr::select(
    species,
    sp
  ) %>% 
  mutate(
    pva = TRUE,
    mpc = TRUE
  )


save(
  proj_path,
  landis_path_eg,
  data_path,
  year0,
  ntimesteps,
  ncores,
  nreplicates,
  out_path_eg,
  source.functions,
  scn_table_eg,
  species_table_eg,
  file = "output/RData/00_controls_eg.RData"
)
