variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "web-lambda-demo"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package"
  type        = string
  default     = "../web-lambda.zip"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"  # Risky - defaulting to production
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "web-lambda-demo"
    Owner       = "devops-team"
    # Missing required tags
    # Missing cost center tags
    # Missing compliance tags
  }
}
