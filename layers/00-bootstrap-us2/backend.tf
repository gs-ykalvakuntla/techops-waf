terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }

  # FIRST APPLY: comment out s3 backend, uncomment local
  # AFTER FIRST APPLY: re-enable s3 and run: terraform init -migrate-state
  #
  # backend "local" {}

  backend "s3" {
    bucket = "us2-waf-tfstate"
    key    = "00-bootstrap/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}

locals {
  common_tags = {
    Environment = "all"
    ManagedBy   = "terraform"
    Layer       = "00-bootstrap"
    Repo        = "techops-waf"
    Stack       = "waf"
    Region      = "us-west-2"
  }
}
