// Declare the DynamoDB table for Website Uptime Monitor time-series metrics
resource "aws_dynamodb_table" "website_uptime_history_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "site_url"
  range_key    = "timestamp"

  attribute {
    name = "site_url"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project   = "Website-Uptime-Monitor"
    ManagedBy = "Terraform"
  }
}