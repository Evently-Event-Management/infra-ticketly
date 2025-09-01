smtp_from_password = "your-gmail-app-password"
smtp_from_password = "abcd efgh ijkl mnop"
on:
jobs:

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
