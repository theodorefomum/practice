terraform {
  backend "s3" {
    bucket = "jenkinsk8spipelinebucket"
    region = "us-east-1"
    key    = "eks/terraform.tfstate"
  }
}