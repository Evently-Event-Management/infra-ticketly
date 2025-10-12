#!/bin/bash

# Simple k6 test runner for Ticketly API
# Exit on error
set -e

# Create output directory if it doesn't exist
mkdir -p output

# Default values
SCENARIO=""
ENVIRONMENT="local"

# Function to print usage information
function print_usage {
  echo "Usage: $0 [scenario] [environment]"
  echo ""
  echo "Options:"
  echo "  scenario    Test scenario (smoke|load|stress|soak|spike|breakpoint|debug)"
  echo "              If not specified, all scenarios will run sequentially"
  echo "  environment Environment (local|dev|staging|prod) [default: local]"
  echo ""
  echo "Examples:"
  echo "  $0                  # Run all scenarios sequentially against local environment"
  echo "  $0 load             # Run load scenario against local environment"
  echo "  $0 smoke prod       # Run smoke tests against production environment"
  exit 1
}

# Process command line arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  print_usage
fi

# First argument is the scenario (optional)
if [[ -n "$1" ]]; then
  SCENARIO="$1"
  
  # Validate scenario if provided
  if [[ ! "$SCENARIO" =~ ^(smoke|load|stress|soak|spike|breakpoint|debug)$ ]]; then
    echo "ERROR: Invalid scenario: $SCENARIO"
    print_usage
  fi
fi

# Second argument is the environment (optional)
if [[ -n "$2" ]]; then
  ENVIRONMENT="$2"
  
  # Validate environment
  if [[ ! "$ENVIRONMENT" =~ ^(local|dev|staging|prod)$ ]]; then
    echo "ERROR: Invalid environment: $ENVIRONMENT"
    print_usage
  fi
fi

# Create timestamp for unique output files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="output/test_${ENVIRONMENT}_${TIMESTAMP}.json"

# Display banner
echo "+--------------------------------------------------+"
echo "|             TICKETLY LOAD TEST RUNNER            |"
echo "+--------------------------------------------------+"
echo ""

# Set the scenario environment variable for k6 if specified
if [[ -n "$SCENARIO" ]]; then
  echo ">> Running $SCENARIO scenario against $ENVIRONMENT environment"
  echo ">> Time: $(date)"
  echo ">> Results will be saved to $OUTPUT_FILE"
  echo ""
  
  # Run k6 test with specific scenario
  echo ">> Starting k6 test..."
  k6 run \
    --out json=$OUTPUT_FILE \
    --env ENV=$ENVIRONMENT \
    --env SCENARIO=$SCENARIO \
    --env ONLY_SCENARIO=$SCENARIO \
    src/main.js
else
  # Run all test scenarios sequentially when no scenario is specified
  echo ">> Running all scenarios sequentially against $ENVIRONMENT environment"
  echo ">> Time: $(date)"
  echo ""
  
  # Define all available scenarios
  SCENARIOS=("smoke" "load" "stress" "soak" "spike" "breakpoint" "debug")
  
  # Run each scenario one by one
  for scenario in "${SCENARIOS[@]}"; do
    # Create unique output file for each scenario
    SCENARIO_OUTPUT_FILE="output/${scenario}_${ENVIRONMENT}_${TIMESTAMP}.json"
    
    echo ""
    echo ">> Starting $scenario scenario..."
    echo ">> Results will be saved to $SCENARIO_OUTPUT_FILE"
    
    k6 run \
      --out json=$SCENARIO_OUTPUT_FILE \
      --env ENV=$ENVIRONMENT \
      --env SCENARIO=$scenario \
      --env ONLY_SCENARIO=$scenario \
      src/main.js
      
    echo ">> Completed $scenario scenario"
  done
fi

echo ">> Test completed"
echo ">> Time: $(date)"
echo ">> Results saved to $OUTPUT_FILE"