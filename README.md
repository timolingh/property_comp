# Property Comparison - Circle Coordinates Generator

R function to generate circular polygon coordinates around a geocoded address.

## Usage

### Option 1: Run with Docker Compose (Recommended)

**Build the image:**
```bash
docker-compose build
```

**Run the function:**
```bash
docker-compose run --rm circle-coords "1600 Pennsylvania Avenue NW, Washington, DC" 1 20
```

**Parameters:**
- `address` (required): The street address to geocode
- `radius_mi` (required): Radius in miles
- `vertices` (optional): Number of vertices for the circle (default: 20)

**Examples:**
```bash
# 1 mile radius around the White House with 20 vertices
docker-compose run --rm circle-coords "1600 Pennsylvania Avenue NW, Washington, DC" 1

# 2 mile radius with 30 vertices
docker-compose run --rm circle-coords "1600 Pennsylvania Avenue NW, Washington, DC" 2 30

# With variables
docker-compose run --rm circle-coords "$ADDRESS" "$RADIUS" "$VERTICES"
```

### Option 2: Run with Docker directly

```bash
docker build -t property_comp .
docker run --rm property_comp "1600 Pennsylvania Avenue NW, Washington, DC" 1 20
```

### Option 3: Run locally with R

Requires packages: `tidygeocoder`, `geosphere`

```R
source("circle_coords.R")
result <- address_circle("1600 Pennsylvania Avenue NW, Washington, DC", radius_mi = 1, vertices = 20)
print(result)
```

## Output Format

The function returns coordinates as a comma-separated string:
```
lon1 lat1, lon2 lat2, lon3 lat3, ..., lonN latN, lon1 lat1
```

The final coordinate pair matches the first, completing the circle polygon.

## Example Output

```
-77.036522 38.897676, -77.030612 38.903721, -77.023105 38.905644, ..., -77.036522 38.897676
```

## Geocoding

The function uses OpenStreetMap (Nominatim) for geocoding via the `tidygeocoder` package. Internet connectivity is required.

## Function Signature

```r
address_circle(address, radius_mi, vertices = 20)
```

- `address` (character): Street address to geocode
- `radius_mi` (numeric): Radius in miles (> 0)
- `vertices` (numeric): Number of circle vertices, default 20 (must be integer ≥ 3)

Returns: Character string of coordinates in "lon lat" format, comma-separated, with closing point matching opening point.
