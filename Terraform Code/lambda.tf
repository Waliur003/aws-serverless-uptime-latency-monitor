// Declare the archive file data source to package the Lambda function code
data "archive_file" "website_uptime_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}


// Declare the Lambda function for the Website Uptime Monitor
resource "aws_lambda_function" "website_uptime_lambda" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.website_uptime_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.website_uptime_lambda_zip.output_path
  source_code_hash = data.archive_file.website_uptime_lambda_zip.output_base64sha256
  timeout          = 15
  architectures    = ["x86_64"]

  environment {
    variables = {
      TARGET_URL     = var.target_url
      DYNAMODB_TABLE = aws_dynamodb_table.website_uptime_history_table.name
      SNS_TOPIC_ARN  = aws_sns_topic.website_uptime_topic.arn
      S3_BUCKET_NAME = aws_s3_bucket.website_uptime_bucket.id
    }
  }
}