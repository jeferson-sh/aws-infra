# Configure o provider AWS
provider "aws" {
  region = var.aws_region  # Defina a região desejada
}

# Crie um repositório ECR
resource "aws_ecr_repository" "ecr_repository" {
  name = "ecr-repository"  # Nome do repositório ECR
}

# Crie um cluster ECS
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"  # Nome do cluster
}

# Defina a IAM Role para as tasks ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Anexe a política ECS à IAM Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

# Defina uma definição de task ECS
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "ecs-task-definition"
  container_definitions    = <<EOF
[
  {
    "name": "ecs-container",
    "image": "${aws_ecr_repository.ecr_repository.repository_url}:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ]
  }
]
EOF
}

# Defina um serviço ECS
resource "aws_ecs_service" "my_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1

  # Configurações para Load Balancer
  network_configuration {
    assign_public_ip = true
    subnets = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "ecs-container"
    container_port   = 80
  }
}

# Crie um Target Group para o Load Balancer
resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 80
  protocol = "HTTP"

  health_check {
    path     = "/"
    interval = 30
    timeout  = 5
  }

  vpc_id = var.vpc_id  # Defina o ID da VPC onde o cluster ECS será criado
}

# Crie um Load Balancer
resource "aws_lb" "ecs_load_balancer" {
  name               = "ecs-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_security_group.id]
  subnets            = var.subnet_ids  # Defina os IDs das sub-redes onde o Load Balancer será criado

  tags = {
    Name = "ecs-load-balancer"
  }
}

# Crie um Security Group para o Load Balancer
resource "aws_security_group" "ecs_security_group" {
  name        = "ecs-security-group"
  description = "Allow HTTP inbound traffic"

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
