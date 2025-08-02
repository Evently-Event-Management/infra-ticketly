#!/bin/bash

# Create S3 bucket for file uploads
echo "Creating S3 bucket for file uploads..."
awslocal s3 mb s3://event-seating-uploads

# Set bucket policy to public read
echo "Setting bucket policy..."
awslocal s3api put-bucket-acl --bucket event-seating-uploads --acl public-read

echo "S3 bucket initialization completed!"
