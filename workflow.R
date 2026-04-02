# Complete workflow: Generate circle coordinates and query housing API
# This script combines address_circle() and search_housing_by_polygon()

library(jsonlite)
# Mark scripts as sourced to prevent CLI handling execution
options(sourced = TRUE)
source("circle_coords.R")
source("housing_api.R")

load_search_config <- function(config_path = "config.json") {
  if (!file.exists(config_path)) {
    stop("Config file not found: ", config_path)
  }

  config <- fromJSON(config_path)
  return(config)
}

#' End-to-End Property Search around an Address
#'
#' Generates circle coordinates and searches for properties within that polygon.
#'
#' @param address Character: street address to search around
#' @param radius_mi Numeric: search radius in miles
#' @param api_key Character: RapidAPI key
#' @param vertices Numeric: number of polygon vertices (default: 20)
#' @param status_type Character: property status ("RecentlySold", "ForSale", etc.)
#' @param min_price Numeric: minimum price
#' @param max_price Numeric: maximum price
#' @param max_pages Numeric: maximum number of pages to fetch (NULL for all pages)
#' @param ... Additional parameters passed to search_housing_by_polygon()
#'
#' @return List with circle coordinates and property results dataframe
#'
#' @examples
#' \dontrun{
#'   results <- property_search_by_address(
#'     address = "Times Square, New York, NY",
#'     radius_mi = 1,
#'     api_key = Sys.getenv("RAPIDAPI_KEY"),
#'     status_type = "RecentlySold"
#'   )
#' }
#'
#' @export
property_search_by_address <- function(
    address,
    radius_mi,
    api_key,
    vertices = NULL,
    status_type = NULL,
    min_price = NULL,
    max_price = NULL,
    beds_min = NULL,
    beds_max = NULL,
    baths_min = NULL,
    baths_max = NULL,
    sqft_min = NULL,
    sqft_max = NULL,
    home_type = NULL,
    sold_in_last = NULL,
    lot_size_min = NULL,
    lot_size_max = NULL,
    max_pages = NULL,
    ...) {

  cat("=== Property Search Workflow ===\n\n")

  # Step 1: Generate circle coordinates
  cat("Step 1: Geocoding address and generating circle polygon\n")
  cat("Address:", address, "\n")
  cat("Radius:", radius_mi, "miles\n")
  cat("Vertices:", vertices, "\n\n")

  polygon <- address_circle(address, radius_mi, vertices)
  cat("Generated polygon coordinates:\n")
  cat(substring(polygon, 1, 100), "...\n\n")

  # Step 2: Query housing API
  cat("Step 2: Querying US Housing Market Data API\n")
  cat("Status Type:", status_type, "\n")
  cat("Price Range: $", format(min_price, big.mark = ","),
      " - $", format(max_price, big.mark = ","), "\n\n", sep = "")

  properties <- search_housing_by_polygon(
    polygon = polygon,
    api_key = api_key,
    status_type = status_type,
    min_price = min_price,
    max_price = max_price,
    beds_min = beds_min,
    beds_max = beds_max,
    baths_min = baths_min,
    baths_max = baths_max,
    sqft_min = sqft_min,
    sqft_max = sqft_max,
    home_type = home_type,
    sold_in_last = sold_in_last,
    lot_size_min = lot_size_min,
    lot_size_max = lot_size_max,
    max_pages = max_pages,
    verbose = TRUE
  )

  # Step 3: Summary
  cat("\n=== Results Summary ===\n")
  if (!is.null(properties) && nrow(properties) > 0) {
    cat("Total Properties Found:", nrow(properties), "\n")
    cat("Columns:", paste(colnames(properties), collapse = ", "), "\n")
  } else {
    cat("No properties found matching criteria.\n")
  }

  # Return results
  return(list(
    polygon = polygon,
    properties = properties
  ))
}

# ============================================================================
# EXAMPLE USAGE
# ============================================================================

