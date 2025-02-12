# Provider
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

# Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "PrivateSubnet2"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "InternetGateway"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name   = "ec2_security_group"
  description = "Allow inbound SSH and outbound MySQL"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group RDS
resource "aws_security_group" "rds_sg" {
    vpc_id = aws_vpc.main_vpc.id
  name        = "rds_security_group"
  description = "Allow MySQL traffic from EC2"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
    # cidr_blocks = ["10.0.0.0/24"]   Consenti solo la subnet pubblica EC2
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami             = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.ec2_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  user_data = <<-EOF
      #!/bin/bash
      sudo yum update -y
      sudo yum install -y mysql
    EOF

  tags = {
    Name = "WebServer"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "private_subnet_group" {
  name        = "my-db-subnet-group"
  description = "Subnet group for RDS instance"

  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "DBSubnetGroup"
  }
}

# SSM Parameters
# Username (non crittografato, non sensibile)
resource "aws_ssm_parameter" "db_username" {
  name  = "Username"
  type  = "String"
  value = "admin"
}

# Password (crittografato, sensibile)
resource "aws_ssm_parameter" "db_password" {
  name  = "Password"
  type  = "SecureString"
  value = "password123"
}

# Username Data Source
data "aws_ssm_parameter" "db_username" {
  name            = aws_ssm_parameter.db_username.name  # Dipendenza esplicita
  with_decryption = false             # Non è necessario decrittografare, dato che è di tipo String
}

# Password Data Source
data "aws_ssm_parameter" "db_password" {
  name            = aws_ssm_parameter.db_password.name  # Dipendenza esplicita
  with_decryption = true              # Necessario per decrittografare, dato che è di tipo SecureString
}

# RDS Instance
resource "aws_db_instance" "db" {
  allocated_storage      = 10
  identifier             = "my-database"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = data.aws_ssm_parameter.db_username.value   # Usa il valore dal data source
  password               = data.aws_ssm_parameter.db_password.value   # Usa il valore decrittografato dal data source
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_subnet_group.name
}

# S3 Bucket
resource "aws_s3_bucket" "web_storage" {
  bucket = "angius-web-storage-bucket"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "EC2_S3_Access_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 Access - SSM Parameters Access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  description = "Policy for EC2 to access S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",  # Permesso per elencare il contenuto del bucket
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::angius-web-storage-bucket",
          "arn:aws:s3:::angius-web-storage-bucket/*"
        ]
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:ssm:us-east-1:864899833939:parameter/Username",
          "arn:aws:ssm:us-east-1:864899833939:parameter/Password"
          ]
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}