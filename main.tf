# Configure o provider AWS
provider "aws" {
  region = var.aws_region  # Defina a região desejada
}

# Configuração do backend S3 para armazenar o estado do Terraform
terraform {
  backend "s3" {
    bucket         = "bucket-s3-terraform"  # Nome do bucket S3 onde o estado será armazenado
    key            = "terraform.tfstate"  # Nome do arquivo de estado no bucket
    region         = "us-east-2"  # Região onde o bucket S3 está localizado
  }
}

# Crie um repositório ECR
resource "aws_ecr_repository" "ecr_repository" {
  name = "ecr-repository"  # Nome do repositório ECR
  force_delete = true
}

# Crie um cluster ECS
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"  # Nome do cluster
}

# Defina a IAM Role para as tasks ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = jsonencode(
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
  )
  managed_policy_arns = [ "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" ]
}


resource "aws_iam_role" "task_role" {
  name               = "task-role"
  assume_role_policy = jsonencode(
    {
      Version   = "2012-10-17",
      Statement = [
        {
          Effect    = "Allow",
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          },
          Action    = "sts:AssumeRole"
        }
      ]
    }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  ]
}

resource "aws_cloudwatch_log_group" "aws_log_group" {
  name              = "/aws/ecs/log-group"  # Nome do grupo de logs
  retention_in_days = 7  # Retenção em dias, ajuste conforme necessário
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "log-stream"
  log_group_name = aws_cloudwatch_log_group.aws_log_group.name
}


# Defina uma definição de task ECS
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "ecs-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.task_role.arn
  container_definitions = jsonencode([
    {
      name : "ecs-container",
      image : "${aws_ecr_repository.ecr_repository.repository_url}:latest",
      cpu : 256,
      memory : 512,
      essential : true,
      portMappings : [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.aws_log_group.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = aws_cloudwatch_log_stream.log_stream.name
        }
      }
    }
  ])
}

# Defina um serviço ECS
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"  # Indica que o serviço será executado no Fargate

  # Configurações para Load Balancer
  network_configuration {
    security_groups = [aws_security_group.ecs_security_group.id]
    subnets = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "ecs-container"
    container_port   = 8080
  }

  # Configuração de logs
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [ aws_alb_listener.alb_listener ]
}

# Crie um Target Group para o Load Balancer
resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  

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

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.ecs_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    type             = "forward"
  }
}
