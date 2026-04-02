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
