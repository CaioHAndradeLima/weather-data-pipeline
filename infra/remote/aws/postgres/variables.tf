variable "aws_region" {
  type        = string
  description = "AWS region"
}

# Postgres

variable "db_name" {
  type        = string
  description = "Postgres database name"
}

variable "db_username" {
  type        = string
  description = "Postgres master username"
}

variable "db_password" {
  type        = string
  description = "Postgres master password"
  sensitive   = true
}

# Network VPC

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}
