#!/bin/bash

# Helper script to run the circle_coords function via Docker Compose
# Usage: ./run_circle.sh "<address>" <radius_mi> [vertices]

if [ $# -lt 2 ]; then
    echo "Usage: ./run_circle.sh '<address>' <radius_mi> [vertices]"
    echo ""
    echo "Examples:"
    echo "  ./run_circle.sh '1600 Pennsylvania Avenue NW, Washington, DC' 1"
    echo "  ./run_circle.sh '1600 Pennsylvania Avenue NW, Washington, DC' 2 30"
    exit 1
fi

ADDRESS="$1"
RADIUS_MI="$2"
VERTICES="${3:-20}"

echo "Generating circle coordinates..."
echo "Address: $ADDRESS"
echo "Radius (mi): $RADIUS_MI"
echo "Vertices: $VERTICES"
echo ""

docker-compose run --rm circle-coords "$ADDRESS" "$RADIUS_MI" "$VERTICES"
