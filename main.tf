# Risky Terraform configuration for Lambda deployment
terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"  # Using older version
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # Risky - no assume role, using default credentials
  # Risky - no version constraints
}

# Risky - S3 bucket without encryption
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${var.project_name}-lambda-deployments-${random_string.bucket_suffix.result}"
  
  # Missing encryption configuration
  # Missing versioning
  # Missing public access block
}

# Risky - S3 bucket policy allows public read
resource "aws_s3_bucket_policy" "lambda_bucket_policy" {
  bucket = aws_s3_bucket.lambda_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.lambda_bucket.arn}/*"
      }
    ]
  })
}

# Risky - IAM role with overly permissive policies
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Risky - IAM policy with wildcard permissions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:*",  # Risky - wildcard S3 permissions
          "rds:*", # Risky - wildcard RDS permissions
          "ec2:*", # Risky - wildcard EC2 permissions
          "iam:*"  # Risky - wildcard IAM permissions
        ]
        Resource = "*"
      }
    ]
  })
}

# Risky - Lambda function without encryption
resource "aws_lambda_function" "web_lambda" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_name}-web-lambda"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime         = "nodejs14.x"  # Using older Node.js version
  
  # Missing encryption configuration
  # Missing VPC configuration
  # Missing environment variables encryption
  
  environment {
    variables = {
      JWT_SECRET = "hardcoded-secret-key"  # Risky - hardcoded secret
      DB_PASSWORD = "hardcoded-db-password"  # Risky - hardcoded password
      DB_HOST = "localhost"  # Risky - hardcoded host
      DB_USER = "root"  # Risky - hardcoded user
      DB_NAME = "testdb"  # Risky - hardcoded database name
      REDIS_HOST = "localhost"  # Risky - hardcoded Redis host
      REDIS_PORT = "6379"  # Risky - hardcoded Redis port
    }
  }
  
  # Risky - no timeout configuration
  # Risky - no memory configuration
  # Risky - no dead letter queue
}

# Risky - API Gateway without authentication
resource "aws_api_gateway_rest_api" "web_api" {
  name = "${var.project_name}-web-api"
  
  # Missing authentication configuration
  # Missing CORS configuration
  # Missing rate limiting
}

# Risky - API Gateway resource without proper configuration
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.web_api.id
  parent_id   = aws_api_gateway_rest_api.web_api.root_resource_id
  path_part   = "{proxy+}"
}

# Risky - API Gateway method without authentication
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.web_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"  # Risky - no authorization
  
  # Missing request validation
  # Missing rate limiting
}

# Risky - API Gateway integration without proper configuration
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.web_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.web_lambda.invoke_arn
  
  # Missing request/response mapping
  # Missing timeout configuration
}

# Risky - API Gateway deployment without stage configuration
resource "aws_api_gateway_deployment" "web_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.web_api.id
  stage_name  = "prod"  # Risky - using prod stage name
  
  # Missing stage configuration
  # Missing logging configuration
  # Missing caching configuration
}

# Risky - Lambda permission without source ARN restriction
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.web_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.web_api.execution_arn}/*/*"
  
  # Missing source ARN restriction
}

# Risky - CloudWatch Log Group without retention
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.web_lambda.function_name}"
  retention_in_days = 0  # Risky - logs never expire
  
  # Missing encryption
  # Missing tags
}

# Risky - Random string for bucket suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Risky - Output sensitive information
output "lambda_function_arn" {
  value = aws_lambda_function.web_lambda.arn
  description = "ARN of the Lambda function"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.web_api_deployment.invoke_url
  description = "URL of the API Gateway"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.lambda_bucket.bucket
  description = "Name of the S3 bucket"
}
