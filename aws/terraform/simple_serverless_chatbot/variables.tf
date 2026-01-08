variable "region" {
  description = "AWS Region"
  type = string
  default     = "eu-south-1"
}

variable "project_name" {
  description = "Nome del progetto"
  type = string
  default     = "simple-serverless-chatbot"
  
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
  # Non impostare un default qui per sicurezza
}