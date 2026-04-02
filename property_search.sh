#!/bin/bash

# Complete property search workflow script
# Usage: ./property_search.sh [config.json]

set -e

# Load .env file if available
if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
fi

CONFIG_FILE=${1:-config.json}

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file '$CONFIG_FILE' not found."
  echo "Create config.json with search parameters, or pass path via argument." 
  exit 1
fi

# Ensure results path exists
mkdir -p results

echo "================================================"
echo "Property Market Search Workflow"
echo "================================================"
echo "Config file: $CONFIG_FILE"
echo "RAPIDAPI_KEY: ${RAPIDAPI_KEY:-(not set)}"
echo ""

# Run the workflow in R using config file
Rscript workflow.R --config="$CONFIG_FILE"

echo ""
echo "================================================"
echo "Search Complete!"
echo "Check the results/ directory for output files"
echo "================================================"
