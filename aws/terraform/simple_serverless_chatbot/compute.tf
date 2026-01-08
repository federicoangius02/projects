# Ruolo IAM per Lambda
resource "aws_iam_role" "chatbot_lambda_role" {
  name = "${var.project_name}-chatbot-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name} Lambda Role"
  }
}

# Policy per i log di CloudWatch
resource "aws_iam_role_policy" "chatbot_lambda_logging" {
  name = "${var.project_name}-chatbot-lambda-logging"
  role = aws_iam_role.chatbot_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-chatbot-*"
      }
    ]
  })
}

# Policy per DynamoDB
resource "aws_iam_role_policy" "chatbot_lambda_dynamodb" {
  name = "${var.project_name}-chatbot-lambda-dynamodb"
  role = aws_iam_role.chatbot_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-conversations"
      }
    ]
  })
}

# CloudWatch Log Group per Lambda
resource "aws_cloudwatch_log_group" "chatbot_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}"
  retention_in_days = 7  # Mantieni log per 7 giorni (free tier friendly)

  tags = {
    Name = "${var.project_name} Lambda Logs"
  }
}

# Funzione Lambda principale
resource "aws_lambda_function" "chatbot" {
  filename         = data.archive_file.chatbot_lambda_zip.output_path
  function_name    = var.project_name
  role            = aws_iam_role.chatbot_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.chatbot_lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30  # 30 secondi (sufficiente per chiamate OpenAI)
  memory_size     = 256 # 256MB (free tier friendly)

  # Variabili d'ambiente
  environment {
    variables = {
      DYNAMODB_TABLE    = "${var.project_name}-conversations"
      OPENAI_API_KEY    = var.openai_api_key
      LOG_LEVEL        = "INFO"
    }
  }

  # Dipende dai log group per evitare race condition
  depends_on = [
    aws_iam_role_policy.chatbot_lambda_logging,
    aws_cloudwatch_log_group.chatbot_lambda_logs
  ]

  tags = {
    Name        = "${var.project_name} Lambda Function"
  }
}