#!/bin/bash

# Check for images directory and proper setup for seeding

# Ensure we're in the integration-tests directory
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR" || exit 1

# Check for assets directory
ASSETS_DIR="./assets"

echo "=== IMAGE ASSETS VERIFICATION ==="
echo "Checking for assets directory at: $ASSETS_DIR"

if [ ! -d "$ASSETS_DIR" ]; then
  echo "ERROR: Assets directory does not exist!"
  echo "Creating assets directory..."
  mkdir -p "$ASSETS_DIR"
  echo "Please add image files (jpg, png, gif) to the assets directory."
  exit 1
fi

# Count image files
IMAGE_COUNT=$(find "$ASSETS_DIR" -type f -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" | wc -l)

echo "Found $IMAGE_COUNT image files in assets directory."

if [ "$IMAGE_COUNT" -eq 0 ]; then
  echo "WARNING: No image files found. Seeding will proceed without images."
  echo ""
  echo "To add test images, please copy them to: $ASSETS_DIR"
  echo "Recommended: 30 images in JPG or PNG format named 001.jpg, 002.jpg, etc."
  exit 0
fi

# Check permissions
echo "Checking file permissions..."
if [ ! -r "$ASSETS_DIR" ]; then
  echo "ERROR: Cannot read from assets directory. Please check permissions."
  echo "Run: chmod -R +r $ASSETS_DIR"
  exit 1
fi

# List first 5 images found
echo ""
echo "Example images found:"
find "$ASSETS_DIR" -type f -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" | head -n 5

echo ""
echo "Image assets verification complete. Ready for seeding."
echo "=== VERIFICATION COMPLETE ==="

exit 0