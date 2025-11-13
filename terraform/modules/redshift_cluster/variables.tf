variable "project" { type = string }
variable "env"     { type = string }
variable "region"  { type = string }

variable "vpc_id" {
  type = string
}

variable "redshift_username_secret_arn" { type = string }
variable "redshift_password_secret_arn" { type = string }
variable "redshift_role_secret_arn"     { type = string }

