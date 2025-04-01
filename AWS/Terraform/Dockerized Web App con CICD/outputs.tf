output "web_app_instance_public_ip" {
  value       = aws_instance.web-app-instance.public_ip
  description = "Indirizzo IP pubblico dell'istanza web-app"
}

output "pipeline_url" {
  value = "https://${var.region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.web_app_pipeline.name}/view"
}