#!/bin/bash

# Exit on error
set -e

echo "Starting Nginx installation and configuration..."

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# Install Certbot and Nginx plugin
echo "Installing Certbot and Nginx plugin..."
sudo apt install -y certbot python3-certbot-nginx

# Remove default site
echo "Removing default Nginx site..."
sudo rm -f /etc/nginx/sites-enabled/default

# Create directory for sites if it doesn't exist
echo "Setting up directories..."
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# Copy configuration files to sites-available
echo "Copying configuration files to sites-available..."

# Move up one directory to access the nginx folder
PARENT_DIR="$(dirname "$(pwd)")"

# API configuration
echo "Setting up api.dpiyumal.me configuration..."
sudo cp $PARENT_DIR/nginx/api.dpiyumal.me.conf /etc/nginx/sites-available/api.dpiyumal.me.conf

# Dozzle configuration
echo "Setting up dozzle.dpiyumal.me configuration..."
sudo cp $PARENT_DIR/nginx/dozzle.dpiyumal.me.conf /etc/nginx/sites-available/dozzle.dpiyumal.me.conf

# Kafka configuration
echo "Setting up kafka.dpiyumal.me configuration..."
sudo cp $PARENT_DIR/nginx/kafka.dpiyumal.me.conf /etc/nginx/sites-available/kafka.dpiyumal.me.conf

# Create symbolic links in sites-enabled
echo "Creating symbolic links in sites-enabled..."
sudo ln -sf /etc/nginx/sites-available/api.dpiyumal.me.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/dozzle.dpiyumal.me.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/kafka.dpiyumal.me.conf /etc/nginx/sites-enabled/

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Reload Nginx to apply changes
echo "Reloading Nginx..."
sudo systemctl reload nginx

# Obtain SSL certificates with Certbot
echo "Obtaining SSL certificates from Let's Encrypt..."
sudo certbot --nginx --non-interactive --agree-tos --email eventmate.22@gmail.com \
  -d api.dpiyumal.me -d dozzle.dpiyumal.me -d kafka.dpiyumal.me

echo "SSL certificates obtained successfully."

# Setup automatic renewal
echo "Setting up automatic certificate renewal..."
echo "0 3 * * * root certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null

echo "Nginx installation and configuration completed successfully!"
echo "Your sites are now accessible at:"
echo "https://api.dpiyumal.me"
echo "https://dozzle.dpiyumal.me"
echo "https://kafka.dpiyumal.me"