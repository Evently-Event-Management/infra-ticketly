# Keycloak Infrastructure for Event Ticketing Platform

This repository contains the Keycloak setup for the Event Ticketing Platform, providing authentication and authorization services for the microservices architecture.

## System Overview

### Keycloak Realm: `event-ticketing`
- **Display Name**: Event Ticketing Platform
- **Features**: User registration, email verification, password reset, brute force protection
- **SMTP**: Configured for Gmail (requires credentials)

### Roles
- **system-admin**: Platform administrators who can approve events and manage the system
- **user**: General users who can create and manage events (default role)

### Users (Development)
| Username | Email | Password | Roles |
|----------|-------|----------|-------|
| admin@yopmail.com | admin@yopmail.com | admin123 | system-admin, event-organizer, ticket-buyer |
| user@yopmail.com | user@yopmail.com | user123 | user |

### Clients
- **events-service**: Resource server (bearer-only) for the Events microservice
  - Public client (no secret required)
  - Bearer-only authentication
  - Used for token validation

## Getting Started

### Prerequisites
- Docker and Docker Compose installed
- Ports 8080 available on your system

### 1. Starting the System

#### Option A: Using Docker Compose (Recommended)
```bash
# Start all services (Keycloak + PostgreSQL)
docker-compose up -d

# View logs
docker-compose logs -f keycloak
```



### 2. Access Keycloak
- **Admin Console**: http://localhost:8080/admin
  - Username: `admin`
  - Password: `admin123`
- **Realm**: http://localhost:8080/realms/event-ticketing

### 3. First Time Setup Verification
1. Navigate to Admin Console
2. Select `event-ticketing` realm from dropdown
3. Verify:
   - Users are imported
   - Roles are configured
   - Client `events-service` is set up as bearer-only

## Operations

### 2. Rerunning the System

#### Full Restart
```bash
# Stop services
docker-compose down

# Start services (keeps data)
docker-compose up -d
```

#### Restart with Fresh Import
```bash
# Stop and remove containers (keeps volumes)
docker-compose down

# Start with fresh import
docker-compose up -d
```

#### Quick Restart (Keycloak only)
```bash
# Restart just Keycloak
docker-compose restart keycloak
```

### 3. Export Settings Changed from GUI

#### Export Entire Realm
```bash
# Export realm to file
docker exec -it keycloak /opt/keycloak/bin/kc.sh export \
  --file /tmp/event-ticketing-export.json \
  --realm event-ticketing \
  --users realm_file

# Copy exported file from container
docker cp keycloak:/tmp/event-ticketing-export.json ./realm-config/event-ticketing-realm-backup.json
```

#### Export Specific Components

**Export Users Only:**
```bash
docker exec -it keycloak /opt/keycloak/bin/kc.sh export \
  --file /tmp/users-only.json \
  --realm event-ticketing \
  --users realm_file \
  --users-per-file 50
```

**Export Clients Only:**
```bash
# Use Admin REST API to export specific clients
curl -X GET "http://localhost:8080/admin/realms/event-ticketing/clients" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json"
```

#### Manual Export via Admin Console
1. Go to Admin Console → Realm Settings → Action → Partial Export
2. Select what to export:
   - ✅ Export groups and roles
   - ✅ Export clients
   - ✅ Include users (if needed)
3. Download the JSON file
4. Replace `./realm-config/event-ticketing-realm.json` with exported content

### 4. Reset to Beginning

#### Complete Reset (Nuclear Option)
```bash
# Stop all services
docker-compose down

# Remove all containers, networks, and volumes
docker-compose down -v --remove-orphans

# Remove any leftover containers
docker system prune -f

# Start fresh
docker-compose up -d
```

#### Reset Database Only (Keep Images)
```bash
# Stop services
docker-compose down

# Remove only the database volume
docker volume rm infra-keycloak_postgres_data

# Start services (will recreate database)
docker-compose up -d
```

#### Reset to Original Configuration
```bash
# Stop services
docker-compose down -v

# Ensure you have the original realm config
git checkout HEAD -- realm-config/event-ticketing-realm.json

# Start fresh with original config
docker-compose up -d
```

## Configuration Details

### Environment Variables
- `POSTGRES_DB`: keycloak
- `POSTGRES_USER`: keycloak
- `POSTGRES_PASSWORD`: keycloak123
- `KEYCLOAK_ADMIN`: admin
- `KEYCLOAK_ADMIN_PASSWORD`: admin123

### Volumes
- `postgres_data`: PostgreSQL data persistence
- `./realm-config`: Realm configuration files mounted to `/opt/keycloak/data/import`

### Networks
- `keycloak-network`: Bridge network for service communication

## Development Notes

### SMTP Configuration
The realm is configured for Gmail SMTP but requires credentials:
```json
"smtpServer": {
  "host": "smtp.gmail.com",
  "port": "587",
  "auth": "false",
  "user": "",     // Add your Gmail username
  "password": ""  // Add your Gmail app password
}
```

### Security Considerations
- Change default passwords in production
- Use environment variables for sensitive data
- Enable HTTPS in production
- Configure proper hostname settings

### Token Configuration
The `events-service` client is configured as a resource server:
- **Bearer-only**: Only validates tokens, doesn't participate in browser flows
- **Public client**: No client secret required
- **Token validation**: Validates JWT tokens issued by Keycloak

## Troubleshooting

### Common Issues

1. **Port 8080 already in use**
   ```bash
   # Check what's using port 8080
   netstat -ano | findstr :8080
   
   # Change port in docker-compose.yml
   ports:
     - "8081:8080"  # Use port 8081 instead
   ```

2. **Keycloak not starting**
   ```bash
   # Check logs
   docker-compose logs keycloak
   
   # Common fix: ensure PostgreSQL is ready
   docker-compose up postgres
   # Wait 30 seconds, then:
   docker-compose up keycloak
   ```

3. **Realm not importing**
   ```bash
   # Verify file exists and has correct permissions
   ls -la realm-config/
   
   # Check import logs
   docker-compose logs keycloak | grep -i import
   ```

4. **Cannot access admin console**
   ```bash
   # Verify services are running
   docker-compose ps
   
   # Check if admin user was created
   docker-compose logs keycloak | grep -i admin
   ```

## API Endpoints

### Keycloak Endpoints
- **Admin Console**: http://localhost:8080/admin
- **Realm Discovery**: http://localhost:8080/realms/event-ticketing/.well-known/openid_configuration
- **Token Endpoint**: http://localhost:8080/realms/event-ticketing/protocol/openid-connect/token
- **Authorization Endpoint**: http://localhost:8080/realms/event-ticketing/protocol/openid-connect/auth
- **User Info**: http://localhost:8080/realms/event-ticketing/protocol/openid-connect/userinfo

### Example Token Request
```bash
curl -X POST http://localhost:8080/realms/event-ticketing/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=events-service" \
  -d "username=user@yopmail.com" \
  -d "password=user123"
```

---

For more information, visit the [Keycloak Documentation](https://www.keycloak.org/documentation).
