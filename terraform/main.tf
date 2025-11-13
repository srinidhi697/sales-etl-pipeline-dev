module "s3" {
  source  = "./modules/s3"
  project = var.project
  env     = var.env
}

module "iam" {
  source               = "./modules/iam"
  project              = var.project
  env                  = var.env
  region               = var.region
  lambda_arn           = module.lambda.start_crawler_arn
  step_functions_arn   = module.step_functions.state_machine_arn
  bucket               = module.s3.bucket_name
  data_lake_bucket_arn = module.s3.data_lake_bucket_arn
  sns_topic_arn        = module.sns.sns_topic_arn
}

module "glue" {
  source                       = "./modules/glue"
  project                      = var.project
  env                          = var.env
  bucket                       = module.s3.bucket_name
  glue_role_arn                = module.iam.glue_role_arn
  redshift_cluster_id          = module.redshift_cluster.cluster_identifier
  redshift_db_name             = "sales_dw"
  redshift_username_secret_arn = module.secrets_manager.redshift_username_secret_arn
  redshift_password_secret_arn = module.secrets_manager.redshift_password_secret_arn
  redshift_copy_role_arn       = module.iam.redshift_copy_role_arn
}

module "step_functions" {
  source              = "./modules/step_functions"
  project             = var.project
  env                 = var.env
  sfn_role_arn        = module.iam.step_functions_role_arn
  sfn_role_name       = module.iam.step_functions_role_name
  lambda_arn          = module.lambda.start_crawler_arn # pass lambda output here
  redshift_cluster_id = var.redshift_cluster_id
  redshift_db_name    = var.redshift_db_name
  redshift_user       = var.redshift_user
  redshift_role_arn   = var.redshift_role_arn
  gold_bucket_path    = var.gold_bucket_path
  region              = var.region
  sns_topic_arn       = module.sns.sns_topic_arn
}

module "lambda" {
  source  = "./modules/lambda"
  project = var.project
  env     = var.env
}

module "eventbridge" {
  source          = "./modules/eventbridge"
  project         = var.project
  env             = var.env
  raw_bucket_name = module.s3.bucket_name
  sfn_arn         = module.step_functions.state_machine_arn
}

module "redshift_cluster" {
  source  = "./modules/redshift_cluster"
  project = var.project
  env     = var.env
  region  = var.region


  vpc_id                       = var.vpc_id
  redshift_username_secret_arn = module.secrets_manager.redshift_username_secret_arn
  redshift_password_secret_arn = module.secrets_manager.redshift_password_secret_arn
  redshift_role_secret_arn     = module.secrets_manager.redshift_role_secret_arn
}

module "sns" {
  source               = "./modules/sns"
  project              = var.project
  env                  = var.env
  sns_email_secret_arn = module.secrets_manager.sns_email_secret_arn
}


module "cloudwatch" {
  source         = "./modules/cloudwatch"
  project        = var.project
  env            = var.env
  sns_topic_arn  = module.sns.sns_topic_arn
  log_group_name = "/aws/etl/sales-pipeline"
}

module "secrets_manager" {
  source            = "./modules/secrets_manager"
  project           = var.project
  env               = var.env
  redshift_username = var.redshift_username
  redshift_password = var.redshift_password
  redshift_role_arn = var.redshift_role_arn
  sns_email         = var.sns_email

}

