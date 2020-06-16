output "rds_postgres_database_name" {
  value = aws_db_instance.main.name
}

output "rds_postgres_username" {
  value = aws_db_instance.main.username
}

output "rds_db_host" {
  value = aws_db_instance.main.address
}

output "rds_db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_postgres_port" {
  value = aws_db_instance.main.port
}

output "rds_db_arn" {
  value = aws_db_instance.main.arn
}
