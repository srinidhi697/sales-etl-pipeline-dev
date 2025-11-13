output "eventbridge_rule_arn" {
  value = aws_cloudwatch_event_rule.s3_upload_rule.arn
}
