
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Reference the existing S3 bucket; Terraform will not create or delete it.
data "aws_s3_bucket" "portfolio" {
  bucket = "mudzo-test-bucket"
}

# CloudFront Origin Access Control allows CloudFront to read the private bucket.
resource "aws_cloudfront_origin_access_control" "portfolio" {
  name                              = "cloud-resume-portfolio-oac"
  description                       = "Secure access from CloudFront to the portfolio S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  comment             = "Cloud Resume Challenge portfolio"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = data.aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id                = "portfolio-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio.id
  }

  default_cache_behavior {
    target_origin_id       = "portfolio-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

output "cloudfront_domain_name" {
  description = "HTTPS domain for the portfolio website"
  value       = aws_cloudfront_distribution.portfolio.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.portfolio.id
}


resource "aws_s3_bucket_policy" "portfolio" {
  bucket = data.aws_s3_bucket.portfolio.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowCloudFrontReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${data.aws_s3_bucket.portfolio.arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.portfolio.arn
          }
        }
      }
    ]
  })
}

# DynamoDB table for the portfolio visitor counter.
resource "aws_dynamodb_table" "visitor_counter" {
  name         = "cloud-resume-visitor-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Lambda execution role.
resource "aws_iam_role" "visitor_counter_lambda" {
  name = "cloud-resume-visitor-counter-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Allow Lambda to update only the visitor-counter table.
resource "aws_iam_role_policy" "visitor_counter_lambda" {
  name = "visitor-counter-dynamodb-access"
  role = aws_iam_role.visitor_counter_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:UpdateItem"]
      Resource = aws_dynamodb_table.visitor_counter.arn
    }]
  })
}

# Python visitor-counter Lambda function.
resource "aws_lambda_function" "visitor_counter" {
  function_name    = "cloud-resume-visitor-counter"
  role             = aws_iam_role.visitor_counter_lambda.arn
  runtime          = "python3.12"
  handler          = "visitor_counter.lambda_handler"
  filename         = "${path.module}/../backend/visitor_counter.zip"
  source_code_hash = filebase64sha256("${path.module}/../backend/visitor_counter.zip")
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_counter.name
    }
  }

  depends_on = [aws_iam_role_policy.visitor_counter_lambda]
}

# Public HTTPS API for the portfolio visitor counter.
resource "aws_apigatewayv2_api" "visitor_counter" {
  name          = "cloud-resume-visitor-counter-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "visitor_counter" {
  api_id                 = aws_apigatewayv2_api.visitor_counter.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "visitor_counter" {
  api_id    = aws_apigatewayv2_api.visitor_counter.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.visitor_counter.id}"
}

resource "aws_apigatewayv2_stage" "visitor_counter" {
  api_id      = aws_apigatewayv2_api.visitor_counter.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "visitor_counter_api" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_counter.execution_arn}/*/*"
}

output "visitor_counter_api_url" {
  description = "HTTPS endpoint for the portfolio visitor counter"
  value       = "${aws_apigatewayv2_api.visitor_counter.api_endpoint}/count"
}
