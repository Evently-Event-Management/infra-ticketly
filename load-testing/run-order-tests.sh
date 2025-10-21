#!/bin/bash

set -euo pipefail

print_help() {
  cat <<'EOF'
Usage: ./run-order-tests.sh [--cloud] [environment]

Description
  Tests order service under high contention - multiple users attempting to book
  the same seat simultaneously. Most requests should fail; at least one succeeds.

Environments
  local (default), dev, prod. Overrides are applied via src/config.js → environments.

Setup notes
  • Configure authentication, base URLs, and order identifiers inside src/config.js.
    The test reads event_id, session_id, organization_id, and seat_ids directly
    from the config file—no environment variables are required.
  • Optionally set ORDER_VUS and ORDER_DURATION environment variables to adjust
    concurrency (defaults: 100 VUs for 30s).
  • Pass --cloud to execute the run via k6 Cloud (Mumbai / asia-south1).
    Cloud runs stream metrics to Grafana Cloud; local JSON results are not generated.

Examples
  ./run-order-tests.sh local              # Contention test against local
  ./run-order-tests.sh prod               # Contention test against prod
  ./run-order-tests.sh --cloud prod       # Contention test in k6 Cloud
  ORDER_VUS=50 ./run-order-tests.sh dev   # Adjust concurrency to 50 VUs

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

mkdir -p output

echo "Running order service contention test against ${ENVIRONMENT} environment"

if [[ "${CLOUD_MODE}" == "true" ]]; then
  K6_CLOUD_REGION=asia-south1 k6 cloud \
    --env ENV="${ENVIRONMENT}" \
    order-test.js
  echo "Cloud run submitted to Mumbai region"
else
  timestamp=$(date +"%Y%m%d_%H%M%S")
  report_file="output/order_race_${ENVIRONMENT}_${timestamp}.html"

  k6 run \
    --out "dashboard=export=${report_file}" \
    --env ENV="${ENVIRONMENT}" \
    order-test.js

  echo "HTML report saved to ${report_file}"
fi
