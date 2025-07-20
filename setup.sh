#!/bin/bash

echo "🎫 Setting up Event Ticketing Keycloak..."

# Create folder structure
echo "📁 Creating folder structure..."
mkdir -p realm-config
mkdir -p scripts

# Check if realm config exists
if [ ! -f "realm-config/event-ticketing-realm.json" ]; then
    echo "❌ realm-config/event-ticketing-realm.json not found!"
    echo "Please make sure you have the realm configuration file."
    exit 1
fi

# Start services
echo "🐳 Starting Docker services..."
docker-compose down -v  # Clean start
docker-compose up -d

echo "⏳ Waiting for Keycloak to start (this takes ~60 seconds)..."
sleep 60

# Check if Keycloak is ready
echo "🔍 Checking if Keycloak is ready..."
until curl -f http://localhost:8080/realms/master > /dev/null 2>&1; do
    echo "⏳ Still waiting for Keycloak..."
    sleep 10
done

echo "✅ Keycloak is ready!"
echo ""
echo "🎉 Setup Complete!"
echo ""
echo "📋 Access Information:"
echo "   Keycloak Admin: http://localhost:8080"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "🔐 Test Users (all using @yopmail.com):"
echo "   System Admin: admin@yopmail.com / admin123"
echo "   Event Organizer: organizer@yopmail.com / organizer123"
echo "   Ticket Buyer: buyer@yopmail.com / buyer123"
echo ""
echo "📧 Check emails at: https://yopmail.com"
echo ""
echo "🎯 Your realm: event-ticketing"
echo "   Frontend Client ID: event-frontend"
echo "   Service Client IDs: events-service, tickets-service, payments-service"