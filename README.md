# Ticketly - Local Development Setup Guide 🎟️

Welcome to the Ticketly project\! This guide will walk you through setting up your local development environment to run the entire microservices stack on your machine.

## Prerequisites

Before you begin, please ensure you have the following tools installed and configured on your system:

- [ ] **Git**: For cloning the repository.  
- [ ] **Docker & Docker Compose**: To run the application services. Install **Docker Desktop**.  
- [ ] **Terraform CLI**: To provision cloud and local infrastructure. Install **Terraform**.  
- [ ] **AWS CLI**: For interacting with AWS. Install **AWS CLI**.  
- [ ] **jq**: A command-line JSON processor used by our scripts.  
  - **macOS**: `brew install jq`  
  - **Linux (Debian/Ubuntu)**: `sudo apt-get install jq`  
  - **Linux (Fedora)**: `sudo dnf install jq`  
  - **Windows (Chocolatey)**: `choco install jq`  
- [ ] **An AWS Account**: Each developer needs their own AWS account with an IAM user that has administrative permissions.  
- [ ] **A Terraform Cloud Account**: You will need a user token to access the project's organization.  

---

## ⚙️ One-Time Setup

You only need to perform these steps the first time you set up the project on your machine.

### 1\. Clone the Repository

Start by cloning this repository to your local machine.

```bash
git clone https://github.com/Evently-Event-Management/infra-ticketly.git
cd infra-ticketly
```

### 2\. Configure Your Host Machine

For local development, we use `auth.ticketly.com` to access Keycloak. You need to tell your computer that this domain points to your local machine.

  - **Linux/macOS**: Edit `/etc/hosts`
  - **Windows**: Edit `C:\Windows\System32\drivers\etc\hosts`

Add the following line to the file:

```
127.0.0.1   auth.ticketly.com
```

### 3\. Place Required Credential Files

You need to place one secret file in the project for it to work:

1.  **GCP Credentials**: Place your `gcp-credentials.json` file inside the `./credentials/` directory.

### 4\. Create the Cross-Platform `.env` File

The `.env` file will be created automatically when you run the extract-secrets.sh script (covered later in this guide). The script detects your operating system and sets the correct Docker socket path.

> **Note**: The `.env` file is created in the project root. This file is listed in `.gitignore` and should not be committed.

### 5\. Handle Script Line Endings (CRITICAL for Windows Users)

Windows and Linux use different line endings, which can break shell scripts.

  - **If you are on Windows, you MUST use Git Bash or another MINGW-based terminal.**
  - Before running any other scripts, you may need to convert them to Unix-style line endings. If you encounter script errors, run `dos2unix` on the script files. **Do not open the scripts in a Windows-native editor like Notepad**, as it may change the line endings back.

  ```bash
  cd scripts/
  dos2unix extract-secrets.sh init-dbs.sh init-debezium.sh monitor-sqs-live.sh send-kafka-event.sh test-scheduler.sh
  ```

### 6\. Provision AWS Infrastructure

This step uses Terraform to create the necessary AWS resources (SQS, S3, etc.) in your personal AWS account.

1.  **Log in to Terraform Cloud**: This connects your local Terraform CLI to the remote backend.

    ```bash
    cd aws/
    terraform login
    ```

2.  **Create Your Developer Workspace**: This creates an isolated state for your infrastructure in Terraform Cloud. **Replace `<your-name>` with your name (e.g., `dev-piyumal`).**

    ```bash
    terraform init
    terraform workspace new dev-<your-name>
    ```

3.  **Configure Credentials in Terraform Cloud**:

      - Log in to the Terraform Cloud UI.
      - An admin must create a **Variable Set** for you (e.g., "AWS Credentials - Piyumal").
      - In this set, add your personal AWS IAM credentials as **Environment Variables** (mark them as sensitive):
          - `AWS_ACCESS_KEY_ID`
          - `AWS_SECRET_ACCESS_KEY`
          - `AWS_REGION` (e.g., `ap-south-1`)
      - Apply this variable set **only** to your new `infra-dev-<your-name>` workspace.

4.  **Initialize and Apply**:

    ```bash
    terraform apply
    ```

    Review the plan and type `yes` to provision the resources.

### 7\. Configure Local Keycloak

Next, we'll provision our local Keycloak container with the necessary realms, clients, and users using Terraform.

1.  **Start Keycloak and its Database**: We need the Keycloak container running so Terraform can connect to it.

    ```bash
    # From the project root
    docker compose up -d keycloak ticketly-db
    ```

2.  **Initialize and Apply Keycloak Config**:

    ```bash
    cd ../keycloak/terraform/

    # Initialize with the local development backend
    terraform init -backend-config=backend.dev.hcl

    # Apply the configuration to the running container
    terraform apply
    ```

    Review the plan and type `yes`.

