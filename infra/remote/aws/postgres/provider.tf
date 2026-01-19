provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::926878603136:role/terraform-role"
  }
}
