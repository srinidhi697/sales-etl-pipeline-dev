output "start_crawler_arn" {
  description = "ARN of the Lambda function that starts the crawler"
  value       = aws_lambda_function.start_crawler.arn
}
