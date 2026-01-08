# terraform/outputs.tf

# ===============================================
# S3 Outputs
# ===============================================

output "frontend_bucket_name" {
  description = "Nome del bucket S3 per il frontend"
  value       = aws_s3_bucket.chatbot_frontend_bucket.id
}

output "frontend_website_endpoint" {
  description = "Endpoint del sito web statico"
  value       = aws_s3_bucket_website_configuration.chatbot_frontend_website.website_endpoint
}

# ===============================================
# Lambda Outputs
# ===============================================

output "lambda_function_name" {
  description = "Nome della funzione Lambda"
  value       = aws_lambda_function.chatbot.function_name
}

output "lambda_function_arn" {
  description = "ARN della funzione Lambda"
  value       = aws_lambda_function.chatbot.arn
}

# ===============================================
# DynamoDB Outputs
# ===============================================

output "dynamodb_table_name" {
  description = "Nome della tabella DynamoDB"
  value       = aws_dynamodb_table.conversations.name
}

output "dynamodb_table_arn" {
  description = "ARN della tabella DynamoDB"
  value       = aws_dynamodb_table.conversations.arn
}

# ===============================================
# API Gateway Outputs (i più importanti!)
# ===============================================

output "api_gateway_url" {
  description = "URL completo per chiamare l'API"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/chat"
}

output "api_gateway_base_url" {
  description = "URL base dell'API Gateway"
  value       = aws_api_gateway_stage.prod.invoke_url
}

# ===============================================
# Riepilogo Completo
# ===============================================

output "deployment_summary" {
  description = "Riepilogo del deployment"
  value = {
    project_name    = var.project_name
    region          = var.region
    frontend_url    = "http://${aws_s3_bucket_website_configuration.chatbot_frontend_website.website_endpoint}"
    api_endpoint    = "${aws_api_gateway_stage.prod.invoke_url}/chat"
    lambda_function = aws_lambda_function.chatbot.function_name
    dynamodb_table  = aws_dynamodb_table.conversations.name
  }
}