# Output utili
output "config_bucket_name" {
  value = aws_s3_bucket.config_bucket.bucket
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail_bucket.bucket
}

output "parameter_store_api_key_arn" {
  value = aws_ssm_parameter.api_key.arn
}

output "config_rules" {
  value = [
    aws_config_config_rule.s3_bucket_public_read_prohibited.name,
    aws_config_config_rule.ec2_instance_no_public_ip.name
  ]
}