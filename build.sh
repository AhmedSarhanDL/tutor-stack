#!/bin/bash

# Exit on error
set -e

echo "Building base image..."
docker build -t tutor-stack-base:latest -f Dockerfile.base .

echo "Building service images..."
docker compose build

echo "All images built successfully!" 