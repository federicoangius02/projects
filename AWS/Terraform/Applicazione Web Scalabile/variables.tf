variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
  
}

variable "availability_zones" {
  default = ["eu-south-1a", "eu-south-1b"]
}

varia