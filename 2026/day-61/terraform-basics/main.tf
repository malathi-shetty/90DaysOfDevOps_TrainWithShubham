terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "terra_bucket" {
  bucket = "terraweek-malathi-2026-unique12345"
}

resource "aws_instance" "terra_ec2" {
  ami           = "ami-003c5247665391546"
  instance_type = "t3.micro"

  tags = {
    Name = "TerraWeek-Modified"
  }
}
