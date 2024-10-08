# Configure o provider AWS
provider "aws" {
  region = var.aws_region  # Defina a região desejada
}

# Configuração do backend S3 para armazenar o estado do Terraform
terraform {
  backend "s3" {
    bucket = "bucket-s3-terraform"  # Nome do bucket S3 onde o estado será armazenado
    key    = "terraform.tfstate"  # Nome do arquivo de estado no bucket
    region = "us-east-2"  # Região onde o bucket S3 está localizado
  }
}

# Crie um repositório ECR
resource "aws_ecr_repository" "ecr_repository" {
  name         = var.ecr_repository_name  # Nome do repositório ECR
  force_delete = true
}

resource "null_resource" "build_and_push_docker_image" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.ecr_repository.repository_url}
      docker build -t custom_nginx_image:latest ./docker
      docker tag custom_nginx_image:latest ${aws_ecr_repository.ecr_repository.repository_url}:latest
      docker push ${aws_ecr_repository.ecr_repository.repository_url}:latest
    EOT
  }
  depends_on = [aws_ecr_repository.ecr_repository]
}

# Crie um cluster ECS
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name  # Nome do cluster
}

# Defina a IAM Role para as tasks ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
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
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/service-role/ROSAKMSProviderPolicy"
  ]
}

resource "aws_iam_role" "task_role" {
  name               = var.task_role_name
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
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

# Defina uma definição de task ECS mínima
resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.ecs_task_definition_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  container_definitions    = jsonencode([
    {
      name  = var.ecs_container_name,
      image = "${aws_ecr_repository.ecr_repository.repository_url}:latest",
      cpu   = 256,
      memory = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-create-group" = "true",
          "awslogs-group"         = "/ecs/log-group-${var.ecs_container_name}",
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs-${var.ecs_container_name}"
        }
      }
    }
  ])
}

# Defina um serviço ECS com tarefas desejadas
resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1 # Defina o número de tarefas desejadas
  launch_type     = "FARGATE"  # Indica que o serviço será executado no Fargate

  # Configurações para Load Balancer
  network_configuration {
    security_groups = [aws_security_group.ecs_security_group.id]
    subnets         = var.subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = var.ecs_container_name
    container_port   = 8080
  }

  # Configuração de deployment
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [aws_alb_listener.alb_listener]
}

# Crie um Target Group para o Load Balancer
resource "aws_lb_target_group" "ecs_target_group" {
  name     = var.ecs_target_group_name
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
  name               = var.ecs_load_balancer_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_security_group.id]
  subnets            = var.subnet_ids  # Defina os IDs das sub-redes onde o Load Balancer será criado

  tags = {
    Name = var.ecs_load_balancer_name
  }
}

# Crie um Security Group para o Load Balancer
resource "aws_security_group" "ecs_security_group" {
  name        = var.ecs_security_group_name
  description = "Allow HTTP inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.ecs_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    type             = "forward"
  }
}

# Defina o alvo de escalonamento para o serviço ECS
resource "aws_appautoscaling_target" "ecs_service_target" {
  max_capacity       = 3  # Capacidade máxima
  min_capacity       = 1  # Capacidade mínima
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Defina a política de escalonamento para aumentar a capacidade
resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "scale-up"
  resource_id        = aws_appautoscaling_target.ecs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_target.service_namespace
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment = 1
      metric_interval_lower_bound = 0
    }
  }
}

# Defina a política de escalonamento para diminuir a capacidade
resource "aws_appautoscaling_policy" "scale_down_policy" {
  name               = "scale-down"
  resource_id        = aws_appautoscaling_target.ecs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_target.service_namespace
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment = -1
      metric_interval_upper_bound = 0
    }
  }
}