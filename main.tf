terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  #setup for terraform cloud automation
  cloud {
    organization = "FinalMix"

    workspaces {
      name = "assessment-github"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}




