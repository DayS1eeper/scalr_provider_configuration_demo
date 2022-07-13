# ------------- create aws user that can assume role that has permission to create ec2 instance --------------
resource "random_string" "external_id" {
  length = 10
  special = false
}


resource "aws_iam_user" "role_delegation_test" {
  name = "go_scal_role_delegation_test"
}

resource "aws_iam_access_key" "role_delegation_test" {
  user = aws_iam_user.role_delegation_test.name
}

resource "aws_iam_role" "role_delegation_test" {
  name = "go_scal_role_delegation_test"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.role_delegation_test.arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = random_string.external_id.id
          }
        }
      },
    ]
  })
  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
                "ec2:*",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

}

# ------------- provider configuration with aws user credentials --------------
resource "scalr_provider_configuration" "aws" {
  name                   = "aws_dev"
  account_id             = var.account_id
  export_shell_variables = false
  is_shared = false
  aws {
    account_type        = "regular"
    credentials_type    = "role_delegation"
    access_key          = aws_iam_access_key.role_delegation_test.id
    secret_key          = aws_iam_access_key.role_delegation_test.secret
    role_arn            = aws_iam_role.role_delegation_test.arn
    external_id         = random_string.external_id.id
    trusted_entity_type = "aws_account"
  }
}

resource "scalr_environment" "test" {
  name                    = "pcfg-demo"
  account_id              = var.account_id
  cost_estimation_enabled = false
  # default_provider_configuration = ["pcfg-1", "pcfg-2"]
}

resource "scalr_workspace" "test" {
  name                   = "workspace-pcfg-demo"
  environment_id         = scalr_environment.test.id
  auto_apply             = false
  operations             = false

  provider_configuration {
    id = scalr_provider_configuration.aws.id
  }
}