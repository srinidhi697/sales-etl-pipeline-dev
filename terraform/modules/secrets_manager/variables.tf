########################################
# Variables for Secrets
########################################

variable "project" {
  type        = string
  description = "Project name"
}

variable "env" {
  type        = string
  description = "Environment (dev, prod, etc.)"
}

variable "redshift_username" {
  type        = string
  description = "Redshift master username"
}

variable "redshift_password" {
  type        = string
  sensitive   = true
  description = "Redshift master password"
}

variable "redshift_role_arn" {
  type        = string
  description = "IAM Role ARN for Redshift COPY"
}

variable "sns_email" {
  type        = string
  description = "SNS notification email"
}