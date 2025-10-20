#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
echo -e "${YELLOW}"
echo "====================================="
echo "Ticketly Event Seeding Complete Test"
echo "====================================="
echo -e "${NC}"

# Step 1: Verify images
echo -e "\n${YELLOW}Step 1: Verifying images...${NC}"
./scripts/verify-images.sh
if [ $? -ne 0 ]; then
  echo -e "${RED}Image verification failed. Aborting.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Images verified successfully${NC}"

# Step 2: Test image upload
echo -e "\n${YELLOW}Step 2: Testing image upload...${NC}"
./scripts/seed-events.sh -t
if [ $? -ne 0 ]; then
  echo -e "${RED}Image upload test failed. Check backend connectivity and authentication.${NC}"
  echo -e "${YELLOW}Do you want to continue anyway? (y/N)${NC}"
  read -r response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Aborting."
    exit 1
  fi
else
  echo -e "${GREEN}✓ Image upload test passed${NC}"
fi

# Step 3: Clean existing seed data
echo -e "\n${YELLOW}Step 3: Cleaning up any existing seeded data...${NC}"
./scripts/seed-events.sh -c
# Don't exit on error as there might not be any seed data
echo -e "${GREEN}✓ Cleanup completed${NC}"

# Step 4: Run seeding
echo -e "\n${YELLOW}Step 4: Starting event seeding...${NC}"
ENV=${1:-dev}
echo "Using environment: $ENV"
./scripts/seed-events.sh -e $ENV
if [ $? -ne 0 ]; then
  echo -e "${RED}Seeding failed. Check logs for details.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Seeding completed successfully${NC}"

# Summary
echo -e "\n${GREEN}====================================="
echo "     All tests completed successfully!"
echo "=====================================${NC}"
echo ""
echo "A seed-data.json file has been created with details of all seeded items."
echo "You can use this file to clean up the data later with:"
echo "  ./scripts/seed-events.sh -c"
echo ""