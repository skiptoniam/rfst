pg.pa <- function(sp_pa, rfa_unit, datum = 32755, option = "A"){
  
  library(ggplot2)
  
  z <- ggplot(data = rfa_unit) +
    geom_sf() +
    geom_sf(data = sp_pa %>% mutate(Presence = as.factor(PA)), aes(colour = Presence, fill = Presence), size = 0.5) +
    coord_sf(datum = datum) +
    scale_colour_viridis_d(option = option) +
    scale_fill_viridis_d(option = option)
  
}