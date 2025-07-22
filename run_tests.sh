#!/bin/bash

# Exit on error
set -e

# Function to run tests for a service
run_service_tests() {
    service=$1
    echo "Running tests for $service service..."
    cd services/$service
    pytest tests/
    cd ../..
}

# Run tests for each service
for service in content auth assessment notifier tutor_chat; do
    run_service_tests $service
done 