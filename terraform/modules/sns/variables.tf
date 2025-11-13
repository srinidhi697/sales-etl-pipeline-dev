variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "sns_email_secret_arn" { type = string }
