output "log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.this.name
}

output "error_alarm_name" {
  description = "CloudWatch Alarm Name for ETL errors"
  value       = aws_cloudwatch_metric_alarm.error_alarm.alarm_name
}
