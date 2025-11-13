variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the crawler Lambda"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "step_functions_arn" {
  type = string
}

variable "bucket" {
  type = string
}

variable "data_lake_bucket_arn" {
  type        = string
  description = "ARN of the data lake S3 bucket"
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN to allow Step Functions to publish notifications"
  type        = string
}
