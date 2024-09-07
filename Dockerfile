# Use Ubuntu as the base image
FROM ubuntu:24.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    handbrake-cli \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Copy the encoding script and preset file
COPY encode.sh /app/
COPY presets.json /app/

# Make the script executable
RUN chmod +x /app/encode.sh

# Set the entrypoint to the encoding script
ENTRYPOINT ["/app/encode.sh"]