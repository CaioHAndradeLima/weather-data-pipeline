output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "postgres_port" {
  value = aws_db_instance.postgres.port
}

output "postgres_db_name" {
  value = var.db_name
}
