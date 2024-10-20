# Variáveis em `variables.tf`
variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-2"
}

variable "lambda_function_name" {
  description = "Nome da função Lambda"
  type        = string
  default     = "spring-native-lambda"
}

variable "lambda_zip_file" {
  description = "Caminho para o arquivo zip da função Lambda"
  type        = string
  default     = "spring-native-function.zip"
}

variable "lambda_memory_size" {
  description = "Tamanho da memória (MB) para a função Lambda"
  type        = number
  default     = 1024
}

variable "lambda_timeout" {
  description = "Timeout (em segundos) para a execução da função Lambda"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs no CloudWatch"
  type        = number
  default     = 14
}

variable "api_gateway_name" {
  description = "Nome do API Gateway HTTP"
  type        = string
  default     = "spring-native-api-gateway"
}
