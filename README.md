# Ticketly - Local Development Setup Guide 🎟️

Welcome to the Ticketly project\! This guide will walk you through setting up your local development environment to run the entire microservices stack on your machine.

## Prerequisites

Before you begin, please ensure you have the following tools installed and configured on your system.

  - [ ] **Git**: For cloning the repository.
  - [ ] **Docker & Docker Compose**: To run the application services. [Install Docker Desktop](https://www.docker.com/products/docker-desktop/).
  - [ ] **Terraform CLI**: To provision cloud and local infrastructure. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
  - [ ] **AWS CLI**: For interacting with AWS. [Install AWS CLI](https://aws.amazon.com/cli/).
  - [ ] **jq**: A command-line JSON processor used by our scripts.
      - **macOS**: `brew install jq`
      - **Linux (Debian/Ubuntu)**: `sudo apt-get install jq`
      - **Linux (Fedora)**: `sudo dnf install jq`
      - **Windows (with Chocolatey)**: `choco install jq`
  - [ ] **An AWS Account**: Each developer needs their own AWS account with an IAM user that has administrative permissions.
  - [ ] **A Terraform Cloud Account**: You will need a user token to access the project's organization.

-----

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

### 6\. Provision AWS Infrastructure

This step uses Terraform to create the necessary AWS resources (SQS, S3, etc.) in your personal AWS account.

1.  **Log in to Terraform Cloud**: This connects your local Terraform CLI to the remote backend.

    ```bash
    cd aws/
    terraform login
    ```

2.  **Create Your Developer Workspace**: This creates an isolated state for your infrastructure in Terraform Cloud. **Replace `<your-name>` with your name (e.g., `dev-piyumal`).**

    ```bash
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
    terraform init
    terraform apply
    ```

    Review the plan and type `yes` to provision the resources.

### 7\. Configure Local Keycloak

Next, we'll provision our local Keycloak container with the necessary realms, clients, and users using Terraform.

1.  **Start Keycloak and its Database**: We need the Keycloak container running so Terraform can connect to it.

    ```bash
    # From the project root
    docker-compose up -d keycloak ticketly-db
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

Happy Coding\!