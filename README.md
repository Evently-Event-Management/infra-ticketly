# Keycloak Infrastructure for Event Ticketing Platform

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
  - Used for obtaining tokens
- **web-frontend**: Frontend SPA client for Next.js applications
  - Public client with PKCE support
  - Authorization Code flow enabled

### Default Client Roles
All users automatically receive these account management roles:
- **manage-account**: Allows users to manage their own account settings
- **view-profile**: Allows users to view their profile information

## Prerequisites

- **Docker and Docker Compose** installed
- **Port 8080** available on your system
- **Terraform >= 1.0** (for Infrastructure as Code deployment)
- **Gmail Account** (for SMTP email functionality)

## SMTP Configuration

### Gmail SMTP Setup

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "Mail"
3. **Set Environment Variables** (see configuration sections below)

### Required SMTP Variables
```bash
smtp_from_email = "your-email@gmail.com"
smtp_from_password = "your-app-password"
```

---

## Deployment Method 1: Docker Compose (Development)

### Quick Start
```bash
# Clone the repository
git clone <repository-url>
cd infra-keycloak

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f keycloak
```

### Docker Compose Commands

#### Starting the System
```bash
# Start all services (Keycloak + PostgreSQL)
docker-compose up -d

# Start with logs visible
docker-compose up

# Start specific service
docker-compose up -d postgres
docker-compose up -d keycloak
```

#### Viewing Logs
```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs keycloak
docker-compose logs postgres
```

#### Stopping Services
```bash
# Stop services (keeps containers and data)
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove containers and volumes (COMPLETE RESET)
docker-compose down -v

# Stop and remove everything including images
docker-compose down -v --rmi all
```

#### Service Management
```bash
# Restart services
docker-compose restart

# Restart specific service
docker-compose restart keycloak

# Check service status
docker-compose ps

# View resource usage
docker-compose top
```

#### Data Management
```bash
# Remove only volumes (reset database)
docker volume rm infra-keycloak_postgres_data

# List all volumes
docker volume ls

# Inspect volume
docker volume inspect infra-keycloak_postgres_data
```

### Access Points
- **Admin Console**: http://localhost:8080/admin
  - Username: `admin`
  - Password: `admin123`
- **Realm**: http://localhost:8080/realms/event-ticketing
- **Account Console**: http://localhost:8080/realms/event-ticketing/account

---

## Deployment Method 2: Terraform (Production)

### Terraform Structure
```
terraform/
├── main.tf          # Provider configuration
├── realm.tf         # Realm configuration with security settings
├── role.tf          # Role definitions and default roles
├── clients.tf       # Client configurations
├── users.tf         # User creation and role assignments
├── variables.tf     # Input variables with defaults
├── outputs.tf       # Output values for integration
└── terraform.tfvars # Environment-specific values (create this)
```

### Setting Up Terraform

#### 1. Prerequisites
```bash
# Verify Terraform installation
terraform version

# Ensure Keycloak is running
docker-compose up -d
```

#### 2. Configuration
Create a `terraform.tfvars` file in the `terraform/` directory:

```hcl
# terraform/terraform.tfvars

# Keycloak Connection
keycloak_url              = "http://localhost:8080"
keycloak_admin_username   = "admin"
keycloak_admin_password   = "admin123"

# SMTP Configuration (Required for email features)
smtp_from_email    = "your-email@gmail.com"
smtp_from_password = "your-gmail-app-password"

# Optional: Custom realm settings
realm_display_name = "Ticketly Event Ticketing Platform"

# Optional: Custom user credentials
admin_password     = "secure-admin-password"
regular_user_password = "secure-user-password"
```

#### 3. Environment Variables (Alternative to .tfvars)
```bash
# Set environment variables
export TF_VAR_smtp_from_email="your-email@gmail.com"
export TF_VAR_smtp_from_password="your-gmail-app-password"
export TF_VAR_keycloak_admin_password="admin123"

# On Windows (PowerShell)
$env:TF_VAR_smtp_from_email="your-email@gmail.com"
$env:TF_VAR_smtp_from_password="your-gmail-app-password"
$env:TF_VAR_keycloak_admin_password="admin123"
```

