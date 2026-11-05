// Declare the IAM role for the Website Uptime Monitor Lambda function
resource "aws_iam_role" "website_uptime_lambda_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


// Declare the IAM policy document for the Website Uptime Monitor Lambda function
data "aws_iam_policy_document" "website_uptime_lambda_policy_document" {
  statement {
    sid    = "DynamoDBLogAccess"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.website_uptime_history_table.arn]
  }

  statement {
    sid    = "SNSPublishAlertAccess"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.website_uptime_topic.arn]
  }

  statement {
    sid    = "S3DashboardWriteAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.website_uptime_bucket.arn}/*"]
  }
}


// Declare the IAM policy for the Website Uptime Monitor Lambda function
resource "aws_iam_policy" "website_uptime_lambda_policy" {
  name   = "WebsiteUptimeMonitorExecutionPolicy"
  policy = data.aws_iam_policy_document.website_uptime_lambda_policy_document.json
}


// Attach the IAM policy to the Website Uptime Monitor Lambda function role
resource "aws_iam_role_policy_attachment" "website_uptime_lambda_role_policy_attachment" {
  role       = aws_iam_role.website_uptime_lambda_role.name
  policy_arn = aws_iam_policy.website_uptime_lambda_policy.arn
}


// Attach the AWSLambdaBasicExecutionRole policy to the Website Uptime Monitor Lambda function role
resource "aws_iam_role_policy_attachment" "website_uptime_lambda_basic_execution" {
  role       = aws_iam_role.website_uptime_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}