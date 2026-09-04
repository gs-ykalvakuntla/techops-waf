terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }

  # FIRST APPLY: comment out the s3 backend below and uncomment local
  # AFTER FIRST APPLY: re-enable s3 backend and run: terraform init -migrate-state
  #
  # backend "local" {}

  backend "s3" {
    bucket = "us1-waf-tfstate"
    key    = "00-bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  common_tags = {
    Environment = "all"
    ManagedBy   = "terraform"
    Layer       = "00-bootstrap"
    Repo        = "techops-waf"
    Stack       = "waf"
    Region      = "us-east-1"
  }
}
