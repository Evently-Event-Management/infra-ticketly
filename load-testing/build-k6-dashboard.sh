#!/bin/bash

set -euo pipefail

echo "Building k6 with web-dashboard extension..."

# Check if xk6 is installed
if ! command -v xk6 &> /dev/null; then
    echo "ERROR: xk6 is not installed."
    echo "Install it with: go install go.k6.io/xk6/cmd/xk6@latest"
    exit 1
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "ERROR: Go is not installed."
    echo "Install it from: https://go.dev/dl/"
    exit 1
fi

# Build k6 with the dashboard extension
xk6 build \
    --with github.com/grafana/xk6-dashboard@latest

echo ""
echo "✓ Custom k6 binary built successfully!"
echo ""
echo "Usage:"
echo "  ./k6 run --out web-dashboard query-test.js"
echo ""
echo "The dashboard will be available at http://localhost:5665"
echo ""
echo "To replace system k6 with this build:"
echo "  sudo mv k6 /usr/local/bin/k6"
