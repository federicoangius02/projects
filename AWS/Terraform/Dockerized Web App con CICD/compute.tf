resource "aws_instance" "web-app-instance" {
    ami                  = var.ami
    instance_type        = "t3.micro"
    subnet_id            = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.web_app_sg.id] # Corretto
    key_name             = var.key_name

    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              systemctl enable docker
              docker run -d -p 80:80 your-docker-image
              EOF

    tags = {
        Name = "web-app-instance"
    }
}