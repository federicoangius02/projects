terraform {
  cloud {

    organization = "learn_terraform_aws_"

    workspaces {
      name = "learn-terraform-aws"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_budgets_budget" "first_budget" {
  name         = var.budget_name
  budget_type  = "COST"
  limit_amount = "0.50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}