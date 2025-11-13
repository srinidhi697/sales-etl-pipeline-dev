########################################
# Secrets Manager - Store Sensitive Values
########################################

# --- Redshift Username ---
resource "aws_secretsmanager_secret" "redshift_username" {
  name = "${var.project}-${var.env}-redshift-username"
}

resource "aws_secretsmanager_secret_version" "redshift_username_value" {
  secret_id     = aws_secretsmanager_secret.redshift_username.id
  secret_string = var.redshift_username
}

# --- Redshift Password ---
resource "aws_secretsmanager_secret" "redshift_password" {
  name = "${var.project}-${var.env}-redshift-password"
}

resource "aws_secretsmanager_secret_version" "redshift_password_value" {
  secret_id     = aws_secretsmanager_secret.redshift_password.id
  secret_string = var.redshift_password
}

# --- Redshift Role ARN ---
resource "aws_secretsmanager_secret" "redshift_role" {
  name = "${var.project}-${var.env}-redshift-role"
}

resource "aws_secretsmanager_secret_version" "redshift_role_value" {
  secret_id     = aws_secretsmanager_secret.redshift_role.id
  secret_string = var.redshift_role_arn
}

# --- SNS Email ---
resource "aws_secretsmanager_secret" "sns_email" {
  name = "${var.project}-${var.env}-sns-email"
}

resource "aws_secretsmanager_secret_version" "sns_email_value" {
  secret_id     = aws_secretsmanager_secret.sns_email.id
  secret_string = var.sns_email
}
