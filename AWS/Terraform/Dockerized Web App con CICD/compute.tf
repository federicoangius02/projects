resource "aws_instance" "web-app-instance" {
  ami = var.ami
  instance_type = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_app_sg.id]

  key_name = var.key_name

  # Script di User Data per configurare l'istanza al primo avvio
  user_data = <<-EOF
#!/bin/bash
# Script di bootstrap per l'istanza EC2

# --- Configurazione base ---
yum update -y
amazon-linux-extras install docker -y
yum install -y git

# --- Installazione AWS CLI v2 ---
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# --- Configurazione Docker ---
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# --- Login a ECR ---
aws ecr get-login-password --region ${var.region} | \
  docker login --username AWS --password-stdin ${local.ecr_registry}

# --- Pull e run dell'immagine ---
docker pull ${local.ecr_registry}/${var.ecr_repository}:latest

# --- Cleanup di eventuali container precedenti ---
docker stop web-app || true
docker rm web-app || true

# --- Run del nuovo container ---
docker run -d \
  --name web-app \
  --restart unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=production \
  ${local.ecr_registry}/${var.ecr_repository}:latest
EOF

  tags = {
    Name = "web-app-instance"
  }
}