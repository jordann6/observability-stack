terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  # default_tags is the only way to guarantee tags reach resources created
  # inside the vpc/eks modules (HCL analysis cannot see inside a module), which
  # is exactly what the platform-guardrails tags.rego and finops.rego gates
  # require. CostCenter is what every chargeback/showback report groups by.
  default_tags {
    tags = {
      Project     = "observability-stack"
      Environment = var.environment
      Owner       = "jordan"
      ManagedBy   = "terraform"
      CostCenter  = var.cost_center
      Lifecycle   = "deploy-demo-destroy"
    }
  }
}