### Terraform Commands

#### Initialize Terraform
```bash
cd terraform

# Initialize Terraform (first time only)
terraform init

# Upgrade providers
terraform init -upgrade
```

#### Planning Changes
```bash
# Review what will be created/changed
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Plan with specific variables
terraform plan -var="smtp_from_email=your-email@gmail.com" -var="smtp_from_password=your-app-password"

# Plan with variable file
terraform plan -var-file="production.tfvars"
```

#### Applying Changes
```bash
# Apply with confirmation prompt
terraform apply

# Apply without confirmation (CI/CD)
terraform apply -auto-approve

# Apply saved plan
terraform apply tfplan

# Apply with variables
terraform apply -var="smtp_from_email=your-email@gmail.com" -var="smtp_from_password=your-app-password"
```

#### Viewing State
```bash
# List all resources
terraform state list

# Show specific resource details
terraform show keycloak_realm.event_ticketing

# Show all resources
terraform show

# Get outputs
terraform output

# Get specific output
terraform output realm_id
```

#### Destroying Resources
```bash
# Destroy all resources with confirmation
terraform destroy

# Destroy without confirmation
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=keycloak_user.admin

# Destroy with variables
terraform destroy -var="smtp_from_email=your-email@gmail.com"
```

#### Workspace Management
```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Switch workspace
terraform workspace select production

# Show current workspace
terraform workspace show
```

#### Troubleshooting
```bash
# Validate configuration
terraform validate

# Format code
terraform fmt

# Refresh state
terraform refresh

# Force unlock (if state is locked)
terraform force-unlock LOCK_ID

# Import existing resource
terraform import keycloak_realm.event_ticketing event-ticketing
```

### Terraform Best Practices

#### Variable Management
```bash
# Environment-specific configurations
terraform apply -var-file="environments/development.tfvars"
terraform apply -var-file="environments/production.tfvars"
```

#### State Management
```bash
# Backup state
cp terraform.tfstate terraform.tfstate.backup

# Remove resource from state (without destroying)
terraform state rm keycloak_user.admin

# Move resource in state
terraform state mv keycloak_user.old_name keycloak_user.new_name
```

---

## Configuration Variables

### Required Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `smtp_from_email` | Gmail address for sending emails | `admin@gmail.com` |
| `smtp_from_password` | Gmail app password | `abcd efgh ijkl mnop` |

### Optional Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `keycloak_url` | `http://localhost:8080` | Keycloak server URL |
| `realm_display_name` | `Event Ticketing Platform` | Display name for the realm |
| `admin_password` | `admin123` | Admin user password |
| `regular_user_password` | `user123` | Regular user password |

### Setting Variables

#### Method 1: terraform.tfvars file
```hcl
# terraform/terraform.tfvars
smtp_from_email = "admin@gmail.com"
smtp_from_password = "abcd efgh ijkl mnop"
keycloak_url = "https://your-keycloak-domain.com"
```

#### Method 2: Environment Variables
```bash
export TF_VAR_smtp_from_email="admin@gmail.com"
export TF_VAR_smtp_from_password="abcd efgh ijkl mnop"
```

#### Method 3: Command Line
```bash
terraform apply -var="smtp_from_email=admin@gmail.com" -var="smtp_from_password=abcd efgh ijkl mnop"
```

---

## Complete Workflows

### Development Workflow
```bash
# 1. Start infrastructure
docker-compose up -d

# 2. Wait for Keycloak to be ready
while ! curl -f http://localhost:8080/health 2>/dev/null; do 
  echo "Waiting for Keycloak..."
  sleep 5
done

# 3. Configure with Terraform
cd terraform
terraform init
terraform apply -auto-approve

# 4. Test the setup
curl http://localhost:8080/realms/event-ticketing/.well-known/openid_configuration
```

### Production Deployment
```bash
# 1. Set up environment variables
export TF_VAR_smtp_from_email="production@yourcompany.com"
export TF_VAR_smtp_from_password="secure-app-password"
export TF_VAR_keycloak_url="https://auth.yourcompany.com"

# 2. Plan deployment
cd terraform
terraform workspace select production
terraform plan -var-file="environments/production.tfvars"

# 3. Apply configuration
terraform apply -var-file="environments/production.tfvars"

# 4. Verify deployment
terraform output
```

