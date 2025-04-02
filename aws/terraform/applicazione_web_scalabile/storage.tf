# Bucket per il backend (file utente)
resource "aws_s3_bucket" "backend_bucket" {
  bucket_prefix = "federico-angius-backend-"
  
  tags = {
    Name        = "backend-storage"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_encryption" {
  bucket = aws_s3_bucket.backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backend_block" {
  bucket                  = aws_s3_bucket.backend_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backend_versioning" {
  bucket = aws_s3_bucket.backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket per il frontend (applicazione web)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket_prefix = "federico-angius-frontend-"
  
  tags = {
    Name        = "frontend-app"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend_hosting" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_access" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = false  # Necessario per hosting static website
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Tabella DynamoDB (metadati)
resource "aws_dynamodb_table" "metadata_table" {
  name         = "my-app-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "federico-angius-metadata"
    Environment = "Production"
  }
}
