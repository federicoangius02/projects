provider "aws" {
    region = "us-east-1"
}

# Crea un bucket S3
resource "aws_s3_bucket" "my_bucket" {
  bucket = "federico-angius-serverless-bucket-test-02"
force_destroy = true # Elimina tutto il contenuto prima di distruggere il bucket
    # acl = "private" # Deprecato, usare invece block_public_acls = true
}

# Abilita il versioning del bucket
resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = "Enabled" # Abilita il versioning
  }
}

# Configura la crittografia del bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Crittografia lato server con AES-256
    }
  }
}

# Blocca l'accesso pubblico
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "my_table" {
  name         = "my-dynamodb-table"       # Nome della tabella
  billing_mode = "PAY_PER_REQUEST"         # Modalità di pagamento (on-demand)

  # Chiave primaria (partition key)
  hash_key = "id"

  # Definizione degli attributi della tabella
  attribute {
    name = "id"
    type = "S"  # Tipo: S = String, N = Number, B = Binary
  }

  # Abilita la crittografia lato server (di default è AWS managed)
  server_side_encryption {
    enabled = true
  }

  tags = {
    Environment = "Development"
    Project     = "Serverless App"
  }
}

resource "aws_lambda_function" "s3_to_dynamodb" {
  filename         = "s3_to_dynamodb.zip"  # Nome del file ZIP
  function_name    = "s3_to_dynamodb"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "s3_to_dynamodb.lambda_handler"  # Nome della funzione handler
  runtime          = "python3.9"
  timeout          = 10

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.my_table.name
    }
  }
}

resource "aws_lambda_function" "crud_dynamodb" {
  filename         = "crud_dynamodb.zip"  # Nome del file ZIP
  function_name    = "crud_dynamodb"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "crud_dynamodb.lambda_handler"  # Nome della funzione handler
  runtime          = "python3.9"
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.my_table.name
    }
  }
}

# Ruolo IAM per Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

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

# Policy IAM unificata
resource "aws_iam_policy" "lambda_access_policy" {
  name        = "lambda_access_policy"
  description = "Permette alla Lambda di accedere a DynamoDB e CloudWatch Logs"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Permessi per DynamoDB
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.my_table.arn
      },
      {
        # Permessi per CloudWatch Logs
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_combined_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_access_policy.arn
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_dynamodb.arn
    events              = ["s3:ObjectCreated:*"]  # Trigger su creazione di oggetti
  }

  depends_on = [aws_lambda_permission.allow_s3]  # Assicurati che i permessi siano configurati
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_dynamodb.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}

resource "aws_api_gateway_rest_api" "crud_api" {
  name        = "crud_dynamodb_api"
  description = "API Gateway per la gestione di DynamoDB"
}

resource "aws_api_gateway_resource" "crud_resource" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  parent_id   = aws_api_gateway_rest_api.crud_api.root_resource_id
  path_part   = "crud"  # Path dell'API, es: /crud
}

resource "aws_api_gateway_method" "crud_method" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.crud_resource.id
  http_method   = "ANY"
    authorization = "AWS_IAM"  # Abilita l'autorizzazione IAM
  #authorization = "NONE"  # Nessuna autorizzazione per ora (puoi aggiungere autenticazione in futuro)
}

resource "aws_api_gateway_integration" "crud_integration" {
  rest_api_id             = aws_api_gateway_rest_api.crud_api.id
  resource_id             = aws_api_gateway_resource.crud_resource.id
  http_method             = aws_api_gateway_method.crud_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crud_dynamodb.invoke_arn
}

# Deployment per API Gateway
resource "aws_api_gateway_deployment" "crud_deployment" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id

  depends_on = [
    aws_api_gateway_integration.crud_integration
  ]
}

# Stage per API Gateway
resource "aws_api_gateway_stage" "prod_stage" {
  stage_name    = "prod"  # Nome dello stage
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  deployment_id = aws_api_gateway_deployment.crud_deployment.id

  description = "Stage di produzione per CRUD API"
}

# Output per l'URL dell'API Gateway
output "api_gateway_url" {
  value       = "https://${aws_api_gateway_rest_api.crud_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.prod_stage.stage_name}"
  description = "URL dell'API Gateway per il CRUD"
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crud_dynamodb.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.crud_api.execution_arn}/*/*"
}

# Crea la policy IAM per l'API Gateway
resource "aws_iam_policy" "api_gateway_invoke_policy" {
  name        = "APIGatewayInvokePolicy"
  description = "Permette di invocare l'API Gateway protetta da IAM Authorization"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "execute-api:Invoke",
        Resource = "arn:aws:execute-api:us-east-1:864899833939:${aws_api_gateway_rest_api.crud_api.id}/prod/ANY/crud"
      }
      ,{
        # Permessi per accedere al bucket S3
        Effect = "Allow",
        Action = [
          "s3:PutObject",    # Per caricare file nel bucket
          # "s3:GetObject",    # (Facoltativo) Per scaricare file dal bucket
          # "s3:ListBucket"    # (Facoltativo) Per elencare i file nel bucket
        ],
        Resource = [
          # "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}",       # Permesso sul bucket stesso
          "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*"     # Permesso su tutti gli oggetti nel bucket
        ]
      }
    ]
  })
}

# Allegare la policy all'utente esistente
resource "aws_iam_user_policy_attachment" "attach_policy_to_user" {
  user       = "admin"  # Sostituisci con il nome del tuo utente IAM
  policy_arn = aws_iam_policy.api_gateway_invoke_policy.arn
}