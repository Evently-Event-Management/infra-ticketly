# Ticketly Load Testing Suite with k6

This directory contains load testing scripts for the Ticketly microservices using [k6](https://k6.io/), an open-source load testing tool.

## Prerequisites

- [k6](https://k6.io/docs/getting-started/installation/) installed on your system
- Node.js (for formatting scripts with Prettier)
- Access to Ticketly API and authentication credentials

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

1. **Smoke Test**: Verifies the system works with minimal load (1 VU, 1 minute)
2. **Load Test**: Tests normal expected load (10 VUs, 5 minutes)
3. **Stress Test**: Tests higher than normal load (up to 20 VUs over 4.5 minutes)
4. **Soak Test**: Tests moderate load over extended period (up to 20 VUs, 30+ minutes)
5. **Spike Test**: Tests sudden burst of traffic (up to 30 VUs over 50 seconds)
6. **Breakpoint Test**: Finds the system breaking point (up to 500 VUs over 20 minutes)
7. **Debug Test**: Reduced load for troubleshooting (2 VUs for 1 minute)
8. **Quick Test**: Fast debugging with minimal load (2 VUs for 30 seconds)

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