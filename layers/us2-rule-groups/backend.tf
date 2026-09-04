terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "us2-waf-tfstate"
    key    = "us2-rule-groups/terraform.tfstate"
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
    Layer       = "us2-rule-groups"
    Repo        = "techops-waf"
    Stack       = "waf"
    Region      = "us-west-2"
  }
}
