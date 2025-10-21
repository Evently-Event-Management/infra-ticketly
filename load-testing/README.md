# Ticketly Load Testing Suite

k6-based load testing for Ticketly microservices, separated into independent query and order test suites.

## Overview

This directory contains two independent load testing suites:

1. **Query Service Tests** (`query-test.js`) - Read-only discovery flow testing
2. **Order Service Tests** (`order-test.js`) - Concurrent booking contention testing

Each suite has its own dedicated runner script and can be executed independently or via k6 Cloud.

### Types of Load Testing

**Query Service Scenarios:**
- **Smoke**: Minimal validation (1 VU, 1m)
- **Load**: Normal expected traffic (10 VUs, 5m)
- **Stress**: Peak load conditions (20 VUs, 10m)
- **Soak**: Extended stability test (5 VUs, 30m)
- **Spike**: Sudden traffic burst (1→50→1 VUs, 5m)
- **Breakpoint**: Find maximum capacity (10→100 VUs, 15m)
- **Debug**: Troubleshooting mode (2 VUs, 1m)

**Order Service Scenario:**
- **Order Race**: Concurrent seat booking contention (100 VUs, 30s)

## Quick Start

### Query Service Tests

```bash
# Smoke test locally
./run-query-tests.sh smoke local

# Load test against dev
./run-query-tests.sh load dev

# Run all scenarios sequentially against prod
./run-query-tests.sh all prod

# Stress test in k6 Cloud (Mumbai region)
./run-query-tests.sh --cloud stress prod
```

### Order Service Tests

```bash
# Contention test locally
./run-order-tests.sh local

# Test against prod
./run-order-tests.sh prod

# Run in k6 Cloud
./run-order-tests.sh --cloud prod

# Adjust concurrency
ORDER_VUS=50 ORDER_DURATION=60s ./run-order-tests.sh dev
```

## Directory Structure

```
load-testing/
│
├── src/
│   ├── config.js           # Configuration settings for environments and test data
│   ├── main.js             # Main entry point for load tests
│   │
│   ├── lib/                # Shared libraries and utilities
│   │   ├── auth.js         # Authentication functions
│   │   ├── endpoints.js    # API endpoint testing functions
│   │   ├── transactions.js # Business transaction functions
│   │   └── utils.js        # Utility functions
│   │
│   └── scenarios/          # Different load testing scenarios
│       ├── smoke.js        # Smoke testing scenario
│       ├── load.js         # Load testing scenario
│       ├── stress.js       # Stress testing scenario
│       ├── soak.js         # Soak testing scenario
│       ├── spike.js        # Spike testing scenario
│       └── breakpoint.js   # Breakpoint testing scenario
│
├── output/                 # Test results output (created during test runs)
│
├── package.json            # Project configuration and scripts
├── output/                # Test results and logs
├── archive/               # Archived older script versions
└── run-tests.sh           # Integrated script with quick debug mode
```

## Test Scenarios

Each scenario is designed to simulate specific traffic patterns and loads. The following table summarizes the actual numbers used in each test:

| Scenario      | Virtual Users (VUs) / Rate | Duration         | Pattern / Purpose                                   | Example Load Profile                |
|---------------|---------------------------|------------------|-----------------------------------------------------|-------------------------------------|
| **Smoke**     | 1 VU                      | 1 minute         | Minimal load, basic system verification             | 1 user, steady for 1 min            |
| **Load**      | 2 → 5 → 10 VUs            | ~3 minutes       | Normal expected load, ramp-up and cool-down         | 2→5 VUs (30s), 5 VUs (1m), 10 VUs (1m), ramp-down |
| **Stress**    | 5 → 20 → 50 VUs           | ~4.5 minutes     | Higher than normal load, peak traffic simulation    | 5→20 VUs (30s), 20→50 VUs (1m), 50 VUs (2m), ramp-down |
| **Soak**      | 5 → 20 VUs                | 34 minutes       | Moderate load over extended period, resource leaks  | 5→20 VUs (2m), 20 VUs (30m), ramp-down (2m) |
| **Spike**     | 0 → 30 VUs                | 50 seconds       | Sudden burst, resilience and recovery               | 0→30 VUs (10s), 30 VUs (30s), ramp-down (10s) |
| **Breakpoint**| 1 → 100 req/sec           | 20 minutes       | Find breaking point, max throughput                 | 10→100 req/sec, 2 min per stage, up to 500 VUs |
| **Debug**     | 2 VUs                     | 1 minute / 30s   | Troubleshooting, minimal load                       | 2 users, steady for 1 min or 30s    |
| **Quick**     | 2 VUs                     | 30 seconds       | Fast debugging, minimal load                        | 2 users, steady for 30s             |

**Details:**

