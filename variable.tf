variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for Terraform state"
  type        = string
  default     = "bucket-s3-terraform"
}

variable "s3_bucket_key" {
  description = "The key for the Terraform state file in the S3 bucket"
  type        = string
  default     = "terraform.tfstate"
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "ecr-repository"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "ecs-cluster"
}

variable "ecs_task_execution_role_name" {
  description = "The name of the IAM role for ECS task execution"
  type        = string
  default     = "ecs-task-execution-role"
}

variable "task_role_name" {
  description = "The name of the IAM role for ECS tasks"
  type        = string
  default     = "task-role"
}

variable "ecs_task_definition_family" {
  description = "The family name of the ECS task definition"
  type        = string
  default     = "aws-task-definition"
}

variable "ecs_container_name" {
  description = "The name of the ECS container"
  type        = string
  default     = "ecs-container"
}

variable "ecs_service_name" {
  description = "The name of the ECS service"
  type        = string
  default     = "ecs-service"
}

variable "ecs_target_group_name" {
  description = "The name of the target group for the load balancer"
  type        = string
  default     = "ecs-target-group"
}

variable "ecs_load_balancer_name" {
  description = "The name of the load balancer"
  type        = string
  default     = "ecs-load-balancer"
}

variable "ecs_security_group_name" {
  description = "The name of the security group for the load balancer"
  type        = string
  default     = "ecs-security-group"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}