@echo off
setlocal enabledelayedexpansion

echo 🎫 Setting up Event Ticketing Keycloak...

:: Create folder structure
echo 📁 Creating folder structure...
mkdir realm-config
mkdir scripts

:: Check if realm config exists
if not exist "realm-config\event-ticketing-realm.json" (
    echo ❌ realm-config\event-ticketing-realm.json not found!
    echo Please make sure you have the realm configuration file.
    exit /b 1
)

:: Start services
echo 🐳 Starting Docker services...
docker-compose down -v
docker-compose up -d

echo ⏳ Waiting for Keycloak to start (this takes ~60 seconds)...
timeout /t 60 >nul

:: Check if Keycloak is ready
echo 🔍 Checking if Keycloak is ready...
:check_keycloak
curl http://localhost:8080/realms/master >nul 2>&1
if errorlevel 1 (
    echo ⏳ Still waiting for Keycloak...
    timeout /t 10 >nul
    goto check_keycloak
)

echo ✅ Keycloak is ready!
echo.
echo 🎉 Setup Complete!
echo.
echo 📋 Access Information:
echo    Keycloak Admin: http://localhost:8080
echo    Username: admin
echo    Password: admin123
echo.
echo 🔐 Test Users (all using @yopmail.com):
echo    System Admin: admin@yopmail.com / admin123
echo    Event Organizer: organizer@yopmail.com / organizer123
echo    Ticket Buyer: buyer@yopmail.com / buyer123
echo.
echo 📧 Check emails at: https://yopmail.com
echo.
echo 🎯 Your realm: event-ticketing
echo    Frontend Client ID: event-frontend
echo    Service Client IDs: events-service, tickets-service, payments-service
