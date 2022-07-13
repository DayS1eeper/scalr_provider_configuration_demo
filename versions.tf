terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    scalr = {
        source = "registry.scalr.dev/scalr/scalr"
        version= "1.0.0-rc-feature-scalrcore-21901"
    }
  }
}
