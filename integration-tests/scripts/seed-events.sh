#!/bin/bash

# Display help message
function show_help {
  echo "Ticketly Seeding Tool"
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help           Display this help message"
  echo "  -c, --clean          Clean up previously seeded data"
  echo "  -e, --env ENV        Use specific environment (dev, prod, seed)"
  echo "  -t, --test-upload    Test image upload functionality only"
  echo "  -v, --verify         Verify images only"
  echo ""
  exit 0
}

# Default options
ACTION="seed"
ENV="dev"
VERIFY_ONLY=false
TEST_UPLOAD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      ;;
    -c|--clean)
      ACTION="clean"
      shift
      ;;
    -e|--env)
      ENV="$2"
      shift 2
      ;;
    -v|--verify)
      VERIFY_ONLY=true
      shift
      ;;
    -t|--test-upload)
      TEST_UPLOAD=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Set NODE_ENV
export NODE_ENV=$ENV
echo "Using environment: $NODE_ENV"

# Verify images
echo "Verifying image assets..."
./scripts/verify-images.sh
if [ $? -ne 0 ]; then
  echo "Error: Image verification failed. Please ensure image assets are available."
  exit 1
fi

# If verify only, exit after verification
if [ "$VERIFY_ONLY" = true ]; then
  echo "Image verification completed successfully."
  exit 0
fi

# If test upload, run the test script
if [ "$TEST_UPLOAD" = true ]; then
  echo "Testing image upload functionality..."
  node ./scripts/test-image-upload.js
  exit $?
fi

# Execute appropriate action
if [ "$ACTION" = "seed" ]; then
  echo "Starting seeding process..."
  npx ts-node src/seeding/seed.ts
elif [ "$ACTION" = "clean" ]; then
  echo "Starting cleanup process..."
  npx ts-node src/seeding/cleanup.ts
else
  echo "Invalid action: $ACTION"
  exit 1
fi