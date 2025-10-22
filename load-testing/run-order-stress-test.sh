#!/bin/bash

set -euo pipefail

print_help() {
  cat <<'EOF'
Usage: ./run-order-stress-test.sh [--cloud] [environment]

Description
  Runs order service stress test - sustained high load with concurrent booking attempts.
  Tests system behavior under stress where multiple users continuously attempt to book seats.
  
  Expected outcomes:
    - 201: Successful bookings (seat was available)
    - 400: Seat already locked/booked (expected when testing same seats)
  Both are considered successful responses (system working correctly)

Environments
  local (default), dev, prod. Overrides are applied via src/config.js → environments.

Setup notes
  • Configure seats in src/config.js → config.order.seatIds array
  • Optionally set ORDER_STRESS_VUS to adjust concurrency (default: 50)
  • Pass --cloud to execute via k6 Cloud (Mumbai / asia-south1)

Examples
  ./run-order-stress-test.sh local              # Stress test against local
  ./run-order-stress-test.sh prod               # Stress test against prod
  ./run-order-stress-test.sh --cloud prod       # Run in k6 Cloud
  ORDER_STRESS_VUS=100 ./run-order-stress-test.sh dev   # 100 VUs base load

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

VUS=${ORDER_STRESS_VUS:-50}

mkdir -p output

echo "========================================="
echo "Order Service Stress Test"
echo "========================================="
echo "Environment: ${ENVIRONMENT}"
echo "Base VUs: ${VUS}"
echo "Peak VUs: $((VUS * 3 / 2))"
echo "Mode: $([ "$CLOUD_MODE" = true ] && echo "Cloud (k6)" || echo "Local")"
echo "Duration: ~16 minutes"
echo "========================================="
echo ""

if [[ "${CLOUD_MODE}" == "true" ]]; then
  echo "Running stress test in k6 Cloud..."
  K6_CLOUD_REGION=asia-south1 k6 cloud \
    --env ENV="${ENVIRONMENT}" \
    --env ORDER_STRESS_VUS="${VUS}" \
    order-stress-test.js
  echo "Cloud run submitted to Mumbai region"
else
  timestamp=$(date +"%Y%m%d_%H%M%S")
  report_file="output/order_stress_${ENVIRONMENT}_${timestamp}.html"
  json_summary="output/order_stress_${ENVIRONMENT}_${timestamp}.json"

  echo "Running order stress test..."
  k6 run \
    --out "dashboard=export=${report_file}" \
    --out "dashboard=report-title=Order Stress Test - ${ENVIRONMENT^^}" \
    --out "dashboard=period=1s" \
    --summary-export="${json_summary}" \
    --env ENV="${ENVIRONMENT}" \
    --env ORDER_STRESS_VUS="${VUS}" \
    order-stress-test.js

  echo ""
  echo "========================================="
  if [ -f "${report_file}" ]; then
    echo "HTML report saved to ${report_file}"
  else
    echo "Note: HTML report generation skipped (test too short)"
  fi
  echo "JSON summary saved to ${json_summary}"
  echo "========================================="
fi
