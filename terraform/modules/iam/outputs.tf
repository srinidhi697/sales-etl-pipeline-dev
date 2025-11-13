output "glue_role_arn" {
  description = "IAM Role ARN for Glue"
  value       = aws_iam_role.glue_role.arn
}

output "step_functions_role_arn" {
  value = aws_iam_role.step_functions.arn
}

output "step_functions_role_name" {
  value = aws_iam_role.step_functions.name
}

output "redshift_copy_role_arn" {
  value = aws_iam_role.redshift_copy_role.arn
}


output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "eventbridge_role_arn" {
  value = aws_iam_role.eventbridge_role.arn
}
