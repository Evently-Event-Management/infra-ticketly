#!/bin/bash

# Exit on error
set -e

# infra values
MODE="infra"
CLEANUP=false
NO_RESTART=false
NO_SSL=false

# Function to show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --mode=MODE    Set the mode to use (infra or k8s). infra is 'infra'"
    echo "  --cleanup      Clean up existing configurations"
    echo "  --no-restart   Don't restart nginx after setup (useful with --cleanup)"
    echo "  --no-ssl       Skip SSL certificate setup"
    echo "  --help         Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --mode=infra"
    echo "  $0 --mode=k8s"
    echo "  $0 --cleanup"
    echo "  $0 --cleanup --no-restart"
    echo "  $0 --mode=k8s --no-ssl"
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --mode=*)
            MODE="${arg#*=}"
            if [[ "$MODE" != "infra" && "$MODE" != "k8s" ]]; then
                echo "Error: Invalid mode. Use 'infra' or 'k8s'."
                show_usage
                exit 1
            fi
            ;;
        --cleanup)
            CLEANUP=true
            ;;
        --no-restart)
            NO_RESTART=true
            ;;
        --no-ssl)
            NO_SSL=true
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            show_usage
            exit 1
            ;;
    esac
done

echo "Starting Nginx installation and configuration in $MODE mode..."

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# Install Certbot and Nginx plugin
echo "Installing Certbot and Nginx plugin..."
sudo apt install -y certbot python3-certbot-nginx

# Remove infra site
echo "Removing infra Nginx site..."
sudo rm -f /etc/nginx/sites-enabled/infra

# Create directory for sites if it doesn't exist
echo "Setting up directories..."
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# Copy configuration files to sites-available
echo "Copying configuration files to sites-available..."

# Get the script's directory path (more reliable than using pwd)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Show paths for debugging
echo "Script directory: $SCRIPT_DIR"
echo "Parent directory: $PARENT_DIR"
echo "Current directory: $(pwd)"

# Clean up if requested
if [[ "$CLEANUP" == "true" ]]; then
    echo "Cleaning up existing Nginx configurations..."
    sudo rm -f /etc/nginx/sites-enabled/api.dpiyumal.me.conf
    sudo rm -f /etc/nginx/sites-enabled/dozzle.dpiyumal.me.conf
    sudo rm -f /etc/nginx/sites-enabled/kafka.dpiyumal.me.conf
    sudo rm -f /etc/nginx/sites-enabled/logs.dpiyumal.me.conf
    sudo rm -f /etc/nginx/sites-available/api.dpiyumal.me.conf
    sudo rm -f /etc/nginx/sites-available/dozzle.dpiyumal.me.conf
    sudo rm -f /etc/nginx/sites-available/kafka.dpiyumal.me.conf
    sudo rm -f /etc/nginx/sites-available/logs.dpiyumal.me.conf
    echo "Cleanup completed."
fi

# Set configuration directory based on mode
CONFIG_DIR="$PARENT_DIR/nginx/$MODE"
echo "Using configuration files from: $CONFIG_DIR"

# Check if the config directory exists
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "Error: Configuration directory $CONFIG_DIR does not exist."
    exit 1
fi

# Copy configuration files to sites-available
echo "Copying configuration files to sites-available..."
for conf_file in "$CONFIG_DIR"/*.conf; do
    if [[ -f "$conf_file" ]]; then
        filename=$(basename "$conf_file")
        echo "Setting up $filename configuration..."
        sudo cp "$conf_file" "/etc/nginx/sites-available/$filename"
        echo "Creating symbolic link for $filename..."
        sudo ln -sf "/etc/nginx/sites-available/$filename" "/etc/nginx/sites-enabled/$filename"
    fi
done

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    if [[ "$CLEANUP" == "true" && "$NO_RESTART" == "true" ]]; then
        echo "Cleanup completed without restarting Nginx as requested."
    else
        # Reload Nginx to apply changes
        echo "Reloading Nginx..."
        sudo systemctl reload nginx
        
        if [[ "$NO_SSL" != "true" && "$CLEANUP" != "true" ]]; then
            # Get list of domains from configuration files
            DOMAINS=()
            for conf_file in "$CONFIG_DIR"/*.conf; do
                if [[ -f "$conf_file" ]]; then
                    domain=$(basename "$conf_file" .conf)
                    DOMAINS+=("$domain")
                fi
            done
            
            # Prepare domain args for certbot
            DOMAIN_ARGS=""
            for domain in "${DOMAINS[@]}"; do
                DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
            done
            
            # Obtain SSL certificates with Certbot
            if [[ -n "$DOMAIN_ARGS" ]]; then
                echo "Obtaining SSL certificates from Let's Encrypt..."
                sudo certbot --nginx --non-interactive --agree-tos --email eventmate.22@gmail.com $DOMAIN_ARGS
                echo "SSL certificates obtained successfully."
                
                # Setup automatic renewal
                echo "Setting up automatic certificate renewal..."
                echo "0 3 * * * root certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null
            fi
        fi
    fi
    
    echo "Nginx installation and configuration completed successfully in '$MODE' mode!"
    echo "Your sites are now accessible at:"
    for conf_file in "$CONFIG_DIR"/*.conf; do
        if [[ -f "$conf_file" ]]; then
            domain=$(basename "$conf_file" .conf)
            echo "https://$domain"
        fi
    done
else
    echo "Nginx configuration test failed. Please check your configuration files."
    exit 1
fi