data "aws_caller_identity" "current" {}


# Allow Step Function role to trigger Glue jobs
resource "aws_iam_role_policy" "sfn_glue_policy" {
  name = "${var.project}-${var.env}-sfn-glue-policy"
  role = var.sfn_role_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:GetJob"
        ],
        Resource = [
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.project}-${var.env}-raw-to-silver",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.project}-${var.env}-silver-to-gold",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.project}-${var.env}-gold-to-redshift"
        ]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "${var.project}-${var.env}-etl-sm"
  role_arn = var.sfn_role_arn

  definition = <<EOF
{
  "Comment": "ETL Orchestration with SNS Notifications",
  "StartAt": "RunCrawler",
  "States": {
    "RunCrawler": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${var.lambda_arn}"
      },
      "Next": "RawToSilver"
    },
    "RawToSilver": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "${var.project}-${var.env}-raw-to-silver"
      },
      "Next": "SilverToGold"
    },
    "SilverToGold": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "${var.project}-${var.env}-silver-to-gold"
      },
      "Next": "GoldToRedshift"
    },
    "GoldToRedshift": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "${var.project}-${var.env}-gold-to-redshift",
        "Arguments": {
          "--REDSHIFT_CLUSTER_ID": "${var.redshift_cluster_id}",
          "--REDSHIFT_DB": "${var.redshift_db_name}",
          "--REDSHIFT_USER": "${var.redshift_user}",
          "--REDSHIFT_ROLE": "${var.redshift_role_arn}",
          "--SOURCE_PATH": "${var.gold_bucket_path}",
          "--TRUNCATE_FACT": "true"
        }
      },
      "Next": "NotifySuccess",
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "NotifyFailure"
        }
      ]
    },
    "NotifySuccess": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "${var.sns_topic_arn}",
        "Message": "ETL pipeline completed successfully!",
        "Subject": "ETL Pipeline Success"
      },
      "End": true
    },
    "NotifyFailure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "${var.sns_topic_arn}",
        "Message": "ETL pipeline FAILED! Check logs in CloudWatch.",
        "Subject": "ETL Pipeline Failure"
      },
      "End": true
    }
  }
}
EOF
}
