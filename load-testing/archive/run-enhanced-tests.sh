#!/bin/bash

# This script runs k6 load tests for the Ticketly API with enhanced error logging

# Exit on error
set -e

# Default values
SCENARIO="smoke"
ENVIRONMENT="local"
K6_OUT="json=output/results.json,csv=output/results.csv"
LOG_LEVEL="warning" # Default log level

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
    -l|--log-level)
      LOG_LEVEL="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  -s, --scenario    Test scenario (smoke|load|stress|soak|spike|breakpoint|debug) [default: smoke]"
      echo "  -e, --env         Environment (local|dev|staging|prod) [default: local]"
      echo "  -l, --log-level   Log level (debug|info|warning|error) [default: warning]"
      echo "  -h, --help        Print this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate scenario
if [[ ! "$SCENARIO" =~ ^(smoke|load|stress|soak|spike|breakpoint|debug)$ ]]; then
  echo "❌ Invalid scenario: $SCENARIO"
  exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(local|dev|staging|prod)$ ]]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  exit 1
fi

# Create timestamp for unique output files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="output/${SCENARIO}_${ENVIRONMENT}_${TIMESTAMP}.json"
LOG_FILE="output/${SCENARIO}_${ENVIRONMENT}_${TIMESTAMP}.log"

echo "🚀 Starting $SCENARIO load test against $ENVIRONMENT environment"
echo "⏱️  $(date)"
echo "📝 Log level: $LOG_LEVEL"
echo "📊 Results will be saved to $OUTPUT_FILE"
echo "📄 Logs will be saved to $LOG_FILE"

# Run k6 test with more detailed output
k6 run \
  --console-output=$LOG_FILE \
  --out="json=$OUTPUT_FILE" \
  --env SCENARIO=$SCENARIO \
  --env ENV=$ENVIRONMENT \
  src/main.js

echo "✅ Load test completed"
echo "⏱️  $(date)"
echo "📊 Results saved to $OUTPUT_FILE"
echo "📄 Logs saved to $LOG_FILE"