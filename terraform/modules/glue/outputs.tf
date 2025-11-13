output "glue_crawler_name" {
  description = "The Glue Crawler name"
  value       = aws_glue_crawler.this.name
}

output "glue_database_name" {
  description = "The Glue Database name"
  value       = aws_glue_catalog_database.this.name
}

output "raw_to_silver_job" {
  value = aws_glue_job.raw_to_silver.name
}

output "silver_to_gold_job" {
  value = aws_glue_job.silver_to_gold.name
}

output "raw_to_silver_job_name" {
  value = aws_glue_job.raw_to_silver.name
}

output "silver_to_gold_job_name" {
  value = aws_glue_job.silver_to_gold.name
}
