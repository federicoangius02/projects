provider "aws" {
    region = "eu-south-1"
}

module "web_app" {
  source = "../web_app_1"
}