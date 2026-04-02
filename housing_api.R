# Install required packages if not already installed
required_packages <- c("httr", "jsonlite")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if (length(new_packages)) {
  options(repos = c(CRAN = "https://cran.rstudio.com/"))
  install.packages(new_packages, quietly = TRUE)
}

library(httr)
library(jsonlite)

# Define null-coalescing operator for handling NULL values
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Query US Housing Market Data API with Polygon
#'
#' Searches for properties using polygon coordinates and fetches all paginated results.
#'
#' @param polygon Character string of polygon coordinates (format: "lon1 lat1, lon2 lat2, ...")
#' @param api_key Character string of RapidAPI key
#' @param status_type Character: "ForSale", "RecentlySold", "ForRent", etc.
#' @param min_price Numeric: minimum price
#' @param max_price Numeric: maximum price
#' @param beds_min Numeric: minimum bedrooms
#' @param beds_max Numeric: maximum bedrooms
#' @param baths_min Numeric: minimum bathrooms
#' @param baths_max Numeric: maximum bathrooms
#' @param sqft_min Numeric: minimum square feet
#' @param sqft_max Numeric: maximum square feet
#' @param sold_in_last Character: time frame (e.g., "12m", "6m", "1y")
#' @param lot_size_min Character: minimum lot size (e.g., "7500 sqft")
#' @param lot_size_max Character: maximum lot size (e.g., "10 acres")
#' @param home_type Character: property home types (e.g., "Houses, Apartments")
#' @param max_pages Numeric: maximum number of pages to fetch (NULL for all pages)
#' @param verbose Logical: print progress messages
#'
#' @return Data frame with all property results from all pages
#'
#' @examples
#' \dontrun{
#'   coords <- address_circle("Times Square, NY", 1, 20)
#'   results <- search_housing_by_polygon(
#'     polygon = coords,
#'     api_key = Sys.getenv("RAPIDAPI_KEY"),
#'     status_type = "RecentlySold",
#'     min_price = 100000,
#'     max_price = 2000000
#'   )
#' }
#'
#' @export
search_housing_by_polygon <- function(
    polygon,
    api_key,
    status_type = NULL,
    min_price = NULL,
    max_price = NULL,
    beds_min = NULL,
    beds_max = NULL,
    baths_min = NULL,
    baths_max = NULL,
    sqft_min = NULL,
    sqft_max = NULL,
    sold_in_last = NULL,
    lot_size_min = NULL,
    lot_size_max = NULL,
    home_type = NULL,
    max_pages = NULL,
    verbose = TRUE) {

  # Validate inputs
  if (!is.character(polygon) || length(polygon) != 1) {
    stop("polygon must be a single character string")
  }
  if (!is.character(api_key) || length(api_key) != 1) {
    stop("api_key must be a single character string")
  }

  # API endpoint
  url <- "https://us-housing-market-data1.p.rapidapi.com/propertyExtendedSearch"
  api_host <- "us-housing-market-data1.p.rapidapi.com"

  # Initialize results storage
  all_results <- NULL
  page <- 1
  total_pages <- if (!is.null(max_pages) && max_pages > 0) max_pages else Inf

  # Fetch pages until no more results or max_pages reached
  while (page <= total_pages) {
    if (verbose) {
          cat("Fetching page", page, "...")
    }

    # Build query parameters (skip NULL values)
    query_params <- list(
      page = as.character(page)
    )
    
    if (!is.null(status_type)) query_params$status_type <- status_type
    if (!is.null(home_type)) query_params$home_type <- home_type
    query_params$polygon <- polygon
    if (!is.null(min_price)) query_params$minPrice <- as.character(min_price)
    if (!is.null(max_price)) query_params$maxPrice <- as.character(max_price)
    if (!is.null(beds_min)) query_params$bedsMin <- as.character(beds_min)
    if (!is.null(beds_max)) query_params$bedsMax <- as.character(beds_max)
    if (!is.null(baths_min)) query_params$bathsMin <- as.character(baths_min)
    if (!is.null(baths_max)) query_params$bathsMax <- as.character(baths_max)
    if (!is.null(sqft_min)) query_params$sqftMin <- as.character(sqft_min)
    if (!is.null(sqft_max)) query_params$sqftMax <- as.character(sqft_max)
    if (!is.null(sold_in_last)) query_params$soldInLast <- sold_in_last
    if (!is.null(lot_size_min)) query_params$lotSizeMin <- lot_size_min
    if (!is.null(lot_size_max)) query_params$lotSizeMax <- lot_size_max

    # Print API payload for debugging
    if (verbose && page == 1) {
      cat("\nAPI Payload:\n")
      cat("URL:", url, "\n")
      cat("Parameters:\n")
      for (param_name in names(query_params)) {
        param_value <- query_params[[param_name]]
        if (param_name == "polygon") {
          # Truncate polygon for readability
          param_value <- paste0(substring(param_value, 1, 60), "...")
        }
        cat("  ", param_name, ": ", param_value, "\n", sep = "")
      }
      cat("\n")
    }

    # Make API request
    tryCatch({
      response <- VERB(
        "GET",
        url,
        query = query_params,
        add_headers(
          'x-rapidapi-key' = api_key,
          'x-rapidapi-host' = api_host
        ),
        content_type("application/json"),
        timeout(60)
      )

      # Check response status
      if (http_error(response)) {
        status_code <- status_code(response)
        error_msg <- content(response, "text")
        stop("API error (", status_code, "): ", error_msg)
      }

      # Parse response
      response_data <- fromJSON(
        content(response, "text"),
        simplifyDataFrame = FALSE,
        simplifyMatrix = FALSE
      )

      # Extract properties (API uses "props" field)
      if (!is.null(response_data$props) && length(response_data$props) > 0) {
        # Convert each property to data frame with consistent columns
        page_results <- do.call(rbind, lapply(response_data$props, function(prop) {
          data.frame(
            address = as.character(prop$address %||% ""),
            bedrooms = as.numeric(prop$bedrooms %||% NA),
            bathrooms = as.numeric(prop$bathrooms %||% NA),
            livingArea = as.numeric(prop$livingArea %||% NA),
            lotAreaValue = as.numeric(prop$lotAreaValue %||% NA),
            lotAreaUnit = as.character(prop$lotAreaUnit %||% ""),
            price = as.numeric(prop$price %||% NA),
            propertyType = as.character(prop$propertyType %||% ""),
            latitude = as.numeric(prop$latitude %||% NA),
            longitude = as.numeric(prop$longitude %||% NA),
            brokerName = as.character(prop$brokerName %||% ""),
            listingStatus = as.character(prop$listingStatus %||% ""),
            dateSold = as.numeric(prop$dateSold %||% NA),
            daysOnZillow = as.numeric(prop$daysOnZillow %||% NA),
            zestimate = as.numeric(prop$zestimate %||% NA),
            rentZestimate = as.numeric(prop$rentZestimate %||% NA),
            zpid = as.character(prop$zpid %||% ""),
            detailUrl = as.character(prop$detailUrl %||% ""),
            stringsAsFactors = FALSE
          )
        }))

        if (verbose) {
          cat(" found", nrow(page_results), "properties\n")
        }

        # Append to results
        if (is.null(all_results)) {
          all_results <- page_results
        } else {
          # Bind rows (fill missing columns with NA)
          all_results <- rbind.data.frame(
            all_results,
            page_results,
            stringsAsFactors = FALSE,
            make.row.names = FALSE
          )
        }

        # Update total pages from response metadata, respecting max_pages limit
        api_total_pages <- NULL
        if (!is.null(response_data$totalPages)) {
          api_total_pages <- response_data$totalPages
        }
        
        if (!is.null(api_total_pages)) {
          if (!is.null(max_pages) && max_pages > 0) {
            total_pages <- min(api_total_pages, max_pages)
          } else {
            total_pages <- api_total_pages
          }
        }

        page <- page + 1
      } else {
        # No properties found
        if (verbose) {
          cat(" no properties found\n")
        }
        break
      }

    }, error = function(e) {
      stop("Request error on page ", page, ": ", conditionMessage(e))
    })

    # Small delay between requests to avoid rate limiting
    Sys.sleep(0.5)
  }

  if (verbose) {
    cat("Total results:", nrow(all_results), "properties\n")
  }

  return(all_results)
}

