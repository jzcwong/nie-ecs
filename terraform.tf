terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.34.0"
    }
  }
}

provider "aws" {
  region              = "us-west-2"
  shared_config_files = ["~/.aws/config"]
  profile             = "AdministratorAccess-142764079456"
}