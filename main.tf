resource "aws_iam_policy" "lambda-policy" {
  name        = "lambdaPolicy"
  path        = "/"
  description = "Allow write to S3 and read System Parameter"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "AllowPutObject",
        "Effect" = "Allow",
        "Action" = [
          "s3:PutObject"
        ],
        "Resource" = [
          "*"
        ]
      },
      {
        "Sid"    = "AllowGetParameterSSM",
        "Effect" = "Allow",
        "Action" = [
          "ssm:GetParameter"
        ],
        "Resource" = [
          "*"
        ]
      },
      {
        "Sid"    = "AllowGetSecretValue",
        "Effect" = "Allow",
        "Action" = [
          "secretmanager:GetSecretValue"
        ],
        "Resource" = [
          "*"
        ]
      }
    ]
    }
  )
}

resource "aws_iam_role" "reporting_lambda_role" {
  name = "ReportingLambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.reporting_lambda_role.name
  policy_arn = aws_iam_policy.lambda-policy.arn
}

output "vpc_id" {
  value = aws_vpc.nb-chatgpt-vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.nb-subnet["public-net"].id
}

output "private_subnet_id" {
  value = aws_subnet.nb-subnet["private-net-1"].id
}


output "nat_gateway_public_ip" {
  value = aws_nat_gateway.nb-nat-gw.public_ip
}