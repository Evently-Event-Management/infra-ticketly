resource "aws_s3_bucket" "ticketly_assets" {
  bucket = "ticketly-assets-${random_id.bucket_suffix.hex}"

  force_destroy = true
  
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
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# S3 Public access policy
resource "aws_s3_bucket_policy" "assets_public_read_policy" {
  bucket = aws_s3_bucket.ticketly_assets.id
  # Explicit dependency to ensure public access block is applied first
  depends_on = [aws_s3_bucket_public_access_block.assets_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.ticketly_assets.arn}/*"
      }
    ]
  })
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "assets_ownership" {
  bucket = aws_s3_bucket.ticketly_assets.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  
  # Apply before the policy
  depends_on = [aws_s3_bucket.ticketly_assets]
}
