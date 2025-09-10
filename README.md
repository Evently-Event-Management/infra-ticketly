smtp_from_password = "your-gmail-app-password"
smtp_from_password = "abcd efgh ijkl mnop"
on:
jobs:

# Docker Compose Setup

The project uses Docker Compose with an override strategy to support both production and development environments:

- `docker-compose.yml` - Base configuration for production environment
- `docker-compose.override.yml` - Development overrides (automatically applied when running `docker-compose up`)

## Development Environment

To start the development environment:

```bash
# Create .env file with required environment variables
cp .env.example .env
# Edit .env with your local values

# Start all services
docker-compose up -d

# To verify all services are running
docker-compose ps
```

The development setup includes:
- Local PostgreSQL database
- Local Keycloak instance for authentication
- MongoDB for query service
- Redis for caching
- Kafka for event streaming
- Debezium for CDC (Change Data Capture)
- All application services with local configuration
- All services exposed to host for direct access
- Services configured to connect to apps running locally via `host.docker.internal`

## Production Environment

To run the production configuration:

```bash
# Ensure you have the appropriate .env file with production values
cp .env.prod .env

# Use the base configuration only (ignoring override file)
docker-compose -f docker-compose.yml up -d
```

The production environment uses:
- RDS for PostgreSQL databases
- External Keycloak instance
- Same supporting services (Redis, Kafka, MongoDB) 
- Inter-service communication via Docker network (no host.docker.internal)
- Minimal port exposure (only API gateway and admin UIs)

For local development, add the following entry to your `/etc/hosts` file:

```
127.0.0.1 auth.ticketly.com
```

# Keycloak Infra Quick Guide

## 1. Start Keycloak and Database

Run this in the repo root:
```bash
docker-compose up -d
```

## 2. Configure with Terraform

Go to the terraform folder:
```bash
cd keycloak/terraform
```
Create a file named `terraform.tfvars` here with:
```hcl
smtp_from_email    = "your-email@gmail.com"
smtp_from_password = "your-gmail-app-password"
```

## 3. How to get Gmail App Password

1. Enable 2-Step Verification in your Gmail account
2. Go to Google Account > Security > App Passwords
3. Generate a new app password for "Mail"
4. Use your Gmail address and the generated password above in `terraform.tfvars`

## 4. Apply Terraform

```bash
terraform init
terraform apply
```

## 5. Default Credentials

- Keycloak Admin Console: http://localhost:8080/admin
  - Username: `admin`
  - Password: `admin123`

## That's it!
