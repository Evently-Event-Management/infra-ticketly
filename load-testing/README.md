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
└── run-load-tests.sh       # Shell script to run tests with various options
```

## Test Scenarios

1. **Smoke Test**: Verifies the system works with minimal load (1 VU, 1 minute)
2. **Load Test**: Tests normal expected load (10 VUs, 5 minutes)
3. **Stress Test**: Tests higher than normal load (50 VUs, 10 minutes)
4. **Soak Test**: Tests moderate load over extended period (20 VUs, 30 minutes)
5. **Spike Test**: Tests sudden burst of traffic (100 VUs for 1 minute)
6. **Breakpoint Test**: Finds the system breaking point (increasing load)

## Running Tests

### Using the Shell Script

The `run-load-tests.sh` script provides a convenient way to run different test scenarios:

```bash
# Make the script executable
chmod +x run-load-tests.sh

# Run smoke test in local environment
./run-load-tests.sh --scenario smoke --env local

# Run load test in dev environment
./run-load-tests.sh --scenario load --env dev

# Run a stress test in staging
./run-load-tests.sh -s stress -e staging
```

### Using npm Scripts

You can also use the npm scripts defined in package.json:

```bash
# Install dependencies
npm install

# Run smoke test
npm run test:smoke

# Run load test
npm run test:load

# Run stress test
npm run test:stress

# Run soak test
npm run test:soak

# Run spike test
npm run test:spike

# Run breakpoint test
npm run test:breakpoint

# Run all scenarios
npm run test:all
```

## Configuration

Before running the tests, update the configuration in `src/config.js`:

1. Set the correct base URL for your API
2. Update the authentication details
3. Add sample IDs for testing (event IDs, session IDs, seat IDs)
4. Adjust environment-specific configurations

## Test Results

Test results are saved to the `output` directory in JSON and CSV formats. You can visualize these results using tools like:

- [k6 Cloud](https://k6.io/cloud/)
- [Grafana](https://grafana.com/) with the k6 data source
- [Datadog](https://www.datadoghq.com/) with k6 integration

## Enhanced Testing and Troubleshooting

For detailed error logging and troubleshooting, use the enhanced test script:

```bash
# Make the script executable
chmod +x run-enhanced-tests.sh

# Run with debug-level logging
./run-enhanced-tests.sh --scenario debug --log-level debug

# Run load test with info-level logging
./run-enhanced-tests.sh --scenario load --log-level info
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