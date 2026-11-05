// Declare the SNS topic for Website Uptime Monitor outage notifications
resource "aws_sns_topic" "website_uptime_topic" {
  name = var.sns_topic_name
}


// Declare the SNS topic subscription for Website Uptime Monitor email alerts
resource "aws_sns_topic_subscription" "website_uptime_subscription" {
  topic_arn = aws_sns_topic.website_uptime_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}


// Declare the SNS topic policy for Website Uptime Monitor alerts
resource "aws_sns_topic_policy" "website_uptime_topic_policy" {
  arn = aws_sns_topic.website_uptime_topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.website_uptime_topic.arn
      }
    ]
  })
}