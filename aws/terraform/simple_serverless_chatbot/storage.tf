# Random string per nome bucket unico
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket per l'hosting del frontend
resource "aws_s3_bucket" "chatbot_frontend_bucket" {
  bucket = "${var.project_name}-frontend-bucket-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name} Frontend Bucket"
  }
  
}

# Versioning per il bucket del frontend
resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.chatbot_frontend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  
}

# Configurazione static website hosting
resource "aws_s3_bucket_website_configuration" "chatbot_frontend_website" {
  bucket = aws_s3_bucket.chatbot_frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
  
}

# Block pubblico per il bucket del frontend
resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket                  = aws_s3_bucket.chatbot_frontend_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false 
  
}

# Policy per l'accesso pubblico al bucket del frontend
resource "aws_s3_bucket_policy" "chatbot_frontend_policy" {
  bucket = aws_s3_bucket.chatbot_frontend_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.frontend_block]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.chatbot_frontend_bucket.arn}/*"
      }
    ]
  })
  
}

# Configurazione della crittografia lato server per il bucket del frontend
resource "aws_s3_bucket_server_side_encryption_configuration" "chatbot_frontend_encryption" {
  bucket = aws_s3_bucket.chatbot_frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
}