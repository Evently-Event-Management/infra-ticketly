resource "aws_s3_bucket" "ticketly_assets" {
  bucket        = "ticketly-assets-${terraform.workspace}-${random_id.bucket_suffix.hex}"
  tags          = { Name = "TicketlyAssets-${terraform.workspace}" }
  force_destroy = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket                  = aws_s3_bucket.ticketly_assets.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "assets_public_read_policy" {
  bucket     = aws_s3_bucket.ticketly_assets.id
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