- **Smoke Test**: Runs with 1 virtual user for 1 minute, ensuring all endpoints respond correctly.
- **Load Test**: Starts with 2 VUs, ramps up to 5 VUs over 30s, holds for 1m, then ramps to 10 VUs for 1m, then ramps down. Simulates typical production traffic.
- **Stress Test**: Begins at 5 VUs, ramps to 20 VUs in 30s, then to 50 VUs in 1m, holds for 2m, then ramps down. Tests system under peak load.
- **Soak Test**: Ramps from 5 to 20 VUs in 2m, holds at 20 VUs for 30m, then ramps down. Detects resource leaks and long-term issues.
- **Spike Test**: Rapidly increases from 0 to 30 VUs in 10s, holds for 30s, then ramps down in 10s. Simulates sudden traffic spikes.
- **Breakpoint Test**: Uses arrival rate executor, starts at 10 req/sec, increases by 10 req/sec every 2 minutes up to 100 req/sec, with up to 500 VUs. Finds system breaking point.
- **Debug/Quick Test**: Runs with 2 VUs for 1 minute (debug) or 30 seconds (quick), for troubleshooting and fast feedback.

## Running Tests

### Using the Integrated Shell Script

The `run-tests.sh` script provides a comprehensive way to run different test scenarios with HTML reports and quick debug mode:

```bash
# Make the script executable
chmod +x run-tests.sh

# Run quick debug test
./run-tests.sh --quick

# Run smoke test in local environment
./run-tests.sh --scenario smoke --env local

# Run load test in dev environment
./run-tests.sh --scenario load --env dev

# Run a stress test in staging
./run-tests.sh -s stress -e staging

# Run with detailed logging
./run-tests.sh --scenario load --log-level debug
```

### Command Line Options for run-tests.sh

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--scenario` | `-s` | Test scenario (smoke, load, stress, soak, spike, breakpoint, debug, quick) | smoke |
| `--env` | `-e` | Environment (local, dev, staging, prod) | local |
| `--log-level` | `-l` | Log level (debug, info, warning, error) | warning |
| `--output` | `-o` | Output format (json, csv) | json |
| `--vus` | `-v` | Number of virtual users for custom runs | 10 |
| `--duration` | `-d` | Duration for custom runs | 30s |
| `--quick` | `-q` | Enable quick debug mode (fast tests with minimal load) | false |
| `--help` | `-h` | Print help message | |

### Using npm Scripts

You can also use the npm scripts defined in package.json (note: these will now use the new run-tests.sh script):

```bash
# Install dependencies
npm install

# Run quick debug test
npm run test:quick

# Run smoke test
npm run test:smoke

# Run load test
npm run test:load

# Run stress test
npm run test:stress
```

## Configuration

Before running the tests, update the configuration in `src/config.js`:

1. Set the correct base URL for your API
2. Update the authentication details
3. Add sample IDs for testing (event IDs, session IDs, seat IDs)
4. Adjust environment-specific configurations

## Test Results

### Output Files

Test results are saved to the following locations:

- JSON reports: `output/<scenario>_<env>_<timestamp>.json`
- CSV reports: `output/<scenario>_<env>_<timestamp>.csv`
- Log files: `output/<scenario>_<env>_<timestamp>.log`

### External Visualization

You can also visualize results using external tools:

- [k6 Cloud](https://k6.io/cloud/)
- [Grafana](https://grafana.com/) with the k6 data source
- [Datadog](https://www.datadoghq.com/) with k6 integration

## Enhanced Testing and Troubleshooting

For detailed error logging and troubleshooting, use the integrated script with debug options:

```bash
# Run quick debug test with detailed logging
./run-tests.sh --quick --log-level debug

# Run load test with info-level logging
./run-tests.sh --scenario load --log-level info
```

### Common Issues and Solutions

1. **High Error Rates under Load**:
   - Reduce concurrent users in test scenarios
   - Check for API rate limits or connection limits
   - Ensure the backend services can handle the load
   - Verify token expiration and refresh mechanisms

2. **Slow Response Times**:
   - Examine backend database queries and indexing
   - Check for network latency between services
   - Consider caching frequently accessed resources
   - Verify service resource allocation

3. **Authentication Failures**:
   - Ensure tokens are correctly obtained and used
   - Check token expiration times and refresh as needed
   - Verify that Keycloak settings match test configuration

## Custom Parameters

For more advanced testing, you can override default parameters:

```bash
# Run with custom VUs and duration
./run-load-tests.sh --vus 50 --duration 2m

# Specify output format
./run-load-tests.sh --output "json=custom.json"
```

## Extending to Other Microservices

While the current suite targets the event-query microservice, the modular design allows easy extension. To add load tests for other microservices:

1. Create new scenario scripts in `src/scenarios/`.
2. Add endpoint and transaction functions in `src/lib/`.
3. Update `src/config.js` with relevant configuration and test data.
4. Integrate new scenarios into `src/main.js` and the shell script.

This approach ensures consistent, scalable load testing across all Ticketly services.