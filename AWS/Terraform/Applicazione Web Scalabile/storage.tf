# Configurazione del bucket S3 con bucket_prefix e blocchi di sicurezza
resource "aws_s3_bucket" "federico_angius_bucket" {
    bucket_prefix = "federico-angius-"

    tags = {
        Name        = "my-bucket"
        Environment = "Production"
    }
}

# Blocco pubblico
resource "aws_s3_bucket_public_access_block" "public_access_bucket_block" {
    bucket                  = aws_s3_bucket.federico_angius_bucket.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.federico_angius_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configurazione della tabella DynamoDB con crittografia lato server
resource "aws_dynamodb_table" "federico_angius_table" {
    name         = "federico-angius-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "id"

    attribute {
        name = "id"
        type = "S"
    }

    # Crittografia lato server
    server_side_encryption {
        enabled = true
    }

    tags = {
        Name        = "federico-angius-table"
        Environment = "Production"
    }
}
