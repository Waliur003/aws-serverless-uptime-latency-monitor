// Declare the S3 bucket for the Website Uptime Monitor dashboard
resource "aws_s3_bucket" "website_uptime_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Project   = "Website-Uptime-Monitor"
    ManagedBy = "Terraform"
  }
}


// Declare the S3 bucket website configuration for the Website Uptime Monitor dashboard
resource "aws_s3_bucket_website_configuration" "website_uptime_bucket_website_configuration" {
  bucket = aws_s3_bucket.website_uptime_bucket.id

  index_document {
    suffix = "index.html"
  }
}


// Declare the S3 bucket public access block for the Website Uptime Monitor bucket
resource "aws_s3_bucket_public_access_block" "website_uptime_bucket_public_access_block" {
  bucket = aws_s3_bucket.website_uptime_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


// Declare the S3 bucket policy for the Website Uptime Monitor dashboard
resource "aws_s3_bucket_policy" "website_uptime_bucket_policy" {
  bucket     = aws_s3_bucket.website_uptime_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.website_uptime_bucket_public_access_block]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_uptime_bucket.arn}/*"
      }
    ]
  })
}


// Declare the S3 object for the Website Uptime Monitor dashboard index.html
resource "aws_s3_object" "website_uptime_index_html" {
  bucket       = aws_s3_bucket.website_uptime_bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/index.html")
}