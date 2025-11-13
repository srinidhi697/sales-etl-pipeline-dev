output "redshift_username_secret_arn" {
  value = aws_secretsmanager_secret.redshift_username.arn
}

output "redshift_password_secret_arn" {
  value = aws_secretsmanager_secret.redshift_password.arn
}

output "redshift_role_secret_arn" {
  value = aws_secretsmanager_secret.redshift_role.arn
}

output "sns_email_secret_arn" {
  value = aws_secretsmanager_secret.sns_email.arn
}