# Configure API key - set via environment or directly
# Sys.setenv(RAPIDAPI_KEY = "your_api_key_here")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)

  config_path <- "config.json"
  use_config <- FALSE

  if (length(args) >= 1 && grepl("^--config=", args[1])) {
    config_path <- sub("^--config=", "", args[1])
    use_config <- TRUE
  } else if (length(args) == 1 && file.exists(args[1])) {
    config_path <- args[1]
    use_config <- TRUE
  }

  if (use_config) {
    if (!file.exists(config_path)) {
      stop("Config file not found: ", config_path)
    }
    config <- load_search_config(config_path)

    address <- config$address
    radius_mi <- as.numeric(config$radius_mi)
    vertices <- if (!is.null(config$vertices)) as.integer(config$vertices) else NULL
    status_type <- if (!is.null(config$status_type)) config$status_type else NULL
    min_price <- if (!is.null(config$min_price)) as.numeric(config$min_price) else NULL
    max_price <- if (!is.null(config$max_price)) as.numeric(config$max_price) else NULL
    beds_min <- if (!is.null(config$beds_min)) as.numeric(config$beds_min) else NULL
    beds_max <- if (!is.null(config$beds_max)) as.numeric(config$beds_max) else NULL
    baths_min <- if (!is.null(config$baths_min)) as.numeric(config$baths_min) else NULL
    baths_max <- if (!is.null(config$baths_max)) as.numeric(config$baths_max) else NULL
    sqft_min <- if (!is.null(config$sqft_min)) as.numeric(config$sqft_min) else NULL
    sqft_max <- if (!is.null(config$sqft_max)) as.numeric(config$sqft_max) else NULL
    home_type <- if (!is.null(config$home_type)) config$home_type else NULL
    sold_in_last <- if (!is.null(config$sold_in_last)) config$sold_in_last else NULL
    lot_size_min <- if (!is.null(config$lot_size_min)) config$lot_size_min else NULL
    lot_size_max <- if (!is.null(config$lot_size_max)) config$lot_size_max else NULL
    max_pages <- if (!is.null(config$max_pages)) as.integer(config$max_pages) else NULL

    api_key <- if (!is.null(config$api_key) && config$api_key == "env") {
      Sys.getenv("RAPIDAPI_KEY")
    } else {
      config$api_key
    }

    if (is.null(api_key) || api_key == "") {
      stop("API key missing. Set in config.json api_key or in .env RAPIDAPI_KEY and use api_key = 'env'.")
    }

  } else {
    # Old-style argument usage
    if (length(args) < 3) {
      cat("Usage: Rscript workflow.R '<address>' <radius_mi> '<api_key>' [status_type] [min_price] [max_price]\n")
      cat("Usage with config: Rscript workflow.R --config=config.json\n")
      quit(save = "no", status = 1)
    }

    address <- args[1]
    radius_mi <- as.numeric(args[2])
    api_key_arg <- args[3]

    if (api_key_arg == "env") {
      api_key <- Sys.getenv("RAPIDAPI_KEY")
      if (api_key == "") {
        stop("RAPIDAPI_KEY environment variable not set")
      }
    } else {
      api_key <- api_key_arg
    }

    status_type <- if (length(args) >= 4) args[4] else NULL
    min_price <- if (length(args) >= 5) as.numeric(args[5]) else NULL
    max_price <- if (length(args) >= 6) as.numeric(args[6]) else NULL
    vertices <- if (length(args) >= 7) as.integer(args[7]) else NULL
    max_pages <- if (length(args) >= 8) as.integer(args[8]) else NULL
    # Additional parameters not supported in CLI mode; set to NULL
    beds_min <- NULL
    beds_max <- NULL
    baths_min <- NULL
    baths_max <- NULL
    sqft_min <- NULL
    sqft_max <- NULL
    home_type <- NULL
    sold_in_last <- NULL
    lot_size_min <- NULL
    lot_size_max <- NULL
  }

  result <- property_search_by_address(
    address = address,
    radius_mi = radius_mi,
    api_key = api_key,
    vertices = vertices,
    status_type = status_type,
    min_price = min_price,
    max_price = max_price,
    beds_min = beds_min,
    beds_max = beds_max,
    baths_min = baths_min,
    baths_max = baths_max,
    sqft_min = sqft_min,
    sqft_max = sqft_max,
    home_type = home_type,
    sold_in_last = sold_in_last,
    lot_size_min = lot_size_min,
    lot_size_max = lot_size_max,
    max_pages = max_pages
  )

  if (!is.null(result$properties) && nrow(result$properties) > 0) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    csv_file <- file.path("results", paste0("housing_results_", timestamp, ".csv"))
    write.csv(result$properties, csv_file, row.names = FALSE)
    cat("\nResults saved to:", csv_file, "\n")

    polygon_file <- file.path("results", paste0("polygon_", timestamp, ".txt"))
    writeLines(result$polygon, polygon_file)
    cat("Polygon saved to:", polygon_file, "\n")
  } else {
    cat("No results found.\n")
  }
}
