# Configurações em `terraform.tfvars`
aws_region           = "us-east-2"
lambda_function_name = "spring-native-lambda"
lambda_zip_file      = "spring-native-function.zip"
lambda_memory_size   = 1024
lambda_timeout       = 30
log_retention_days   = 14
api_gateway_name     = "spring-native-api-gateway"
