resource "aws_s3_bucket" "ticketly_assets" {
  bucket = "ticketly-assets-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "TicketlyAssets"
  }
}

# Generate random suffix for globally unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket public access block - keep blocked for security
resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket = aws_s3_bucket.ticketly_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "assets_ownership" {
  bucket = aws_s3_bucket.ticketly_assets.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
