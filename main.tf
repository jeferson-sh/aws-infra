# Terraform para AWS Lambda com Spring Native e API Gateway (Binário Nativo)

provider "aws" {
  region = var.aws_region  # Defina a região desejada
}

# Configuração do backend S3 para armazenar o estado do Terraform
terraform {
  backend "s3" {
    bucket = "bucket-s3-terraform"  # Nome do bucket S3 onde o estado será armazenado
    key    = "terraform.tfstate"  # Nome do arquivo de estado no bucket
    region = var.aws_region  # Região onde o bucket S3 está localizado
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "spring_native_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "example.handler::handleRequest"
  runtime       = "provided.al2"  # Utilizamos o runtime customizado para rodar binários nativos

  filename         = "${path.module}/${var.lambda_zip_file}"  # Arquivo zip contendo o build nativo
  source_code_hash = filebase64sha256("${path.module}/${var.lambda_zip_file}")

  environment {
    variables = {
      JAVA_TOOL_OPTIONS = "-Dspring.native.remove-yaml-support=true"
    }
  }

  memory_size      = var.lambda_memory_size  # O valor pode ser ajustado conforme necessário
  timeout          = var.lambda_timeout      # O tempo pode ser aumentado dependendo da execução
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.spring_native_lambda.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spring_native_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.spring_native_lambda.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /api/v1/messages"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

output "lambda_function_name" {
  value = aws_lambda_function.spring_native_lambda.function_name
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
