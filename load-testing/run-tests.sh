#!/bin/bash

# TicketlyLoadTester: Integrated load testing script for the Ticketly API
# This script combines features from run-load-tests.sh and run-enhanced-tests.sh
# and adds HTML report generation

# Exit on error
set -e

# Default values
SCENARIO="smoke"
ENVIRONMENT="local"
LOG_LEVEL="warning" # Default log level
K6_VUIS=10
K6_DURATION="30s"
OUTPUT_FORMAT="json"
QUICK_DEBUG=false

# Function to print usage information
function print_usage {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -s, --scenario    Test scenario (smoke|load|stress|soak|spike|breakpoint|debug|quick) [default: smoke]"
  echo "  -e, --env         Environment (local|dev|staging|prod) [default: local]"
  echo "  -l, --log-level   Log level (debug|info|warning|error) [default: warning]"
  echo "  -o, --output      Output format (json|csv) [default: json]"
  echo "  -v, --vus         Number of virtual users for custom runs [default: 10]"
  echo "  -d, --duration    Duration for custom runs [default: 30s]"
  echo "  -q, --quick       Enable quick debug mode (fast tests with minimal load) [default: false]"
  echo "  -h, --help        Print this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --scenario load --env dev"
  echo "  $0 -s stress -e staging"
  echo "  $0 --quick -l debug"
  echo "  $0 -s quick"
  exit 1
}

# Create output directory if it doesn't exist
mkdir -p output

# Ensure output directory has proper permissions
chmod 755 output

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--scenario)
      SCENARIO="$2"
      shift 2
      ;;
    -e|--env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -l|--log-level)
      LOG_LEVEL="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    -v|--vus)
      K6_VUIS="$2"
      shift 2
      ;;
    -d|--duration)
      K6_DURATION="$2"
      shift 2
      ;;
    -q|--quick)
      QUICK_DEBUG=true
      shift
      ;;
    -h|--help)
      print_usage
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      ;;
  esac
done

# Handle "quick" scenario as an alias for a fast debug run
if [[ "$SCENARIO" == "quick" ]]; then
  QUICK_DEBUG=true
  SCENARIO="debug"
fi

# Validate scenario
if [[ ! "$SCENARIO" =~ ^(smoke|load|stress|soak|spike|breakpoint|debug)$ ]]; then
  echo "❌ Invalid scenario: $SCENARIO"
  print_usage
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(local|dev|staging|prod)$ ]]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  print_usage
fi

# Validate log level
if [[ ! "$LOG_LEVEL" =~ ^(debug|info|warning|error)$ ]]; then
  echo "❌ Invalid log level: $LOG_LEVEL"
  print_usage
fi

# Create timestamp for unique output files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
JSON_OUTPUT_FILE="output/${SCENARIO}_${ENVIRONMENT}_${TIMESTAMP}.json"
CSV_OUTPUT_FILE="output/${SCENARIO}_${ENVIRONMENT}_${TIMESTAMP}.csv"
LOG_FILE="output/${SCENARIO}_${ENVIRONMENT}_${TIMESTAMP}.log"

# Configure output formats
K6_OUT_PARAMS=""
if [[ "$OUTPUT_FORMAT" == *"json"* ]]; then
  K6_OUT_PARAMS+="--out json=$JSON_OUTPUT_FILE "
fi
if [[ "$OUTPUT_FORMAT" == *"csv"* ]]; then
  K6_OUT_PARAMS+="--out csv=$CSV_OUTPUT_FILE "
fi

# Banner display
echo "┌──────────────────────────────────────────────────┐"
echo "│             TICKETLY LOAD TEST RUNNER            │"
echo "└──────────────────────────────────────────────────┘"
echo ""
echo "🚀 Starting $SCENARIO load test against $ENVIRONMENT environment"
echo "⏱️  $(date)"
echo "📝 Log level: $LOG_LEVEL"

