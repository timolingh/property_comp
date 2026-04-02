# Property Comparison - Circle Coordinates Generator & Housing API Integration

Generate circular polygon coordinates around a geocoded address, then search for properties within that polygon using the US Housing Market Data API.

## Features

- **Geocoding**: Converts addresses to coordinates using OpenStreetMap
- **Circle Generation**: Creates smooth polygon coordinates around a point
- **API Integration**: Searches housing market data within the polygon
- **Pagination Handling**: Automatically fetches all pages of results
- **Docker Containerization**: Run everything in isolated containers

---

## Step 1: Generate Circle Coordinates

### Function: `address_circle()`

Converts an address into a set of circular polygon coordinates.

**Signature:**
```r
address_circle(address, radius_mi, vertices = 20)
```

**Parameters:**
- `address` (character): Street address to geocode
- `radius_mi` (numeric): Radius in miles (> 0)
- `vertices` (numeric): Number of circle vertices, default 20 (must be integer ≥ 3)

**Returns:** Character string of coordinates in "lon lat" format, comma-separated, with closing point matching opening point.

### Usage

**Via Docker Compose**

Build the image:
```bash
docker-compose build
```

Generate circle coordinates:
```bash
docker-compose run --rm circle-coords "1600 Pennsylvania Avenue NW, Washington, DC" 1 20
```

Parameters:
- `address` (required): Street address to geocode
- `radius_mi` (required): Radius in miles
- `vertices` (optional): Number of vertices (default: 20)

### Example Output

```
-77.036522 38.897676, -77.030612 38.903721, -77.023105 38.905644, ..., -77.036522 38.897676
```

---

## Step 2: Search Housing Market Data

### Function: `search_housing_by_polygon()`

Queries the US Housing Market Data API using polygon coordinates and fetches all paginated results.

**Signature:**
```r
search_housing_by_polygon(
  polygon,
  api_key,
  status_type = "RecentlySold",
  min_price = 10000,
  max_price = 2000000,
  beds_min = 1,
  beds_max = 5,
  baths_min = 1,
  baths_max = 3,
  sqft_min = 1000,
  sqft_max = 10000,
  sold_in_last = "12m",
  lot_size_min = "7500 sqft",
  lot_size_max = "10 acres",
  home_type = "Houses, Apartments, Condos",
  verbose = TRUE
)
```

**Parameters:**
- `polygon` (character): Polygon coordinates from `address_circle()` output
- `api_key` (character): RapidAPI key for authentication
- `status_type` (character): "ForSale", "RecentlySold", "ForRent", etc.
- `min_price`, `max_price` (numeric): Price range filters
- `beds_min`, `beds_max`, `baths_min`, `baths_max` (numeric): Bed/bath filters
- `sqft_min`, `sqft_max` (numeric): Square footage filters
- `sold_in_last` (character): Time frame ("12m", "6m", "1y", etc.)
- `lot_size_min`, `lot_size_max` (character): Lot size filters ("7500 sqft", "10 acres", etc.)
- `home_type` (character): Property types (e.g., "Houses, Apartments, Condos", "Townhomes", etc.)
- `verbose` (logical): Print progress messages

**Returns:** Data frame with all property results (handles all pages automatically)

### Get API Key

1. Sign up at https://rapidapi.com/
2. Subscribe to the US Housing Market Data API
3. Find your API key in the API dashboard

### Usage

Use the complete workflow (see Step 3 below) which combines both functions.

---

## Step 3: Complete Workflow

### Function: `property_search_by_address()`

Combines both steps: geocoding + circle generation + API search.

**Signature:**
```r
property_search_by_address(
  address,
  radius_mi,
  api_key,
  vertices = 20,
  status_type = "RecentlySold",
  min_price = 10000,
  max_price = 2000000,
  ...
)
```

**Returns:** List containing:
- `polygon`: Generated coordinates string
- `properties`: Data frame of results

### Usage

**Via Docker Compose (Recommended)**

1. Copy `.env.sample` to `.env` and set your API key:
```bash
cp .env.sample .env
# Edit .env and set RAPIDAPI_KEY
```

2. Edit `config.json` with your search parameters (address, radius, price range, etc.)

3. Run the workflow:
```bash
./property_search.sh config.json
```

Or directly with docker-compose:
```bash
docker-compose run --rm housing-api
```

Results are saved to `results/` directory.

---

## Docker Usage

### Build
```bash
docker-compose build
```

### Available Services

**1. Generate Circle Coordinates**
```bash
docker-compose run --rm circle-coords "<address>" <radius_mi> [vertices]
```

**2. Complete Workflow (Recommended)**
```bash
docker-compose run --rm housing-api
```
Uses `config.json` for all parameters and `.env` for API key.

### Output

Results are saved to:
- CSV files with timestamp: `housing_results_YYYYMMDD_HHMMSS.csv`
- Polygon coordinates: `polygon_YYYYMMDD_HHMMSS.txt`

---

## File Structure

```
.
├── circle_coords.R       # Circle coordinate generation function
├── housing_api.R         # Housing API query function
├── workflow.R            # Complete end-to-end workflow
├── example.R             # Usage examples
├── Dockerfile            # Container definition
├── docker-compose.yml    # Container orchestration
└── README.md            # This file
```

---

## Requirements

System:
- Docker & Docker Compose
- Internet connection (for geocoding and API calls)

Note: All R packages are installed automatically in the Docker container.

---

## Examples

### Example 1: Search for Recently Sold Homes around Apple Park

Edit `config.json`:
```json
{
  "address": "1 Apple Park Way, Cupertino, CA",
  "radius_mi": 1,
  "status_type": "RecentlySold",
  "min_price": 500000,
  "max_price": 3000000,
  "api_key": "env"
}
```

Then run:
```bash
./property_search.sh config.json
```

### Example 2: Find Properties for Sale in Times Square Area

Edit `config.json`:
```json
{
  "address": "Times Square, New York, NY",
  "radius_mi": 0.5,
  "status_type": "ForSale",
  "min_price": 100000,
  "max_price": 500000,
  "api_key": "env"
}
```

Run:
```bash
./property_search.sh config.json
```

---

## Troubleshooting

### Geocoding Error
- Ensure the address format is valid (street, city, state or zip)
- Check internet connection
- Try a different address format

### API Errors
- Verify API key is correct
- Check RapidAPI subscription is active
- Review rate limits (free tier has restrictions)
- Ensure polygon format is correct (lon/lat pairs)

### Docker Issues
- Run `docker-compose build --no-cache` to rebuild from scratch
- Check Docker daemon is running
- Verify disk space for image

---

## Quick Start

1. **Setup:**
   ```bash
   cp .env.sample .env
   # Edit .env and set RAPIDAPI_KEY
   docker-compose build
   ```

2. **Configure search:**
   Edit `config.json` with your desired parameters

3. **Run:**
   ```bash
   ./property_search.sh config.json
   ```

4. **Check results:**
   ```bash
   ls -la results/
   ```

## References

- [RapidAPI US Housing Market Data](https://rapidapi.com/apimaker/api/us-housing-market-data1)
- [tidygeocoder Documentation](https://jessecambon.github.io/tidygeocoder/)
- [geosphere Package](https://cran.r-project.org/web/packages/geosphere/)
