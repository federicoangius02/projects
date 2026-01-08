# terraform/api.tf

# ===============================================
# API Gateway REST API
# ===============================================

resource "aws_api_gateway_rest_api" "chatbot_api" {
  name        = "${var.project_name}-api"
  description = "API Gateway for serverless chatbot"

  endpoint_configuration {
    types = ["REGIONAL"]  # REGIONAL per EU, EDGE per global distribution
  }

  tags = {
    Name      = "${var.project_name} API"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ===============================================
# API Gateway Resource: /chat
# ===============================================

resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  parent_id   = aws_api_gateway_rest_api.chatbot_api.root_resource_id
  path_part   = "chat"
}

# ===============================================
# POST Method: POST /chat
# ===============================================

resource "aws_api_gateway_method" "chat_post" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "POST"
  authorization = "NONE"  # Nessuna autenticazione per semplicità
}

# ===============================================
# OPTIONS Method: OPTIONS /chat (per CORS)
# ===============================================

resource "aws_api_gateway_method" "chat_options" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# ===============================================
# Lambda Integration: POST /chat → Lambda
# ===============================================

resource "aws_api_gateway_integration" "chat_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.chatbot_api.id
  resource_id             = aws_api_gateway_resource.chat.id
  http_method             = aws_api_gateway_method.chat_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"  # Lambda proxy integration
  uri                     = aws_lambda_function.chatbot.invoke_arn
}

# ===============================================
# OPTIONS Mock Integration (per CORS preflight)
# ===============================================

resource "aws_api_gateway_integration" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# ===============================================
# OPTIONS Method Response (CORS)
# ===============================================

resource "aws_api_gateway_method_response" "chat_options_200" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# ===============================================
# OPTIONS Integration Response (CORS)
# ===============================================

resource "aws_api_gateway_integration_response" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  status_code = aws_api_gateway_method_response.chat_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.chat_options]
}

# ===============================================
# Lambda Permission: Permetti API Gateway di invocare Lambda
# ===============================================

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot_api.execution_arn}/*/*"
}

# ===============================================
# API Deployment: Deploy l'API
# ===============================================

resource "aws_api_gateway_deployment" "chatbot" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id

  depends_on = [
    aws_api_gateway_integration.chat_lambda,
    aws_api_gateway_integration.chat_options
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ===============================================
# API Stage: prod
# ===============================================

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.chatbot.id
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  stage_name    = "prod"

  # Throttling per protezione
  throttle_settings {
    burst_limit = 100   # Max 100 richieste burst
    rate_limit  = 50    # Max 50 richieste/secondo
  }

  # Logging per debugging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name      = "${var.project_name} API Stage"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ===============================================
# CloudWatch Log Group per API Gateway
# ===============================================

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name      = "${var.project_name} API Gateway Logs"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ===============================================
# Outputs
# ===============================================

output "api_gateway_url" {
  description = "URL base dell'API Gateway"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/chat"
}

output "api_gateway_id" {
  description = "ID dell'API Gateway"
  value       = aws_api_gateway_rest_api.chatbot_api.id
}

output "api_gateway_stage" {
  description = "Nome dello stage"
  value       = aws_api_gateway_stage.prod.stage_name
}

