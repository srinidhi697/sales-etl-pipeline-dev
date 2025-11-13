variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "sales-etl-pipeline"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  type = string
}


variable "data_lake_bucket_arn" {
  description = "ARN of the data lake S3 bucket"
  type        = string
}

variable "redshift_cluster_id" {
  type = string
}

variable "redshift_db_name" {
  type        = string
  description = "The Redshift database name (e.g. sales_dw)"
}


variable "redshift_user" {
  type    = string
  default = "etl_user"
}

variable "log_group_name" {
  type = string
}

variable "gold_bucket_path" {
  type = string
}

variable "redshift_username" {
  type        = string
  description = "Redshift master username (raw, stored in Secrets Manager)"
}

variable "redshift_password" {
  type        = string
  description = "Redshift master password (raw, stored in Secrets Manager)"
  sensitive   = true
}

variable "redshift_role_arn" {
  type        = string
  description = "Redshift IAM Role ARN"
}

variable "sns_email" {
  type        = string
  description = "Email for SNS subscription"
}
