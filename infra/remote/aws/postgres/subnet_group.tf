resource "aws_db_subnet_group" "postgres" {
  name       = "retail-postgres-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "retail-postgres-subnet-group"
  }
}
