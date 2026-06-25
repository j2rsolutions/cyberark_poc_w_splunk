terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }
  }
}

variable "aws_profile" {
  description = "AWS CLI profile used for the GovCloud CyberArk account."
  type        = string
  default     = "172363844851_AdministratorAccess"
}

variable "aws_region" {
  description = "GovCloud region hosting the CyberArk POC."
  type        = string
  default     = "us-gov-east-1"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