# If quick debug mode is enabled, create a temporary scenario file
if [[ "$QUICK_DEBUG" == true ]]; then
  echo "⚡ Quick debug mode enabled: Running a fast test with minimal load"
  
  QUICK_DEBUG_FILE="src/scenarios/quick_temp.js"
  
  # Create a temporary quick debug scenario file
  cat > $QUICK_DEBUG_FILE << EOF
// Temporary quick debug scenario - fast test with minimal load
export const debugTestScenario = {
  executor: 'constant-vus',
  vus: 2,
  duration: '30s',
  tags: {
    scenario: 'debug'
  }
};
EOF

  echo "Created temporary quick debug scenario"
  QUICK_DEBUG_ENV="--env QUICK_DEBUG=true"
fi

# Log output file information
if [[ "$OUTPUT_FORMAT" == *"json"* ]]; then
  echo "📊 JSON results will be saved to $JSON_OUTPUT_FILE"
fi
if [[ "$OUTPUT_FORMAT" == *"csv"* ]]; then
  echo "📊 CSV results will be saved to $CSV_OUTPUT_FILE"
fi
echo "📄 Logs will be saved to $LOG_FILE"
echo ""

# Run k6 test with configured parameters
echo "▶️ Running k6 test..."
k6 run \
  $K6_OUT_PARAMS \
  --console-output=$LOG_FILE \
  --env SCENARIO=$SCENARIO \
  --env ENV=$ENVIRONMENT \
  --env ONLY_SCENARIO=$SCENARIO \
  $QUICK_DEBUG_ENV \
  src/main.js

# Cleanup temporary file if it was created
if [[ "$QUICK_DEBUG" == true ]]; then
  rm $QUICK_DEBUG_FILE
  echo "Removed temporary quick debug scenario"
