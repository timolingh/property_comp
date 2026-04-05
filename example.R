# Example R script showing how to use address_circle() function

# Load the function
source("circle_coords.R")

# Example 1: Simple usage with default vertices (20)
cat("Example 1: Basic usage\n")
result1 <- address_circle(
  address = "1 Apple Park Way, Cupertino, CA",
  radius_mi = 0.5
)
cat(result1, "\n\n")

# Example 2: Custom number of vertices
cat("Example 2: With custom vertices\n")
result2 <- address_circle(
  address = "Times Square, New York, NY",
  radius_mi = 1,
  vertices = 30
)
cat(result2, "\n\n")

# Example 3: Larger radius
cat("Example 3: Larger radius\n")
result3 <- address_circle(
  address = "Space Needle, Seattle, WA",
  radius_mi = 2,
  vertices = 16
)
cat(result3, "\n\n")

# Example 4: Save to file
cat("Example 4: Save to CSV\n")
result4 <- address_circle(
  address = "Statue of Liberty, New York, NY",
  radius_mi = 1.5
)

# Parse output and save as CSV
coords_str <- result4
coords_pairs <- strsplit(coords_str, ", ")[[1]]
coords_df <- data.frame(
  lon = sapply(coords_pairs, function(x) as.numeric(strsplit(x, " ")[[1]][1])),
  lat = sapply(coords_pairs, function(x) as.numeric(strsplit(x, " ")[[1]][2]))
)
write.csv(coords_df, "circle_coordinates.csv", row.names = FALSE)
cat("Saved to circle_coordinates.csv\n")

# -------------------------------------------------------------------------
# Example 5: Full end-to-end workflow (generate polygon + housing search)
# -------------------------------------------------------------------------
cat("Example 5: Full workflow (polygon -> housing API)\n")

# Load the full workflow functions (won't execute CLI section when sourced interactively)
source("workflow.R")

# Ensure results directory exists
if (!dir.exists("results")) dir.create("results", recursive = TRUE)

# Use API key from environment if available
api_key <- Sys.getenv("RAPIDAPI_KEY")
if (api_key == "") {
  cat("RAPIDAPI_KEY not set; skipping full workflow example.\n")
} else {
  result <- property_search_by_address(
    address = "Times Square, New York, NY",
    radius_mi = 1,
    api_key = api_key,
    status_type = "RecentlySold",
    min_price = 100000,
    max_price = 1000000,
    max_pages = 1
  )

  if (!is.null(result$properties) && nrow(result$properties) > 0) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    csv_file <- file.path("results", paste0("example_housing_results_", timestamp, ".csv"))
    write.csv(result$properties, csv_file, row.names = FALSE)
    polygon_file <- file.path("results", paste0("example_polygon_", timestamp, ".txt"))
    writeLines(result$polygon, polygon_file)
    cat("Full workflow completed. Results saved to:", csv_file, "and", polygon_file, "\n")
  } else {
    cat("Full workflow completed. No properties found.\n")
  }
}
