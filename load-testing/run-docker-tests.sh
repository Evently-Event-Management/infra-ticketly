#!/bin/bash

# This script creates a Docker container with k6 and runs load tests

# Exit on error
set -e

# Default values
SCENARIO="smoke"
ENVIRONMENT="local"

# Print usage
function print_usage {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -s, --scenario    Test scenario (smoke|load|stress|soak|spike|breakpoint) [default: smoke]"
  echo "  -e, --env         Environment (local|dev|staging|prod) [default: local]"
  echo "  -h, --help        Print this help message"
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--scenario)
      SCENARIO="$2"
      shift 2
      ;;
    -e|--env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      ;;
  esac
done

# Create output directory with correct permissions
mkdir -p output
chmod 777 output

# Run k6 in Docker
docker run --rm \
  -v ${PWD}:/app \
  -w /app \
  --network=host \
  grafana/k6:latest \
  run --env SCENARIO=$SCENARIO --env ENV=$ENVIRONMENT \
  --out json=output/results-${SCENARIO}-${ENVIRONMENT}.json \
  src/main.js

echo "✅ Load test completed"
echo "📊 Results saved to output/results-${SCENARIO}-${ENVIRONMENT}.json"