#!/bin/bash

# This script sets up k6 and its dependencies

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "k6 is not installed. Installing now..."
    
    # Install GPG key
    sudo gpg -k
    sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
    
    # Add k6 repository
    echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
    
    # Update and install k6
    sudo apt-get update
    sudo apt-get install -y k6
    
    echo "k6 installed successfully!"
else
    echo "k6 is already installed."
fi

# Check for Node.js (for formatting scripts)
if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. It's recommended for using Prettier."
    echo "You can install it with: sudo apt install nodejs npm"
fi

# Make scripts executable
chmod +x run-load-tests.sh
chmod +x run-docker-tests.sh

# Create output directory
mkdir -p output
chmod 777 output

# Install npm dependencies (if Node.js is available)
if command -v npm &> /dev/null; then
    npm install
fi

echo "✅ Setup complete! You can now run load tests with:"
echo "./run-load-tests.sh -s smoke"
echo "or"
echo "npm run test:smoke"