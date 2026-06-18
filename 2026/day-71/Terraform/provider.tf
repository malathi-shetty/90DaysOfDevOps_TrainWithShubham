provider "aws" {
  region = "us-west-2"
}

terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
    }
  }
}