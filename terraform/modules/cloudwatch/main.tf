# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = 14

  tags = {
    Project     = var.project
    Environment = var.env
  }
}

# Metric Filter - count ERROR logs
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.project}-${var.env}-error-count"
  log_group_name = aws_cloudwatch_log_group.this.name

  pattern = "?ERROR ?Error ?Exception ?Failed ?RuntimeError"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project}-${var.env}"
    value     = "1"
  }
}

# Alarm on ErrorCount > 0
resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "${var.project}-${var.env}-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.error_count.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.error_count.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when there are ERROR logs in ETL pipeline"
  alarm_actions       = [var.sns_topic_arn]

  tags = {
    Project     = var.project
    Environment = var.env
  }
}