### Reset to Clean State
```bash
# Complete reset (Docker Compose)
docker-compose down -v
docker system prune -f
docker-compose up -d

# Complete reset (Terraform)
cd terraform
terraform destroy -auto-approve
terraform apply -auto-approve
```

### Backup and Restore
```bash
# Backup database
docker exec keycloak-postgres pg_dump -U keycloak keycloak > backup.sql

# Export realm configuration
docker exec -it keycloak /opt/keycloak/bin/kc.sh export \
  --file /tmp/realm-backup.json \
  --realm event-ticketing \
  --users realm_file

# Copy backup from container
docker cp keycloak:/tmp/realm-backup.json ./backups/
```

---

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
  -d "username=user@yopmail.com" \
  -d "password=user123"
```

---

## Troubleshooting

### Common Issues

#### Port 8080 Already in Use
```bash
# Check what's using port 8080
netstat -ano | findstr :8080

# Change port in docker-compose.yml
ports:
  - "8081:8080"  # Use port 8081 instead
```

#### Keycloak Not Starting
```bash
# Check logs
docker-compose logs keycloak

# Ensure PostgreSQL is ready first
docker-compose up postgres
sleep 30
docker-compose up keycloak
```

#### SMTP Not Working
```bash
# Verify Gmail app password
# Check if 2FA is enabled on Gmail account
# Verify SMTP variables are set correctly

# Test SMTP settings in Keycloak admin console
# Realm Settings → Email → Test connection
```

#### Terraform State Issues
```bash
# If state is corrupted
terraform refresh

# If state is locked
terraform force-unlock LOCK_ID

# If resources drift
terraform plan  # Shows differences
terraform apply # Fixes drift
```

#### Database Connection Issues
```bash
# Reset database
docker-compose down
docker volume rm infra-keycloak_postgres_data
docker-compose up -d

# Check database logs
docker-compose logs postgres
```

### Health Checks
```bash
# Check if Keycloak is healthy
curl http://localhost:8080/health

# Check if realm is accessible
curl http://localhost:8080/realms/event-ticketing

# Check database connection
docker exec keycloak-postgres psql -U keycloak -d keycloak -c "SELECT 1;"
```

---

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
          TF_VAR_smtp_from_email: ${{ secrets.SMTP_FROM_EMAIL }}
          TF_VAR_smtp_from_password: ${{ secrets.SMTP_FROM_PASSWORD }}
          TF_VAR_keycloak_admin_password: ${{ secrets.KEYCLOAK_ADMIN_PASSWORD }}
          
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: ./terraform
        env:
          TF_VAR_smtp_from_email: ${{ secrets.SMTP_FROM_EMAIL }}
          TF_VAR_smtp_from_password: ${{ secrets.SMTP_FROM_PASSWORD }}
          TF_VAR_keycloak_admin_password: ${{ secrets.KEYCLOAK_ADMIN_PASSWORD }}
```

### Environment-Specific Deployments
```bash
# Development
terraform workspace select development
terraform apply -var-file="environments/dev.tfvars"

# Staging
terraform workspace select staging
terraform apply -var-file="environments/staging.tfvars"

# Production
terraform workspace select production
terraform apply -var-file="environments/prod.tfvars"
```

---

## Security Considerations

### Production Checklist
- [ ] Change default passwords
- [ ] Use HTTPS in production
- [ ] Configure proper hostname settings
- [ ] Set up proper SMTP credentials
- [ ] Use remote Terraform state
- [ ] Enable audit logging
- [ ] Configure backup strategy
- [ ] Set up monitoring and alerts

### Secrets Management
```bash
# Use environment variables for sensitive data
export TF_VAR_smtp_from_password="$(cat /path/to/secret)"

# Or use external secret management
# - AWS Secrets Manager
# - Azure Key Vault
# - HashiCorp Vault
```

---

## Additional Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak Terraform Provider](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)

---

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Keycloak logs: `docker-compose logs keycloak`
3. Validate Terraform configuration: `terraform validate`
4. Check the official documentation links provided
