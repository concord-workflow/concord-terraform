resource "aws_db_subnet_group" "main" {
  name        = "${var.rds_postgres_identifier}-subnet"
  description = "Subnet for ${var.rds_postgres_identifier}"
  subnet_ids  = data.aws_subnet_ids.selected.ids
  tags        = var.tags
}

resource "aws_security_group" "main" {
  name        = "${var.rds_postgres_identifier}-sg"
  description = "Security group for ${var.rds_postgres_identifier}"
  vpc_id      = data.aws_vpc.selected.id
  tags        = var.tags
}

resource "aws_db_instance" "main" {
  allocated_storage       = var.rds_postgres_storage_size
  storage_type            = var.rds_postgres_storage_type
  engine                  = "postgres"
  engine_version          = var.rds_postgres_engine_version
  instance_class          = var.rds_postgres_instance_type
  backup_retention_period = 7
  identifier              = var.rds_postgres_identifier
  publicly_accessible     = false
  deletion_protection     = false
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.main.id
  # Postgres
  name                    = var.rds_postgres_database_name
  port                    = var.rds_postgres_port
  username                = var.rds_postgres_username
  password                = var.rds_postgres_password

  vpc_security_group_ids = [
    aws_security_group.main.id
  ]

  tags = var.tags
}

resource "aws_security_group_rule" "allow_db_outbound" {
  description       = "Allow all outbound"
  type              = "egress"
  security_group_id = aws_security_group.main.id
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_db_inbound" {
  description       = "Allow 5432 inbound"
  type              = "ingress"
  security_group_id = aws_security_group.main.id
  from_port         = var.rds_postgres_port
  to_port           = var.rds_postgres_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