3.  **Extract Client Secrets**: Before shutting down the containers, you need to extract the client secrets:

    ```bash
    # Go back to the project root
    cd ../../
    
    # Run the extract-secrets script to get client secrets from Keycloak
    ./scripts/extract-secrets.sh
    ```

4.  **Shut Down Temporary Containers**: Now that Keycloak is configured and secrets are extracted, we can stop the containers before running the full stack.

    ```bash
    # From the project root
    docker-compose down
    ```

-----

## 🚀 Running the Full Application

Once the one-time setup is complete, you're ready to start working. Note that extracting secrets (step 3 in the Keycloak setup) is typically needed only once, unless your infrastructure changes.

### 1\. Start Services

Launch the entire application stack.

```bash
# From the project root
docker-compose up -d
```

The first time you run this, it may take a while to download all the container images.

> **Note:** If you've made changes to your AWS infrastructure or need to refresh your environment variables, you would need to run `./scripts/extract-secrets.sh` with Keycloak containers running before starting all services.



-----

## 🖥️ Accessing Services

Your local development environment is now running\! Here are the main endpoints:

| Service               | Local URL                     | Credentials      |
| --------------------- | ----------------------------- | ---------------- |
| **API Gateway** | `http://localhost:8088`       | -                |
| **Keycloak Admin** | `http://auth.ticketly.com:8080` | `admin`/`admin123` |
| **Kafka UI** | `http://localhost:9000`       | -                |
| **Dozzle (Log Viewer)** | `http://localhost:9999`       | -                |

-----

## 🛠️ Useful Commands

  * **View All Logs**: Use Dozzle at `http://localhost:9999` or run `docker-compose logs -f`.
  * **View Logs for a Single Service**: `docker-compose logs -f <service-name>` (e.g., `order-service`).
  * **Stop All Services**: `docker-compose down`.
  * **Stop and Remove Volumes** (for a clean slate): `docker-compose down -v`.

-----

## 🌎 Production Environment Setup

Follow these steps to set up and deploy the production infrastructure on AWS.

### 1. Generate SSH Key for EC2 Instance

Before applying the production Terraform configuration, you need to generate an SSH key pair:

```bash
# Navigate to the aws directory
cd aws/

# Generate a new SSH key pair without passphrase
ssh-keygen -t rsa -b 2048 -f ticketly-key -N ""

# Set correct permissions on the private key
chmod 600 ticketly-key
```

### 2. Ensure SSH Keys Are in .gitignore

The `.gitignore` file already exists in the aws directory. If you generate new SSH keys, make sure they are excluded from git:

1. Check the `.gitignore` file in the aws directory to ensure it includes:

```
# Ignore SSH keys
ticketly-key
ticketly-key.pub
```

2. If you generate keys with different names, add those to the `.gitignore` file:

```bash
echo "your-custom-key-name" >> aws/.gitignore
echo "your-custom-key-name.pub" >> aws/.gitignore
```

### 3. Set Up Terraform for Production

Initialize Terraform and select the production workspace:

```bash
# Make sure you're in the aws directory
cd aws/

# Initialize Terraform
terraform init

# Select the production workspace
terraform workspace select infra-ticketly
```

### 4. Apply Production Infrastructure

Deploy the production infrastructure:

```bash
# Apply Terraform configuration
terraform apply
```

Review the plan carefully and type `yes` to provision the resources. This will create:
- VPC with public and private subnets
- EC2 instance with SSH access
- RDS PostgreSQL database
- S3 bucket for assets
- SQS queues for event handling
- IAM roles and policies
- EventBridge scheduler

### 5. Connect to the EC2 Instance

After the infrastructure is deployed, connect to your EC2 instance using:

```bash
# The command will be provided in Terraform outputs
ssh -i ticketly-key ubuntu@<EC2_PUBLIC_IP>

# Example:
# ssh -i ticketly-key ubuntu@65.0.29.156
```

### 6. Important Production Outputs

The following outputs are provided after Terraform apply:
- `ec2_ip`: Public IP address of the EC2 instance
- `ssh_command`: Command to SSH into the EC2 instance
- `ticketly_db_endpoint`: RDS database endpoint
- `s3_bucket_name`: S3 bucket for assets
- `sqs_session_scheduling_url`: URL for the session scheduling queue
- `sqs_trending_job_url`: URL for the trending job queue
- `sqs_session_reminders_url`: URL for the session reminders queue

To view these outputs again at any time:

```bash
terraform output
```

### 7. Production Infrastructure Maintenance

- **Update Infrastructure**: Make changes to Terraform files and run `terraform apply`
- **Destroy Infrastructure**: Run `terraform destroy` (use with caution!)
- **Access AWS Resources**: Use AWS console or CLI with appropriate credentials
- **Database Backups**: RDS creates automatic backups according to configuration
- **Monitoring**: Set up CloudWatch alarms for resource monitoring

Happy Coding\!