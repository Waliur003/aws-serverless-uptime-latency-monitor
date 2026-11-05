// Declare the AWS region variable for the Website Uptime Monitor
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region where resources will be provisioned"
}


// Declare the target URL variable to monitor
variable "target_url" {
  type        = string
  default     = "https://checkip.amazonaws.com"
  description = "The target website URL for synthetic health check probes"
}


// Declare the alert email variable for outage notifications
variable "alert_email" {
  type        = string
  description = "The email address to receive downtime and outage alerts"
}


// Declare the S3 bucket name variable for the uptime status dashboard
variable "s3_bucket_name" {
  type        = string
  default     = "website-uptime-dashboard-sun-waliur-2026"
  description = "The globally unique name of the S3 dashboard bucket"
}


// Declare the DynamoDB table name variable for uptime history
variable "dynamodb_table_name" {
  type        = string
  default     = "website-uptime-history"
  description = "The name of the DynamoDB table storing time-series health logs"
}


// Declare the SNS topic name variable for uptime alerts
variable "sns_topic_name" {
  type        = string
  default     = "uptime-alert-topic"
  description = "The name of the SNS topic for outage alerts"
}


// Declare the Lambda function name variable for the health checker
variable "lambda_function_name" {
  type        = string
  default     = "uptime-health-checker"
  description = "The name of the Lambda function performing synthetic probes"
}


// Declare the IAM role name variable for the Lambda function
variable "iam_role_name" {
  type        = string
  default     = "WebsiteUptimeMonitorRole"
  description = "The name of the IAM execution role for the Lambda function"
}


// Declare the CloudWatch event rule name variable for scheduled health checks
variable "cloudwatch_event_rule_name" {
  type        = string
  default     = "uptime-check-schedule"
  description = "The name of the EventBridge rule triggering 5-minute health checks"
}