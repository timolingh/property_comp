# Property Comparison - Circle Coordinates Generator & Housing API Integration

Generate circular polygon coordinates around a geocoded address, then search for properties within that polygon using the US Housing Market Data API.

## Features

- **Geocoding**: Converts addresses to coordinates using OpenStreetMap
- **Circle Generation**: Creates smooth polygon coordinates around a point
- **API Integration**: Searches housing market data within the polygon
- **Pagination Handling**: Automatically fetches all pages of results
- **Configuration-Driven**: All parameters via config.json and .env
- **Docker Containerization**: Run everything in isolated containers
- **Flexible Filtering**: Comprehensive property search filters (price, beds, baths, sqft, lot size, etc.)

---
## Quick Start

1. **Setup:**
   ```bash
   cp .env.sample .env
   # Edit .env and set RAPIDAPI_KEY
   docker compose build
   ```

2. **Configure search:**
   Edit `config.json` with your desired parameters

3. **Run:**
   ```bash
   docker compose run --rm housing-api
   ```

4. **Check results:**
   ```bash
   ls -la results/
   ```

---

## Configuration

### config.json

All search parameters are configured in `config.json`:

```json
{
  "address": "1017 Magnolia St, South Pasadena, CA 91030",
  "radius_mi": 10,
  "vertices": 20,
  "status_type": "RecentlySold",
  "home_type": "Houses, Apartments, Condos",
  "min_price": 1000000,
  "max_price": 2000000,
  "beds_min": 1,
  "beds_max": null,
  "baths_min": 1,
  "baths_max": null,
  "sqft_min": 1000,
  "sqft_max": null,
  "sold_in_last": "12m",
  "lot_size_min": "7500 sqft",
  "lot_size_max": "10 acres",
  "max_pages": 1,
  "api_key": "env"
}
```

**Parameters:**
- `address`: Street address to search around
- `radius_mi`: Search radius in miles
- `vertices`: Number of polygon vertices (default: 20)
- `status_type`: Property status ("RecentlySold", "ForSale", "ForRent")
- `home_type`: Property types ("Houses, Apartments, Condos", "Townhomes", etc.)
- `min_price`/`max_price`: Price range in dollars
- `beds_min`/`beds_max`: Bedroom count range (set to `null` to skip filter)
- `baths_min`/`baths_max`: Bathroom count range (set to `null` to skip filter)
- `sqft_min`/`sqft_max`: Square footage range (set to `null` to skip filter)
- `sold_in_last`: Time frame for recently sold ("12m", "6m", "1y", etc.)
- `lot_size_min`/`lot_size_max`: Lot size range ("7500 sqft", "10 acres", etc.)
- `max_pages`: Maximum pages to fetch (set to `null` for all pages)
- `api_key`: Set to "env" to read from RAPIDAPI_KEY environment variable

### .env File

Set your RapidAPI key:
```bash
RAPIDAPI_KEY=your_api_key_here
```

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

Generate circle coordinates:
```bash
docker compose run --rm circle-coords "1600 Pennsylvania Avenue NW, Washington, DC" 1 20
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
  verbose = TRUE
)
```

