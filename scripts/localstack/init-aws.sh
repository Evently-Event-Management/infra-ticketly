#!/bin/bash
echo "--- Initializing LocalStack AWS resources ---"

# Set region and endpoint for clarity
REGION="us-east-1"
ENDPOINT_URL="http://localhost:4566"

# Create S3 bucket for file uploads
echo "Creating S3 bucket for file uploads..."
awslocal s3 mb s3://event-seating-uploads

# Set bucket policy to public read
echo "Setting bucket policy..."
awslocal s3api put-bucket-acl --bucket event-seating-uploads --acl public-read

echo "S3 bucket initialization completed!"

# Create the SQS queue for the scheduler target
echo "Creating SQS queue..."
awslocal sqs create-queue --queue-name session-on-sale-queue --region ${REGION} --endpoint-url ${ENDPOINT_URL}

# Create the IAM role that the scheduler will use to send messages to SQS
echo "Creating IAM role for scheduler..."
awslocal iam create-role --role-name EventBridgeSchedulerRole --assume-role-policy-document file:///etc/localstack/init/ready.d/scheduler-role-policy.json --region ${REGION} --endpoint-url ${ENDPOINT_URL}

# ✅ The Fix: Create the EventBridge Scheduler Group
echo "Creating EventBridge Scheduler group..."
awslocal scheduler create-schedule-group --name event-ticketing-schedules --region ${REGION} --endpoint-url ${ENDPOINT_URL}

echo "--- AWS resource initialization complete ---"
