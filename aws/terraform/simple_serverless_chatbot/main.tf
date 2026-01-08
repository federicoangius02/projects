provider "aws" {
  region = var.region
  
}

# Data source per ottenere l'account ID corrente
data "aws_caller_identity" "current" {}

# Crea un file zip con il codice Lambda
data "archive_file" "chatbot_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/src"
  output_path = "${path.module}/../backend/chatbot_lambda.zip"
}