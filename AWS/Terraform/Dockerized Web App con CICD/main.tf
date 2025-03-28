provider "aws" {
    region = var.region # Replace with your desired AWS region
}

resource "aws_iam_role" "ecr_role" {
  name = "ecr-read-only-role"  # Nome specifico per il tuo progetto
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"  # Allega policy predefinita
}

resource "aws_iam_instance_profile" "ecr_read_only_profile" {
  name = "ecr-read-only-instance-profile"
  role = aws_iam_role.ecr_role.name  # Ruolo predefinito
}