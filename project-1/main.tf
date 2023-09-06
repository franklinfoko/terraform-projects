provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAZKRZUH4TVFWKJFPV"
  secret_key = "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"
}

resource "aws_vpc" "vpc-1" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "vpc-project"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet-project"
  }
}
