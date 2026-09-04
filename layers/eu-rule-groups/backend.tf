terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "eu-waf-tfstate"
    key    = "eu-rule-groups/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

locals {
  common_tags = {
    Environment = "all"
    ManagedBy   = "terraform"
    Layer       = "eu-rule-groups"
    Repo        = "techops-waf"
    Stack       = "waf"
    Region      = "eu-central-1"
  }
}
