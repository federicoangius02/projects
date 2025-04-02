output "alb_dns_name" {
  description = "DNS name dell'ALB"
  value       = aws_lb.app_lb.dns_name
}

output "backend_bucket_name" {
  description = "Nome del bucket S3 backend"
  value       = aws_s3_bucket.backend_bucket.bucket  # <- Modificato
}

output "frontend_bucket_name" {
  description = "Nome del bucket S3 frontend"
  value       = aws_s3_bucket.frontend_bucket.bucket  # <- Nuovo output
}

output "dynamodb_table_name" {
  description = "Nome della tabella DynamoDB"
  value       = aws_dynamodb_table.metadata_table.name  # <- Modificato
}

output "frontend_url" {
  description = "URL del frontend"
  value       = "http://${aws_s3_bucket.frontend_bucket.bucket}.s3-website.${var.region}.amazonaws.com"
}