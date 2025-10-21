#!/bin/bash

set -euo pipefail

print_help() {
  cat <<'EOF'
Usage: ./run-query-tests.sh [--cloud] [scenario] [environment]

Scenarios
  all (default) → Run all scenarios sequentially
  smoke         → Minimal load validation
  load          → Normal expected load
  stress        → Peak load testing
  step-up      → Progressive load testing
  soak          → Extended duration testing
  spike         → Sudden traffic burst
  breakpoint    → Find maximum capacity
  debug         → Troubleshooting with minimal load

Environments
  local (default), dev, prod. Overrides are applied via src/config.js → environments.

Setup notes
  • Configure authentication and base URLs inside src/config.js.
  • Pass --cloud to execute the run via k6 Cloud (Mumbai / asia-south1).
    Cloud runs stream metrics to Grafana Cloud; local JSON results are not generated.

Examples
  ./run-query-tests.sh smoke local        # Smoke test against local
  ./run-query-tests.sh all dev            # Run all scenarios against dev
  ./run-query-tests.sh load prod          # Load test against prod
  ./run-query-tests.sh --cloud stress prod # Stress test in k6 Cloud

EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

declare -A SCENARIOS=(
  [smoke]=smoke
  [load]=load
  [stress]=stress
  [soak]=soak
  [spike]=spike
  [breakpoint]=breakpoint
  [step-up]=step-up
  [debug]=debug
)

CLOUD_MODE=false

if [[ "${1:-}" == "--cloud" || "${1:-}" == "cloud" ]]; then
  CLOUD_MODE=true
  shift
fi

SCENARIO_INPUT=${1:-all}
SCENARIO_INPUT=${SCENARIO_INPUT,,}

ENVIRONMENT=${2:-local}
ENVIRONMENT=${ENVIRONMENT,,}

mkdir -p output

run_k6() {
  local scenario=$1
  local environment=$2
  echo "Running query service :: ${scenario} scenario against ${environment} environment"

  if [[ "${CLOUD_MODE}" == "true" ]]; then
    K6_CLOUD_REGION=asia-south1 k6 cloud \
      --env ENV="${environment}" \
      --env SCENARIO="${scenario}" \
      --env ONLY_SCENARIO="${scenario}" \
      query-test.js
    echo "Cloud run submitted to Mumbai region"
  else
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local result_file="output/query_${scenario}_${environment}_${timestamp}.json"

    k6 run \
      --out dashboard \
      --env ENV="${environment}" \
      --env SCENARIO="${scenario}" \
      --env ONLY_SCENARIO="${scenario}" \
      query-test.js

    echo "Results saved to ${result_file}"
  fi

  echo ""
}

if [[ "${SCENARIO_INPUT}" == "all" ]]; then
  echo "Launching full query test suite (smoke, load, stress, soak, spike, breakpoint, debug, step-up)"
  for s in smoke load stress soak spike breakpoint debug step-up; do
    run_k6 "${SCENARIOS[$s]}" "${ENVIRONMENT}"
  done
else
  if [[ -z "${SCENARIOS[${SCENARIO_INPUT}]:-}" ]]; then
    echo "ERROR: Unknown scenario '${SCENARIO_INPUT}'."
    print_help
    exit 1
  fi
  run_k6 "${SCENARIOS[${SCENARIO_INPUT}]}" "${ENVIRONMENT}"
fi
