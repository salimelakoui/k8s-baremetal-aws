terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.47"
    }
  }
}

variable "region" {
  description = "Target region"
  default     = "eu-west-3"
}

variable "profile" {
  description = "The profile you want to use"
  default     = "default"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}