fi
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ticketly Load Test Report - $SCENARIO ($ENVIRONMENT)</title>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 1200px; margin: 0 auto; padding: 20px; }
    h1 { color: #2c3e50; text-align: center; padding-bottom: 10px; border-bottom: 1px solid #eee; }
    h2 { color: #3498db; margin-top: 30px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 30px; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #f2f2f2; color: #333; }
    tr:hover { background-color: #f5f5f5; }
    .metric-good { color: #27ae60; }
    .metric-warning { color: #f39c12; }
    .metric-bad { color: #e74c3c; }
    .summary-box { background-color: #f8f9fa; border-radius: 5px; padding: 15px; margin: 20px 0; }
    .chart-container { width: 100%; height: 400px; margin-bottom: 30px; }
    .container { display: flex; flex-wrap: wrap; justify-content: space-between; }
    .card { flex: 1 0 45%; margin: 10px; padding: 15px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    @media (max-width: 768px) { .card { flex: 1 0 100%; } }
  </style>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script>
    // Load and parse the JSON data
    fetch('./$(basename $JSON_OUTPUT_FILE)')
      .then(response => response.json())
      .then(data => {
        document.getElementById('loading').style.display = 'none';
        document.getElementById('report-content').style.display = 'block';
        populateSummary(data);
        createCharts(data);
      })
      .catch(error => {
        document.getElementById('loading').innerHTML = 'Error loading data: ' + error;
      });

    function populateSummary(data) {
      // Populate summary from the metrics data
      if (data.metrics) {
        const metrics = data.metrics;
        
        // Populate HTTP metrics
        if (metrics.http_req_duration) {
          document.getElementById('avg_response').textContent = (metrics.http_req_duration.values.avg).toFixed(2) + ' ms';
          document.getElementById('p95_response').textContent = (metrics.http_req_duration.values['p(95)']).toFixed(2) + ' ms';
          document.getElementById('max_response').textContent = (metrics.http_req_duration.values.max).toFixed(2) + ' ms';
        }
        
        // Populate error rate
        if (metrics.http_req_failed) {
          const errorRate = metrics.http_req_failed.values.rate * 100;
          document.getElementById('error_rate').textContent = errorRate.toFixed(2) + '%';
          document.getElementById('error_rate').className = errorRate > 5 ? 'metric-bad' : 'metric-good';
        }
        
        // Populate request count
        if (metrics.http_reqs) {
          document.getElementById('total_requests').textContent = metrics.http_reqs.values.count;
        }
        
        // Populate VU and iteration info
        if (metrics.vus) {
          document.getElementById('max_vus').textContent = metrics.vus.values.max;
        }
        if (metrics.iterations) {
          document.getElementById('total_iterations').textContent = metrics.iterations.values.count;
        }
      }
    }
    
    function createCharts(data) {
      // Create a response time chart
      if (data.metrics && data.metrics.http_req_duration) {
        new Chart(document.getElementById('responseTimeChart'), {
          type: 'line',
          data: {
            labels: Object.keys(data.metrics.http_req_duration.values).filter(key => 
              !['avg', 'min', 'max', 'med', 'p(90)', 'p(95)'].includes(key)),
            datasets: [{
              label: 'Response Time (ms)',
              data: Object.values(data.metrics.http_req_duration.values).filter((_, i) => 
                !['avg', 'min', 'max', 'med', 'p(90)', 'p(95)'].includes(Object.keys(data.metrics.http_req_duration.values)[i])),
              borderColor: '#3498db',
              backgroundColor: 'rgba(52, 152, 219, 0.2)',
              borderWidth: 2,
              tension: 0.4
            }]
          },
          options: {
            responsive: true,
            plugins: {
              title: {
                display: true,
                text: 'Response Time Distribution'
              }
            },
            scales: {
              y: {
                beginAtZero: true,
                title: {
                  display: true,
                  text: 'Response Time (ms)'
                }
              }
            }
          }
        });
      }
    }
  </script>
</head>
<body>
  <h1>Ticketly Load Test Report</h1>
  <div class="summary-box">
    <p><strong>Scenario:</strong> $SCENARIO</p>
    <p><strong>Environment:</strong> $ENVIRONMENT</p>
    <p><strong>Date/Time:</strong> $(date)</p>
  </div>
  
  <div id="loading">Loading test data...</div>
  
  <div id="report-content" style="display:none;">
    <h2>Test Summary</h2>
    <div class="container">
      <div class="card">
        <h3>Response Times</h3>
        <table>
          <tr><td>Average Response Time</td><td id="avg_response">-</td></tr>
          <tr><td>95th Percentile</td><td id="p95_response">-</td></tr>
          <tr><td>Maximum Response Time</td><td id="max_response">-</td></tr>
        </table>
      </div>
      
      <div class="card">
        <h3>Test Metrics</h3>
        <table>
          <tr><td>Total Requests</td><td id="total_requests">-</td></tr>
          <tr><td>Error Rate</td><td id="error_rate">-</td></tr>
          <tr><td>Max VUs</td><td id="max_vus">-</td></tr>
          <tr><td>Total Iterations</td><td id="total_iterations">-</td></tr>
        </table>
      </div>
    </div>
    
    <h2>Response Time Chart</h2>
    <div class="chart-container">
      <canvas id="responseTimeChart"></canvas>
    </div>
    
    <p>
      <strong>Note:</strong> For detailed metrics, please review the JSON output file at 
      <code>$(basename $JSON_OUTPUT_FILE)</code>.
    </p>
  </div>
</body>
</html>
EOF

echo "✅ Load test completed"
echo "⏱️  $(date)"

# Print results summary
echo ""
echo "📊 Test Results Summary:"
echo "──────────────────────────────────────────"
echo "Scenario:    $SCENARIO"
echo "Environment: $ENVIRONMENT"
if [[ -f "$JSON_OUTPUT_FILE" ]]; then
  echo "JSON Report:  $JSON_OUTPUT_FILE"
fi
if [[ -f "$CSV_OUTPUT_FILE" ]]; then
  echo "CSV Report:   $CSV_OUTPUT_FILE"
fi
echo "Log File:    $LOG_FILE"
echo "──────────────────────────────────────────"