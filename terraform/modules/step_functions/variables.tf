variable "project" { type = string }
variable "env"     { type = string }
variable "region" {}
variable "sfn_role_arn" {
  description = "IAM role ARN for Step Functions execution"
  type        = string
}

variable "sfn_role_name" {
  description = "Name of the Step Functions IAM role"
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the Lambda function"
  type        = string
}

variable "redshift_cluster_id" {
  type        = string
  description = "Redshift cluster identifier"
}

variable "redshift_db_name" {
  type        = string
  description = "Redshift database name"
}

variable "redshift_user" {
  type        = string
  description = "Redshift database user"
}

variable "redshift_role_arn" {
  type        = string
  description = "IAM role ARN for Redshift COPY"
}

variable "gold_bucket_path" {
  type        = string
  description = "S3 path for gold data"
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for ETL pipeline notifications"
  type        = string
}
