resource "aws_dynamodb_table" "conversations_table" {
  name         = "${var.project_name}-conversations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "conversationId"

  attribute {
    name = "conversationId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S" # S = String (ISO format: 2025-10-28T14:30:00+00:00)
  }

  global_secondary_index {
    name            = "UserIdIndex"
    hash_key        = "userId"      # Partition key dell'indice
    range_key       = "timestamp"   # Sort key: ordina per data (più recenti prima)
    projection_type = "ALL"         # Proietta tutti gli attributi (non solo chiavi)
  }

  point_in_time_recovery {
    enabled = true  # Backup continuo per il ripristino point-in-time
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name} Conversations"
    Environment = "production"
  }
  
}