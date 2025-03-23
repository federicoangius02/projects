variable "region" {
  description = "AWS Region"
  default     = "eu-south-1"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
  
}

variable "availability_zones" {
  default = ["eu-south-1a", "eu-south-1b"]
}

/*variable "ssm_parameter_name" {
  description = "Nome del parametro SSM"
  type        = string
  default     = "my-parameter-name"  # Sostituisci con il nome del parametro SSM
}*/