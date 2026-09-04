terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "us1-waf-tfstate"
    key    = "us1-regex-patterns/terraform.tfstate"
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
    Layer       = "us1-regex-patterns"
    Repo        = "techops-waf-mangalyaan"
    Stack       = "waf"
    Region      = "us-east-1"
  }
}