**Parameters:**
- `polygon` (character): Polygon coordinates from `address_circle()` output
- `api_key` (character): RapidAPI key for authentication
- `status_type` (character): "ForSale", "RecentlySold", "ForRent", etc. (NULL = no filter)
- `min_price`, `max_price` (numeric): Price range filters (NULL = no filter)
- `beds_min`, `beds_max`, `baths_min`, `baths_max` (numeric): Bed/bath filters (NULL = no filter)
- `sqft_min`, `sqft_max` (numeric): Square footage filters (NULL = no filter)
- `sold_in_last` (character): Time frame ("12m", "6m", "1y", etc.) (NULL = no filter)
- `lot_size_min`, `lot_size_max` (character): Lot size filters ("7500 sqft", "10 acres", etc.) (NULL = no filter)
- `home_type` (character): Property types (e.g., "Houses, Apartments, Condos", "Townhomes", etc.) (NULL = no filter)
- `max_pages` (numeric): Maximum pages to fetch (NULL = fetch all pages)
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
  ...
)
```

**Returns:** List containing:
- `polygon`: Generated coordinates string
- `properties`: Data frame of results

### Usage

**Via Docker Compose (Recommended)**

1. Set your API key in `.env`
2. Edit `config.json` with your search parameters
3. Run the workflow:
```bash
docker compose run --rm housing-api
```

Results are saved to `results/` directory as timestamped CSV files.

---

## Docker Usage

### Build
```bash
docker compose build
```

### Available Services

**1. Generate Circle Coordinates**
```bash
docker compose run --rm circle-coords "<address>" <radius_mi> [vertices]
```

**2. Complete Workflow (Recommended)**
```bash
docker compose run --rm housing-api
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
├── config.json           # Search configuration parameters
├── .env                  # API key (copy from .env.sample)
├── .env.sample           # API key template
├── .gitignore            # Git ignore rules
├── docker compose.yml    # Container orchestration
├── Dockerfile            # Container definition
├── property_search.sh    # Convenience script
├── run_circle.sh         # Circle generation script
├── results/              # Output directory (created automatically)
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

### Example 1: Search for Recently Sold Homes around South Pasadena

Current `config.json` searches for recently sold homes within 10 miles of South Pasadena:

```json
{
  "address": "1017 Magnolia St, South Pasadena, CA 91030",
  "radius_mi": 10,
  "vertices": 20,
  "status_type": "RecentlySold",
  "home_type": "Houses, Apartments, Condos",
  "min_price": 1000000,
  "max_price": 2000000,
  "beds_min": 1,
  "beds_max": null,
  "baths_min": 1,
  "baths_max": null,
  "sqft_min": 1000,
  "sqft_max": null,
  "sold_in_last": "12m",
  "lot_size_min": "7500 sqft",
  "lot_size_max": "10 acres",
  "max_pages": 1,
  "api_key": "env"
}
```

Run:
```bash
docker compose run --rm housing-api
```

### Example 2: Find Properties for Sale in Cupertino

Edit `config.json`:
```json
{
  "address": "1 Apple Park Way, Cupertino, CA",
  "radius_mi": 2,
  "status_type": "ForSale",
  "min_price": 1000000,
  "max_price": 5000000,
  "beds_min": 2,
  "beds_max": 5,
  "baths_min": 2,
  "baths_max": 4,
  "sqft_min": 1500,
  "sqft_max": 4000,
  "max_pages": null,
  "api_key": "env"
}
```

Run:
```bash
docker compose run --rm housing-api
```

---

## Troubleshooting

### Geocoding Error
- Ensure the address format is valid (street, city, state or zip)
- Check internet connection
- Try a different address format

### API Errors
- Verify API key is correct in `.env`
- Check RapidAPI subscription is active
- Review rate limits (free tier has restrictions)
- Ensure polygon format is correct (lon/lat pairs)

### No Results
- Check that your search criteria aren't too restrictive
- Verify the address geocodes correctly
- Try increasing the search radius
- Set restrictive filters to `null` to remove them

### Docker Issues
- Run `docker compose build --no-cache` to rebuild from scratch
- Check Docker daemon is running
- Verify disk space for image

---

## API Response Format

The API returns properties with these fields:
- `address`: Full property address
- `bedrooms`/`bathrooms`: Room counts
- `livingArea`: Square footage
- `lotAreaValue`/`lotAreaUnit`: Lot size
- `price`: Sale/listing price
- `propertyType`: Property type (SINGLE_FAMILY, CONDO, etc.)
- `latitude`/`longitude`: Coordinates
- `brokerName`: Listing broker
- `listingStatus`: Status (RECENTLY_SOLD, etc.)
- `dateSold`: Sale date (Unix timestamp)
- `zestimate`/`rentZestimate`: Zillow estimates
- `zpid`: Zillow property ID
- `detailUrl`: Zillow detail page URL

## References

- [RapidAPI US Housing Market Data](https://rapidapi.com/apimaker/api/us-housing-market-data1)
- [tidygeocoder Documentation](https://jessecambon.github.io/tidygeocoder/)
- [geosphere Package](https://cran.r-project.org/web/packages/geosphere/)
