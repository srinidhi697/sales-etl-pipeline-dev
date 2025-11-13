# -----------------------------
# EventBridge Rule for S3 Upload
# -----------------------------
# -----------------------------
resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "${var.project}-${var.env}-s3-upload-rule"
  description = "Trigger Step Function when file uploaded to S3 raw bucket"

  event_pattern = jsonencode({
    source       = ["aws.s3"]
    detail-type  = ["Object Created"]
    detail = {
      bucket = {
        name = [var.raw_bucket_name]
      }
      object = {
        key = [{ prefix = "raw/sales/" }]
      }
    }
  })
}

# -----------------------------
# EventBridge Target → Step Function
# -----------------------------
resource "aws_cloudwatch_event_target" "step_function_target" {
  rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
  target_id = "StepFunctionTarget"
  arn       = var.sfn_arn   # Step Function ARN passed from root
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# -----------------------------
# IAM Role for EventBridge
# -----------------------------
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project}-${var.env}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Allow EventBridge to Start Step Function Execution
resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${var.project}-${var.env}-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = var.sfn_arn
      }
    ]
  })
}
