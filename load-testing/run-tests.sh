#!/bin/bash

set -euo pipefail

print_help() {
  cat <<'EOF'
Usage: ./run-tests.sh [service] [scenario] [environment]

Services and scenarios
  query  → discovery flow (default). Scenarios: all (default), smoke, load, stress,
            soak, spike, breakpoint, debug.
  order  → parallel seat booking contention. Scenarios: race (default).

Environments
  local (default), dev, prod. Overrides are applied via src/config.js → environments.

Setup notes
  • Configure authentication, base URLs, and order identifiers inside src/config.js.
    The order workload reads event_id, session_id, organization_id, and seat_ids
    directly from that file—no environment variables are required.
  • Optionally adjust ORDER_VUS / ORDER_DURATION when invoking order tests to
    change contention levels (defaults: 100 VUs for 30s).

Examples
  ./run-tests.sh query smoke local      # Query service, smoke scenario, local endpoints
  ./run-tests.sh query all dev          # Run every query scenario sequentially against dev
  ./run-tests.sh order race prod        # Run seat contention test against prod settings

EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

declare -A QUERY_SCENARIOS=(
  [smoke]=smoke
  [load]=load
  [stress]=stress
  [soak]=soak
  [spike]=spike
  [breakpoint]=breakpoint
  [debug]=debug
)

SERVICE=${1:-query}
SERVICE=${SERVICE,,}

SCENARIO_INPUT=${2:-}
ENVIRONMENT=${3:-local}
ENVIRONMENT=${ENVIRONMENT,,}

mkdir -p output

run_k6() {
  local service=$1
  local scenario=$2
  local environment=$3
  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  local result_file="output/${service}_${scenario}_${environment}_${timestamp}.json"

  echo "Running ${service} service :: ${scenario} scenario against ${environment} environment"

  k6 run \
    --out json="${result_file}" \
    --env ENV="${environment}" \
    --env SCENARIO="${scenario}" \
    --env ONLY_SCENARIO="${scenario}" \
    --env SERVICE="${service}" \
    src/main.js

  echo "Results saved to ${result_file}"
  echo ""
}

case "${SERVICE}" in
  query)
    SCENARIO=${SCENARIO_INPUT:-all}
    SCENARIO=${SCENARIO,,}
    if [[ "${SCENARIO}" == "all" ]]; then
      echo "Launching full query suite (smoke, load, stress, soak, spike, breakpoint, debug)"
      for s in smoke load stress soak spike breakpoint debug; do
        run_k6 "${SERVICE}" "${QUERY_SCENARIOS[$s]}" "${ENVIRONMENT}"
      done
    else
      if [[ -z "${QUERY_SCENARIOS[${SCENARIO}]:-}" ]]; then
        echo "ERROR: Unknown query scenario '${SCENARIO}'."
        print_help
        exit 1
      fi
      run_k6 "${SERVICE}" "${QUERY_SCENARIOS[${SCENARIO}]}" "${ENVIRONMENT}"
    fi
    ;;
  order)
    SCENARIO=${SCENARIO_INPUT:-race}
    SCENARIO=${SCENARIO,,}
    case "${SCENARIO}" in
      race|order_race|orderrace)
        run_k6 "${SERVICE}" "orderRace" "${ENVIRONMENT}"
        ;;
      *)
        echo "ERROR: Order service supports only the 'race' scenario."
        print_help
        exit 1
        ;;
    esac
    ;;
  *)
    echo "ERROR: Unsupported service '${SERVICE}'."
    print_help
    exit 1
    ;;
esac