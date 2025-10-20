#!/bin/bash

# Ticketly Event Seeding Script
# Usage: ./seed-events.sh [command]
#   Commands:
#     seed     - Seed the system with events (default)
#     cleanup  - Clean up seeded events
#     help     - Show this help message

SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR" || exit 1

# Get command line arguments
COMMAND=${1:-"help"}
SEED_DATA_FILE=${2:-""}

# Set environment
ENV=${ENV:-"seed"}

# Build the project first
echo "Building project..."
npm run build

case $COMMAND in
  seed)
    echo "=== SEEDING EVENTS ==="
    echo "Using environment: $ENV"
    
    # Verify images before seeding
    ./verify-images.sh
    if [ $? -ne 0 ]; then
      echo "Image verification failed. Please check the assets directory."
      echo "You can continue without images or fix the issues and try again."
      read -p "Continue without images? (y/n): " continue_seeding
      if [[ ! $continue_seeding =~ ^[Yy]$ ]]; then
        echo "Seeding aborted."
        exit 1
      fi
    fi
    
    ENV="$ENV" node -r ./register-paths.js dist/index.js seed
    ;;
  
  cleanup)
    echo "=== CLEANING UP SEEDED DATA ==="
    echo "Using environment: $ENV"
    if [ -n "$SEED_DATA_FILE" ]; then
      ENV="$ENV" node -r ./register-paths.js dist/index.js cleanup "$SEED_DATA_FILE"
    else
      ENV="$ENV" node -r ./register-paths.js dist/index.js cleanup
    fi
    ;;
  
  help|*)
    echo "Ticketly Event Seeding Script"
    echo "Usage: ./seed-events.sh [command]"
    echo ""
    echo "Commands:"
    echo "  seed     - Seed the system with events"
    echo "  cleanup  - Clean up seeded events"
    echo "  help     - Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ENV      - Environment to use (dev, prod, seed). Default: seed"
    echo ""
    echo "Examples:"
    echo "  ./seed-events.sh seed             # Seed using default environment"
    echo "  ENV=dev ./seed-events.sh seed     # Seed using dev environment"
    echo "  ./seed-events.sh cleanup          # Cleanup using default seed data file"
    echo "  ./seed-events.sh cleanup path/to/seed-data.json  # Cleanup using specific seed data file"
    ;;
esac
