variable "project" {
  type = string
}
variable "env" {
  type = string
}
variable "bucket" {
  type = string
}
variable "glue_role_arn" {
  type = string
}

variable "redshift_cluster_id" {
  type = string
}

variable "redshift_db_name" {
  type    = string
  default = "sales_dw"   
}

variable "redshift_copy_role_arn" {
  type = string
}

variable "redshift_username_secret_arn" {
  type = string
}

variable "redshift_password_secret_arn" {
  type = string
}