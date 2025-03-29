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
              # Installazioni base
              yum update -y
              amazon-linux-extras install docker -y

              # Installazione AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Configurazione Docker
              systemctl start docker
              usermod -aG docker ec2-user

              # Login a ECR
              aws ecr get-login-password --region eu-south-1 | \
                docker login --username AWS --password-stdin 864899833939.dkr.ecr.eu-south-1.amazonaws.com

              # Avvio container
              docker run -d \
                -p 3000:3000 \
                --restart unless-stopped \
                864899833939.dkr.ecr.eu-south-1.amazonaws.com/my-web-app:latest
              EOF

  tags = {
    Name = "web-app-instance"
  }
}