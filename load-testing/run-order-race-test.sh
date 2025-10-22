#!/bin/bash

set -euo pipefail

print_help() {
  cat <<'EOF'
Usage: ./run-order-race-test.sh [--cloud] [environment]

Description
  Runs order race condition test - spawns 100 VUs per seat to test concurrent booking.
  For each seat in the configuration:
    - 100 VUs attempt to book the same seat simultaneously
    - Only 1 should succeed, 99 should fail
  
  If you have 5 seats configured, the test runs 5 times in sequence:
    - Round 1: 100 VUs → Seat 1 (1 success, 99 failures)
    - Round 2: 100 VUs → Seat 2 (1 success, 99 failures)
    - Round 3: 100 VUs → Seat 3 (1 success, 99 failures)
    - Round 4: 100 VUs → Seat 4 (1 success, 99 failures)
    - Round 5: 100 VUs → Seat 5 (1 success, 99 failures)
  
  Expected total: 5 successful bookings, 495 failures

Environments
  local (default), dev, prod. Overrides are applied via src/config.js → environments.

Setup notes
  • Configure seats in src/config.js → config.order.seatIds array
  • Optionally set ORDER_VUS to adjust concurrency (default: 100)
  • Pass --cloud to execute via k6 Cloud (Mumbai / asia-south1)

Examples
  ./run-order-race-test.sh local              # Test all seats against local
  ./run-order-race-test.sh prod               # Test all seats against prod
  ./run-order-race-test.sh --cloud prod       # Run in k6 Cloud
  ORDER_VUS=50 ./run-order-race-test.sh dev   # 50 VUs per seat

EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

CLOUD_MODE=false

if [[ "${1:-}" == "--cloud" || "${1:-}" == "cloud" ]]; then
  CLOUD_MODE=true
  shift
fi

ENVIRONMENT=${1:-local}
ENVIRONMENT=${ENVIRONMENT,,}

VUS=${ORDER_VUS:-100}

mkdir -p output

echo "========================================="
echo "Order Race Condition Test"
echo "========================================="
echo "Environment: ${ENVIRONMENT}"
echo "VUs per seat: ${VUS}"
echo "Mode: $([ "$CLOUD_MODE" = true ] && echo "Cloud (k6)" || echo "Local")"
echo "========================================="
echo ""

if [[ "${CLOUD_MODE}" == "true" ]]; then
  echo "Running complete race test in k6 Cloud..."
  K6_CLOUD_REGION=asia-south1 k6 cloud \
    --env ENV="${ENVIRONMENT}" \
    --env ORDER_VUS="${VUS}" \
    order-test.js
  echo "Cloud run submitted to Mumbai region"
else
  timestamp=$(date +"%Y%m%d_%H%M%S")
  report_file="output/order_race_all_seats_${ENVIRONMENT}_${timestamp}.html"
  json_summary="output/order_race_all_seats_${ENVIRONMENT}_${timestamp}.json"

  echo "Running race test for all seats..."
  # Note: Test includes 2-second delays between seats to ensure HTML report generation
  # (k6 dashboard requires ~30+ seconds minimum test duration)
  k6 run \
    --out "dashboard=export=${report_file}" \
    --summary-export="${json_summary}" \
    --env ENV="${ENVIRONMENT}" \
    --env ORDER_VUS="${VUS}" \
    order-test.js

  echo ""
  echo "========================================="
  echo "HTML report: ${report_file}"
  echo "JSON summary: ${json_summary}"
  echo "========================================="
fi
