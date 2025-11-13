variable "project" {
  type        = string
  description = "Project name"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS Topic ARN for alarms"
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch Log Group name"
  default     = "/aws/etl/sales-pipeline"
}
