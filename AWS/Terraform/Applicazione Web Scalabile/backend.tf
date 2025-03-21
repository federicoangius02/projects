resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "ecs-cluster"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "my-app"
  network_mode             = "awsvpc"  # Usa AWSVPC per Fargate
  requires_compatibilities = ["FARGATE"]  # Modalità serverless
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = "512"  # 0.5 vCPU
  memory                   = "1024" # 1GB RAM

  container_definitions = jsonencode([
    {
      name      = "my-app"
      image     = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/my-app:latest"  # Sostituisci con il tuo ECR repo
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/my-app"
          "awslogs-region"        = "eu-west-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 2  # Numero di container attivi

  network_configuration {
    subnets          = aws_subnet.private_subnet[*].id  # Usa le subnet private
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false  # Non serve un IP pubblico
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "my-app"
    container_port   = 80
  }

  tags = {
    Name = "ecs-service"
  }
}

resource "aws_iam_role" "ecs_role" {
  name = "ecsRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_iam_policy" "ecs_policy" {
  name        = "ecsPolicy"
  description = "Policy for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        
      ]
      Resource = "*"
    }]
  })
}