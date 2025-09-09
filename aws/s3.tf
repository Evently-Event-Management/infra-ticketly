# storage.tf (RECOMMENDED)

resource "aws_s3_bucket" "ticketly_assets" {
  bucket = "ticketly-assets-${terraform.workspace}-${random_id.bucket_suffix.hex}"
  tags   = { Name = "TicketlyAssets-${terraform.workspace}" }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Step 1: Enforce bucket owner ownership and disable ACLs.
resource "aws_s3_bucket_ownership_controls" "assets_ownership" {
  bucket = aws_s3_bucket.ticketly_assets.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Step 2: Set the bucket's base ACL to private.
# The bucket policy below will grant public access to the objects inside.
resource "aws_s3_bucket_acl" "assets_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.assets_ownership]
  bucket     = aws_s3_bucket.ticketly_assets.id
  acl        = "private"
}

# Step 3: Configure public access block to allow the bucket policy.
resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket = aws_s3_bucket.ticketly_assets.id

  block_public_acls       = true
  block_public_policy     = false # Allow our public policy
  ignore_public_acls      = true
  restrict_public_buckets = false # Allow public access via the policy
}

# Step 4: Apply the policy to make objects publicly readable.
resource "aws_s3_bucket_policy" "assets_public_read_policy" {
  bucket = aws_s3_bucket.ticketly_assets.id

  # Depend on the public access block to ensure correct apply order
  depends_on = [aws_s3_bucket_public_access_block.assets_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.ticketly_assets.arn}/*"
    }]
  })
}