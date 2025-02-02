patmat <- function(
  x,
  threshold,
  out_path = "output/patch_matrix/",
  scn_id = NA,
  varset = "",
  species = NA,
  write = TRUE
){
  
  if(write){
    if(is.na(scn_id)) {
      stop("scn_id missing")
    }
    
    if(is.na(species)){
      stop("species missing")
    }
  }
  
  
  x[x < threshold] <- 0
  
  x[x > 0] <- 1
  
  
  names(x) <- sprintf("patch_matrix_%02d", 0:(dim(x)[3] - 1))
  
  if(write){
    writeRaster(
      x,
      filename = sprintf(
        "%s/patmat_%s_%s_%s_%s.grd",
        out_path,
        scn_id,
        varset,
        species,
        threshold
      ),
      overwrite = TRUE
    )
  }
  
  
  return(x)
  
}