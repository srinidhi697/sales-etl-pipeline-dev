resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.env}-alerts"
}


data "aws_secretsmanager_secret_version" "sns_email" {
  secret_id = var.sns_email_secret_arn
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = data.aws_secretsmanager_secret_version.sns_email.secret_string
}
