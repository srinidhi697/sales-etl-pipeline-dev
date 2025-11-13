# -----------------------------
# Create the main S3 bucket
# -----------------------------
resource "aws_s3_bucket" "this" {
  bucket        = "${var.project}-${var.env}-datalake"
  force_destroy = true   # allows bucket to be destroyed even if not empty (useful for dev)
}

# -----------------------------
# Enable versioning
# -----------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------
# Block public access
# -----------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------
# Create folder structure (raw, silver, gold)
# -----------------------------
resource "aws_s3_object" "folders" {
  for_each = toset(["raw/", "silver/", "gold/"])

  bucket  = aws_s3_bucket.this.id
  key     = each.value
  content = ""   # empty object to represent "folder"
}

# Upload raw_to_silver.py into scripts/ folder in S3
resource "aws_s3_object" "raw_to_silver_script" {
  bucket = aws_s3_bucket.this.id
  key    = "scripts/raw_to_silver.py"
  source = "${path.root}/../src/raw_to_silver.py"
  etag   = filemd5("${path.root}/../src/raw_to_silver.py")
}

resource "aws_s3_object" "silver_to_gold_script" {
  bucket = aws_s3_bucket.this.id
  key    = "scripts/silver_to_gold.py"
  source = "${path.root}/../src/silver_to_gold.py"
  etag   = filemd5("${path.root}/../src/silver_to_gold.py")
}

resource "aws_s3_object" "gold_to_redshift_script" {
  bucket = aws_s3_bucket.this.id
  key    = "scripts/gold_to_redshift.py"
  source = "${path.root}/../src/gold_to_redshift.py"
  etag   = filemd5("${path.root}/../src/gold_to_redshift.py")
}


# -----------------------------
# Enable EventBridge notifications

# -----------------------------
resource "aws_s3_bucket_notification" "eventbridge" {
  bucket = aws_s3_bucket.this.id

  eventbridge = true
}
