variable "region" {
  description = "Regione dove creare le risorse"
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

variable "key_name" {
  description = "Il nome della Key Pair SSH da utilizzare per accedere all'istanza"
  type        = string
  default     = "MyKeyPair"
}

variable "ami" {
  description = "L'AMI da utilizzare per l'istanza"
  type        = string
  default     = "ami-00e75c3cfa05fd424"
}

variable "ecr_repository" {
  default = "my-web-app"
}

variable "ecr_registry" {
  default = "864899833939.dkr.ecr.eu-south-1.amazonaws.com"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
}

variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}