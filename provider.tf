provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    dynamodb_table = "state-lock"
    bucket = "s3statebackendatindra"
    key = "global/mystatefile/terrafrom.tfstate"
    region = "us-east-1"
  }
}

# create s3
resource "aws_s3_bucket" "mybucket"{
    bucket  = "s3statebackendatindra"
    versioning {
        enabled = true
    }
}


# create dynamodb
resource "aws_dynamodb_table" "statelock" {
  name = "state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

# godaddy provider for managing sub domains for wasy access for websites

provider "godaddy-dns" {}

terraform {
  required_providers {
    godaddy-dns = {
      source = "registry.terraform.io/veksh/godaddy-dns"
    }
  }
}