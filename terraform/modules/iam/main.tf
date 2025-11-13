data "aws_caller_identity" "current" {}

# Glue IAM Role
resource "aws_iam_role" "glue_role" {
  name = "${var.project}-${var.env}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "glue_policy" {
  name        = "${var.project}-${var.env}-glue-policy"
  description = "Glue job permissions for S3, Glue, and CloudWatch logging"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # S3 Access
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket","s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::${var.project}-${var.env}-datalake",
          "arn:aws:s3:::${var.project}-${var.env}-datalake/*"
        ]
      },
      # Glue Access
      {
        Effect   = "Allow"
        Action   = ["glue:*"]
        Resource = "*"
      },
      # CloudWatch Logs Access
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

# -----------------------------
# Step Functions IAM Role
# -----------------------------
resource "aws_iam_role" "step_functions" {
  name = "${var.project}-${var.env}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "states.amazonaws.com" },
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project}-${var.env}-sfn-policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # --- Allow Step Functions to trigger Glue jobs
      {
        Effect   = "Allow",
        Action   = ["glue:StartJobRun", "glue:GetJobRun", "glue:GetJobRuns"],
        Resource = [
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.project}-${var.env}-raw-to-silver",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.project}-${var.env}-silver-to-gold",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.project}-${var.env}-gold-to-redshift" 
        ]
      },
      # --- Allow Step Functions to start crawler (through Lambda)
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = var.lambda_arn
      },
      # --- Allow CloudWatch Logs
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}


# IAM Role for Redshift COPY (S3 + Glue access)
resource "aws_iam_role" "redshift_copy_role" {
  name = "${var.project}-${var.env}-redshift-copy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "redshift.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Allow Redshift to read from S3
resource "aws_iam_role_policy_attachment" "redshift_s3" {
  role       = aws_iam_role.redshift_copy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Allow Redshift to access Glue Data Catalog
resource "aws_iam_role_policy_attachment" "redshift_glue" {
  role       = aws_iam_role.redshift_copy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-${var.env}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project}-${var.env}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["glue:StartCrawler", "glue:GetCrawler"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project}-${var.env}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_invoke_sfn" {
  name = "${var.project}-${var.env}-eventbridge-invoke-sfn"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow EventBridge to trigger Step Functions
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = var.step_functions_arn
      },
      # Allow EventBridge to read S3 event details
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetBucketNotification",
          "s3:PutBucketNotification",
          "s3:GetObject"
        ]
        Resource = [
          var.data_lake_bucket_arn,          
          "${var.data_lake_bucket_arn}/*"    
        ]
      }
    ]
  })
}


# -----------------------------
# S3 Bucket Policy for Redshift COPY
# -----------------------------
resource "aws_s3_bucket_policy" "redshift_cross_access" {
  bucket = var.bucket  # you are already passing "${var.project}-${var.env}-datalake"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowRedshiftCopyFromS3",
        Effect   = "Allow",
        Principal = {
          AWS = "${aws_iam_role.redshift_copy_role.arn}"
        },
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket}",
          "arn:aws:s3:::${var.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "sfn_sns_policy" {
  name = "${var.project}-${var.env}-sfn-sns-policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      }
    ]
  })
}
