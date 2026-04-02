FROM rocker/geospatial:4.3.0

# Install additional system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install R packages (geosphere and tidygeocoder)
RUN install2.r -e tidygeocoder geosphere

# Create working directory
WORKDIR /app

# Copy the R script
COPY circle_coords.R .

# Set entrypoint to R
ENTRYPOINT ["Rscript", "circle_coords.R"]
