#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default image directory
IMAGE_DIR="./assets"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--directory)
      IMAGE_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [-d|--directory IMAGE_DIRECTORY]"
      exit 1
      ;;
  esac
done

echo "Verifying images in directory: $IMAGE_DIR"

# Check if directory exists
if [ ! -d "$IMAGE_DIR" ]; then
  echo -e "${RED}Error: Directory does not exist: $IMAGE_DIR${NC}"
  echo "Creating directory..."
  mkdir -p "$IMAGE_DIR"
  echo -e "${YELLOW}Created directory, but no images found. Please add images to $IMAGE_DIR${NC}"
  exit 1
fi

# Check if directory is readable
if [ ! -r "$IMAGE_DIR" ]; then
  echo -e "${RED}Error: Directory is not readable: $IMAGE_DIR${NC}"
  exit 1
fi

# Find image files
IMAGE_COUNT=$(find "$IMAGE_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) | wc -l)

# Check if images were found
if [ "$IMAGE_COUNT" -eq 0 ]; then
  echo -e "${RED}Error: No image files found in $IMAGE_DIR${NC}"
  echo "Please add some JPG, PNG, or GIF images to the directory."
  exit 1
else
  echo -e "${GREEN}Found $IMAGE_COUNT image files.${NC}"
  
  # Show the first few images
  echo "First few images:"
  find "$IMAGE_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) | head -5
  
  # Check file permissions
  echo -e "\nVerifying file permissions..."
  UNREADABLE_FILES=$(find "$IMAGE_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) ! -readable | wc -l)
  
  if [ "$UNREADABLE_FILES" -gt 0 ]; then
    echo -e "${YELLOW}Warning: Found $UNREADABLE_FILES unreadable image files.${NC}"
    echo "Please check file permissions."
  else
    echo -e "${GREEN}All image files are readable.${NC}"
  fi
  
  # Check file sizes
  echo -e "\nChecking image sizes..."
  LARGE_FILES=$(find "$IMAGE_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) -size +5M | wc -l)
  
  if [ "$LARGE_FILES" -gt 0 ]; then
    echo -e "${YELLOW}Warning: Found $LARGE_FILES image files larger than 5MB.${NC}"
    echo "Large files might cause upload issues. Consider resizing them."
  else
    echo -e "${GREEN}All image files are under 5MB.${NC}"
  fi
  
  echo -e "\n${GREEN}Image verification complete.${NC}"
  exit 0
fi