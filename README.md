# Keycloak Infras### Roles
- **role-system-admin**: Platform administrators who can approve events and manage the system
- **role-user**: General users who can create and manage events (default role)

### Users (Development)
| Username | Email | Password | Roles |
|----------|-------|----------|-------|
| admin@yopmail.com | admin@yopmail.com | admin123 | role-system-admin |
| user@yopmail.com | user@yopmail.com | user123 | role-user |

### Clients
- **events-service**: Resource server (bearer-only) for the Events microservice
  - Bearer-only client (no secret required)
  - Used for token validation only
- **login-testing**: Public client for authentication testing
  - Supports password grant for development/testing
  - Used for obtaining tokensvent Ticketing Platform

This repository contains the Keycloak setup for the Event Ticketing Platform, providing authentication and authorization services for the microservices architecture.

## Deployment Options

This infrastructure supports two deployment methods:
1. **Docker Compose** - Quick setup for development and testing
2. **Terraform** - Infrastructure as Code for production and automated deployments

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
- For Terraform: Terraform >= 1.0 installed

## Deployment Method 1: Docker Compose (Development)

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
   - Client `login-testing` is available for authentication

## Deployment Method 2: Terraform (Production)

### Overview
The Terraform configuration provides Infrastructure as Code (IaC) for deploying and managing the Keycloak realm configuration. This method is recommended for production environments and CI/CD pipelines.

### Terraform Structure
```
terraform/
├── main.tf          # Provider configuration
├── realm.tf         # Realm configuration with security settings
├── role.tf          # Role definitions and default roles
├── clients.tf       # Client configurations (events-service, login-testing)
├── users.tf         # User creation and role assignments
├── variables.tf     # Input variables with defaults
├── outputs.tf       # Output values for integration
└── terraform.tfvars # Environment-specific values
```

### Terraform Prerequisites
1. **Keycloak Server Running**: Ensure Keycloak is accessible
   ```bash
   # Start Keycloak with Docker Compose (infrastructure only)
   docker-compose up -d
   ```

2. **Terraform Installed**: Version >= 1.0
   ```bash
   # Verify installation
   terraform version
   ```

### Terraform Deployment

#### Initialize Terraform
```bash
cd terraform
terraform init
```

#### Plan Deployment
```bash
# Review what will be created
terraform plan

# Plan with custom variables
terraform plan -var="keycloak_url=https://your-keycloak.com"
```

#### Apply Configuration
```bash
# Apply with confirmation
terraform apply

# Apply without confirmation (CI/CD)
terraform apply -auto-approve
```

#### View Current State
```bash
# List all resources
terraform state list

# Show specific resource
terraform show keycloak_realm.event_ticketing
```

### Terraform Variables

#### Required Variables
```hcl
# terraform.tfvars
keycloak_url              = "http://localhost:8080"
keycloak_admin_username   = "admin"
keycloak_admin_password   = "admin123"
```

#### Optional Variables (with defaults)
```hcl
# Realm Configuration
realm_name               = "event-ticketing"
realm_display_name       = "Event Ticketing Platform"

# SMTP Configuration
smtp_host               = "smtp.gmail.com"
smtp_port               = "587"
smtp_from_email         = "noreply@eventtickets.local"
smtp_from_display_name  = "Event Ticketing Platform"

# User Configuration
admin_email             = "admin@yopmail.com"
admin_password          = "admin123"
regular_user_email      = "user@yopmail.com"
regular_user_password   = "user123"
```

### Terraform Outputs
After successful deployment, Terraform provides:
```hcl
realm_id                  = "event-ticketing"
realm_name               = "event-ticketing"
admin_user_id            = "user-uuid"
regular_user_id          = "user-uuid"
system_admin_role_id     = "role-uuid"
user_role_id             = "role-uuid"
events_service_client_id = "events-service"
login_testing_client_id  = "login-testing"
```

### Terraform vs Docker Compose

| Feature | Docker Compose | Terraform |
|---------|----------------|-----------|
| **Use Case** | Development, Quick Setup | Production, CI/CD |
| **Configuration** | JSON Import | HCL (Infrastructure as Code) |
| **State Management** | Manual | Automatic State Tracking |
| **Rollback** | Manual | `terraform apply` previous version |
| **Drift Detection** | None | `terraform plan` shows changes |
| **Integration** | Manual export/import | Programmatic outputs |
| **Secrets** | Hardcoded in JSON | Variable-based, external sources |

### Managing Configuration Changes

#### With Terraform (Recommended)
```bash
# Make changes to .tf files
# Plan changes
terraform plan

# Apply changes
terraform apply

# Export current state if needed
terraform show -json > current-state.json
```

#### Hybrid Approach
1. Use Docker Compose for initial development
2. Export configuration from Keycloak admin console
3. Convert to Terraform for production deployment

### Terraform Best Practices

#### Environment Management
```bash
# Use workspace for different environments
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Switch environments
terraform workspace select production
```

#### Variable Management
```bash
# Environment-specific variable files
terraform apply -var-file="environments/production.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

#### State Management
```bash
# Use remote state for production
# Configure in main.tf:
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "keycloak/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Operations

### Docker Compose Operations

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

### Terraform Operations

#### Update Configuration
```bash
cd terraform

# Modify .tf files as needed
# Plan changes
terraform plan

# Apply changes
terraform apply
```

#### Destroy Resources
```bash
# Destroy all Terraform-managed resources
terraform destroy

# Destroy specific resource
terraform destroy -target=keycloak_user.admin
```

#### Import Existing Resources
```bash
# Import manually created resources into Terraform state
terraform import keycloak_realm.event_ticketing event-ticketing
terraform import keycloak_user.admin user-uuid
```

#### Refresh State
```bash
# Sync Terraform state with actual infrastructure
terraform refresh
```

#### Reset Terraform State
```bash
# Remove state file (careful!)
rm terraform.tfstate terraform.tfstate.backup

# Reinitialize
terraform init
terraform apply
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
  -d "client_id=login-testing" \
  -d "grant_type=password" \
  -d "username=admin@yopmail.com" \
  -d "password=admin123"
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy Keycloak Configuration

on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
          
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
        
      - name: Terraform Plan
        run: terraform plan
        working-directory: ./terraform
        env:
          TF_VAR_keycloak_admin_password: ${{ secrets.KEYCLOAK_ADMIN_PASSWORD }}
          
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: ./terraform
        env:
          TF_VAR_keycloak_admin_password: ${{ secrets.KEYCLOAK_ADMIN_PASSWORD }}
```

### Docker + Terraform Workflow
```bash
# 1. Start infrastructure
docker-compose up -d

# 2. Wait for Keycloak to be ready
while ! curl -f http://localhost:8080/health; do sleep 5; done

# 3. Apply Terraform configuration
cd terraform
terraform init
terraform apply -auto-approve

# 4. Verify deployment
terraform output
```

---

## Additional Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak Terraform Provider](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Terraform Documentation](https://www.terraform.io/docs)
