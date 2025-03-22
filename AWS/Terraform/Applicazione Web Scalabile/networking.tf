resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "main-vpc"
    }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "main-igw"
    }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public_subnet)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private_subnet)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Environment = "s3-endpoint"
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-security-group"
  }
}

resource "aws_security_group_rule" "alb_sg_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_sg_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_sg_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnet[*].id

  enable_deletion_protection = false

  tags = {
    Name = "app-lb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name = "app-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  health_check {
    path = "/health"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "s3-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb_vpc_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "dynamodb-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_messages_vpc_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ec2messages"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "ec2-messages-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_vpc_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "ecr-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api_vpc_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "ecr-api-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm_vpc_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ssm"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "ssm-vpc-endpoint"
  }
}