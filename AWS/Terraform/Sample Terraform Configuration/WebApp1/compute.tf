resource "aws_instance" "instance_1" {
  ami             = "ami-0b385250c54450908"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
                #!/bin/bash
                echo "Hello, World 1" > index.html
                python3 -m http.server 8080 &
                EOF

  tags = {
    Name = "instance-1"
  }
}

resource "aws_instance" "instance_2" {
  ami             = "ami-0b385250c54450908"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
                #!/bin/bash
                echo "Hello, World 2" > index.html
                python3 -m http.server 8080 &
                EOF
  tags = {
    Name = "instance-2"
  }
}