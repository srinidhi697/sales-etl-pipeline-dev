output "data_lake_bucket_name" {
  description = "Main S3 data lake bucket name"
  value       = module.s3.bucket_name
}

output "glue_role_arn" {
  description = "IAM Role ARN for Glue"
  value       = module.iam.glue_role_arn
}

output "glue_crawler_name" {
  description = "Glue crawler created for raw data"
  value       = module.glue.glue_crawler_name
}

output "glue_database_name" {
  description = "Glue database created"
  value       = module.glue.glue_database_name
}

output "sns_topic_arn" {
  value       = module.sns.sns_topic_arn
  description = "SNS topic ARN for CloudWatch alarms"
}
