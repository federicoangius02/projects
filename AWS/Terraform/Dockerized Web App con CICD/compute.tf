resource "aws_instance" "web-app-instance" {
    ami                  = var.ami
    instance_type        = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.ecr_read_only_profile.name
    subnet_id            = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.web_app_sg.id]
    key_name             = var.key_name

    user_data = <<-EOF
              #!/bin/bash
              # Installazioni di base
              yum update -y
              amazon-linux-extras install docker -y
              
              # AWS CLI v2 (obbligatorio per ECR login)
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              
              # Configurazione Docker
              systemctl start docker
              usermod -aG docker ec2-user
              
              # Autenticazione ECR
              aws ecr get-login-password --region eu-south-1 | \
                docker login --username AWS --password-stdin 864899833939.dkr.ecr.eu-south-1.amazonaws.com
              
              # Deploy container
              docker pull 864899833939.dkr.ecr.eu-south-1.amazonaws.com/my-web-app:latest
              docker run -d \
                -p 3000:3000 \
                -e "NODE_ENV=production" \
                864899833939.dkr.ecr.eu-south-1.amazonaws.com/my-web-app:latest
              EOF

    tags = {
        Name = "web-app-instance"
    }
}