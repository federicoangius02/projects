output "alb_dns_name" {
  description = "DNS name dell'ALB"
  value       = aws_lb.app_lb.dns_name
}

output "s3_bucket_name" {
  description = "Nome del bucket S3"
  value       = aws_s3_bucket.my_bucket.bucket
}

output "dynamodb_table_name" {
  description = "Nome della tabella DynamoDB"
  value       = aws_dynamodb_table.dyanmodb_table.name
}