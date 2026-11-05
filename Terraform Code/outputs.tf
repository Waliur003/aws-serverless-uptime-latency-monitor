// Declare the output for the DynamoDB table name
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.website_uptime_history_table.name
  description = "The name of the DynamoDB table storing time-series health logs"
}


// Declare the output for the SNS topic ARN
output "sns_topic_arn" {
  value       = aws_sns_topic.website_uptime_topic.arn
  description = "The ARN of the SNS topic for Website Uptime Monitor notifications"
}


// Declare the output for the Lambda function ARN
output "lambda_function_arn" {
  value       = aws_lambda_function.website_uptime_lambda.arn
  description = "The ARN of the Lambda function for Website Uptime Monitor"
}


// Declare the output for the S3 dashboard public website URL
output "s3_dashboard_url" {
  value       = "http://${aws_s3_bucket_website_configuration.website_uptime_bucket_website_configuration.website_endpoint}"
  description = "The public website URL of the S3 uptime status dashboard"
}