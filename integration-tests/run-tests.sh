#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}=== Event Ticketing System Integration Tests ===${NC}"
echo ""

# Check if services are running
echo -e "${BOLD}Checking if required services are running...${NC}"

# Check PostgreSQL
if nc -z localhost 5432 > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} PostgreSQL is running"
else
  echo -e "  ${RED}✗${NC} PostgreSQL is not running at localhost:5432"
  echo -e "  ${YELLOW}!${NC} Make sure to start PostgreSQL before running tests"
fi

# Check MongoDB
if nc -z localhost 27017 > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} MongoDB is running"
else
  echo -e "  ${RED}✗${NC} MongoDB is not running at localhost:27017"
  echo -e "  ${YELLOW}!${NC} Make sure to start MongoDB before running tests"
fi

# Check Redis
if nc -z localhost 6379 > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} Redis is running"
else
  echo -e "  ${RED}✗${NC} Redis is not running at localhost:6379"
  echo -e "  ${YELLOW}!${NC} Make sure to start Redis before running tests"
fi

echo ""
echo -e "${BOLD}Installing dependencies...${NC}"
npm install

echo ""
echo -e "${BOLD}Building TypeScript files...${NC}"
npm run build

echo ""
echo -e "${BOLD}Testing connectivity to services...${NC}"
npm run connectivity

echo ""
echo -e "${BOLD}Running tests...${NC}"
npm run test:cqrs