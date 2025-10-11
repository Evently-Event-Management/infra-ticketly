#!/bin/bash

# This script runs k6 load tests for the Ticketly API

# Exit on error
set -e

# Default values
SCENARIO="smoke"
ENVIRONMENT="local"
K6_OUT="json=output/results.json,csv=output/results.csv"
K6_VUIS=10
K6_DURATION="30s"

# Print usage
function print_usage {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -s, --scenario    Test scenario (smoke|load|stress|soak|spike|breakpoint) [default: smoke]"
  echo "  -e, --env         Environment (local|dev|staging|prod) [default: local]"
  echo "  -o, --output      K6 output format [default: json=output/results.json,csv=output/results.csv]"
  echo "  -v, --vus         Number of virtual users for custom runs [default: 10]"
  echo "  -d, --duration    Duration for custom runs [default: 30s]"
  echo "  -h, --help        Print this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --scenario load --env dev"
  echo "  $0 -s stress -e staging"
  echo "  $0 --vus 50 --duration 2m"
  exit 1
}

# Create output directory if it doesn't exist
mkdir -p output

# Ensure output directory has proper permissions
chmod 755 output

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
    -o|--output)
      K6_OUT="$2"
      shift 2
      ;;
    -v|--vus)
      K6_VUIS="$2"
      shift 2
      ;;
    -d|--duration)
      K6_DURATION="$2"
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

# Validate scenario
if [[ ! "$SCENARIO" =~ ^(smoke|load|stress|soak|spike|breakpoint)$ ]]; then
  echo "Invalid scenario: $SCENARIO"
  print_usage
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(local|dev|staging|prod)$ ]]; then
  echo "Invalid environment: $ENVIRONMENT"
  print_usage
fi

echo "🚀 Starting $SCENARIO load test against $ENVIRONMENT environment"
echo "⏱️  $(date)"

# Run k6 test
if [[ "$SCENARIO" == "custom" ]]; then
  k6 run --vus $K6_VUIS --duration $K6_DURATION --env ENV=$ENVIRONMENT src/main.js
else
  k6 run --env SCENARIO=$SCENARIO --env ENV=$ENVIRONMENT src/main.js
fi

echo "✅ Load test completed"
echo "⏱️  $(date)"
echo "📊 Results saved to output directory"