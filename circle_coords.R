# Install required packages if not already installed
required_packages <- c("tidygeocoder", "geosphere")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if (length(new_packages)) {
  options(repos = c(CRAN = "https://cran.rstudio.com/"))
  install.packages(new_packages, quietly = TRUE)
}

library(tidygeocoder)
library(geosphere)

#' Generate Circle Coordinates from Address
#'
#' Creates a circular polygon around a given address with specified radius
#' 
#' @param address Character string of the address to geocode
#' @param radius_mi Numeric radius in miles
#' @param vertices Numeric number of vertices for the circle (default: 20)
#'
#' @return Character string of coordinates in format "lon1 lat1, lon2 lat2, ..."
#'         Final coordinate pair matches the first
#'
#' @examples
#' \dontrun{
#'   coords <- address_circle("1600 Pennsylvania Avenue NW, Washington, DC", radius_mi = 1)
#'   print(coords)
#' }
#'
#' @export
address_circle <- function(address, radius_mi, vertices = 20) {
  
  # Validate inputs
  if (!is.character(address) || length(address) != 1) {
    stop("address must be a single character string")
  }
  if (!is.numeric(radius_mi) || radius_mi <= 0) {
    stop("radius_mi must be a positive number")
  }
  if (!is.numeric(vertices) || vertices < 3 || vertices != floor(vertices)) {
    stop("vertices must be an integer >= 3")
  }
  
  # Geocode the address
  tryCatch({
    # tidygeocoder expects a dataframe
    addr_df <- data.frame(address = address)
    geo_result <- tidygeocoder::geocode(addr_df, address = address, method = "osm", quiet = TRUE)
    
    if (nrow(geo_result) == 0 || is.na(geo_result$long[1]) || is.na(geo_result$lat[1])) {
      stop("Could not geocode address: ", address)
    }
    
    center_lon <- geo_result$long[1]
    center_lat <- geo_result$lat[1]
    
  }, error = function(e) {
    stop("Geocoding error: ", conditionMessage(e))
  })
  
  # Convert miles to meters
  radius_meters <- radius_mi * 1609.34
  
  # Create angles for circle vertices (in degrees)
  angles <- seq(0, 360, length.out = vertices + 1)[1:vertices]
  
  # Generate coordinates on the circle
  coords_list <- list()
  for (i in 1:vertices) {
    angle_rad <- angles[i] * pi / 180
    
    # Use destPoint to get coordinates at distance and bearing
    point <- destPoint(
      p = c(center_lon, center_lat),
      b = angles[i],  # bearing in degrees
      d = radius_meters
    )
    
    coords_list[[i]] <- sprintf("%.6f %.6f", point[1], point[2])
  }
  
  # Add closing point (same as first)
  closing_point <- coords_list[[1]]
  
  # Format output string
  output <- paste(c(coords_list, closing_point), collapse = ", ")
  
  return(output)
}

# Example usage:
if (!interactive() && !isTRUE(getOption("sourced"))) {
  # Get command line arguments
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) >= 2) {
    address <- args[1]
    radius_mi <- as.numeric(args[2])
    vertices <- if (length(args) >= 3) as.numeric(args[3]) else 20
    
    result <- address_circle(address, radius_mi, vertices)
    cat(result, "\n")
  } else {
    cat("Usage: Rscript circle_coords.R '<address>' <radius_mi> [vertices]\n")
    cat("Example: Rscript circle_coords.R '1600 Pennsylvania Avenue NW, Washington, DC' 1 20\n")
  }
}