# Run as command line script
if (!interactive() && !isTRUE(getOption("sourced"))) {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) < 2) {
    cat("Usage: Rscript housing_api.R '<polygon_coords>' '<api_key>' [status_type] [min_price] [max_price]\n")
    cat("Example: Rscript housing_api.R 'lon1 lat1, lon2 lat2, ...' 'your_api_key' 'RecentlySold' 100000 2000000\n")
    quit(save = "no", status = 1)
  }

  polygon <- args[1]
  api_key <- args[2]
  status_type <- if (length(args) >= 3) args[3] else "RecentlySold"
  min_price <- if (length(args) >= 4) as.numeric(args[4]) else 10000
  max_price <- if (length(args) >= 5) as.numeric(args[5]) else 2000000

  cat("Search Parameters:\n")
  cat("Status Type:", status_type, "\n")
  cat("Price Range: $", min_price, " - $", max_price, "\n")
  cat("Polygon: ", substr(polygon, 1, 50), "...\n\n", sep = "")

  # Source the circle_coords.R to get the address_circle function if needed
  if (file.exists("circle_coords.R")) {
    source("circle_coords.R")
  }

  # Perform search
  results <- search_housing_by_polygon(
    polygon = polygon,
    api_key = api_key,
    status_type = status_type,
    min_price = min_price,
    max_price = max_price,
    verbose = TRUE
  )

  # Display results summary
  if (!is.null(results) && nrow(results) > 0) {
    cat("\n=== Results Summary ===\n")
    cat("Total Properties Found:", nrow(results), "\n")
    cat("\nColumn Names:\n")
    print(colnames(results))
    cat("\nFirst few results:\n")
    print(head(results, 3))

    # Save to CSV
    output_file <- paste0("housing_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    write.csv(results, output_file, row.names = FALSE)
    cat("\nResults saved to:", output_file, "\n")
  } else {
    cat("No results found.\n")
  }
}
