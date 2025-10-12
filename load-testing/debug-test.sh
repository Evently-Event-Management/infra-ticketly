#!/bin/bash

# This script runs k6 debug tests for the Ticketly API

# Create output directory if it doesn't exist
mkdir -p output

# Set output format to include JSON and standard output
K6_OUT="json=output/debug-results.json"

echo "🔍 Starting debug test with detailed logging"
echo "⏱️  $(date)"

# Run k6 test with debug scenario
k6 run --env SCENARIO=debug --env ENV=local \
  --out $K6_OUT \
  --http-debug=full \
  --console-output=output/debug-log.txt \
  src/main.js

echo "✅ Debug test completed"
echo "⏱️  $(date)"
echo "📊 Results saved to output directory"