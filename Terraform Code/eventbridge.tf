// Declare the CloudWatch event rule for the Website Uptime Monitor schedule
resource "aws_cloudwatch_event_rule" "website_uptime_event_rule" {
  name                = var.cloudwatch_event_rule_name
  description         = "CloudWatch event rule for Website Uptime Monitor 5-minute health checks"
  schedule_expression = "rate(5 minutes)"
}


// Declare the CloudWatch event target for the Website Uptime Monitor
resource "aws_cloudwatch_event_target" "website_uptime_event_target" {
  rule      = aws_cloudwatch_event_rule.website_uptime_event_rule.name
  target_id = "WebsiteUptimeMonitorLambda"
  arn       = aws_lambda_function.website_uptime_lambda.arn
}


// Declare the Lambda permission for CloudWatch EventBridge invocation
resource "aws_lambda_permission" "website_uptime_lambda_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.website_uptime_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.website_uptime_event_rule.arn
}