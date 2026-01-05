terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "rajo-terraform-state"      # update with your bucket
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"           # optional but recommended for state locking
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
}
