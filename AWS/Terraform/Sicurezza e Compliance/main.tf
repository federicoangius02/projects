# Configura il provider AWS per la regione di Milano (eu-south-1)
provider "aws" {
  region = "eu-south-1"
}

# 1. Frontend: Configurazione di S3 e CloudFront
# Crea un bucket S3 per ospitare i file statici del frontend (HTML, CSS, JS)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "my-web-app-frontend"  # Nome del bucket
}

# Configura l'accesso pubblico al bucket S3 (disabilitato per sicurezza)
resource "aws_s3_bucket_public_access_block" "frontend_bucket_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configura il bucket S3 come sito web statico
resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Configura CloudFront per distribuire i contenuti del bucket S3
resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = "S3-Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Crea un'origine di accesso CloudFront per il bucket S3
resource "aws_cloudfront_origin_access_identity" "frontend_oai" {
  comment = "OAI for frontend bucket"
}

# 2. Backend: Configurazione di Lambda e API Gateway
# Crea una funzione Lambda per gestire le richieste API
resource "aws_lambda_function" "api_lambda" {
  filename      = "lambda_function_payload.zip"  # File ZIP contenente il codice Lambda
  function_name = "my_api_lambda"  # Nome della funzione Lambda
  role          = aws_iam_role.lambda_exec_role.arn  # Ruolo IAM associato alla Lambda
  handler       = "index.handler"  # Punto di ingresso della funzione
  runtime       = "nodejs14.x"  # Runtime Node.js 14.x

  environment {
    variables = {
      DB_HOST     = aws_db_instance.web_db.address  # Endpoint del database
      DB_USER     = "admin"  # Utente del database
      DB_PASSWORD = "password"  # Password del database
      DB_NAME     = "mydb"  # Nome del database
    }
  }
}

# Crea un ruolo IAM per la funzione Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Allega la politica di base di esecuzione Lambda al ruolo
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Crea un'API Gateway per esporre la Lambda come API RESTful
resource "aws_api_gateway_rest_api" "api" {
  name = "my_api"
}

# Crea una risorsa API Gateway per il percorso "/myresource"
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "myresource"
}

# Configura il metodo GET per la risorsa API
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Configura l'integrazione tra API Gateway e Lambda
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_lambda.invoke_arn
}

# Crea un deployment dell'API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

# 3. Database: Configurazione di Amazon RDS (MySQL)
# Crea un'istanza RDS MySQL
resource "aws_db_instance" "web_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

# Crea un gruppo di sicurezza per il database
resource "aws_security_group" "db_sg" {
  name_prefix = "db-sg-"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Autenticazione: Configurazione di Amazon Cognito
# Crea un pool di utenti per l'autenticazione
resource "aws_cognito_user_pool" "user_pool" {
  name = "my_user_pool"
}

# Crea un client per il pool di utenti
resource "aws_cognito_user_pool_client" "client" {
  name         = "my_client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# 5. Sicurezza: Configurazione di AWS WAFv2
# Crea una Web ACL per proteggere l'applicazione
resource "aws_wafv2_web_acl" "web_acl" {
  name        = "my_web_acl"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "my-web-acl-metrics"
    sampled_requests_enabled   = true
  }
}

# 6. Monitoraggio: Configurazione di CloudWatch
# Crea un allarme CloudWatch per monitorare gli errori della Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda_errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]
}

# Crea un topic SNS per le notifiche degli allarmi
resource "aws_sns_topic" "alarm_topic" {
  name = "alarm-topic"
}

# Output
output "frontend_url" {
  value = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "db_endpoint" {
  value = aws_db_instance.web_db.endpoint
}