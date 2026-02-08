resource "aws_db_subnet_group" "postgres" {
  name       = "weather-postgres-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "weather-postgres-subnet-group"
  }
}
