
variable "rds_postgres_identifier" {
  type = string
}

variable "rds_postgres_storage_size" {
  type = number
  description = "Storage size in GB"
}

variable "rds_postgres_storage_type" {
  type = string
  default = "gp2"
}

variable "rds_postgres_instance_type" {
  type = string
}

variable "rds_postgres_engine_version" {
  type = string
  default = "10.6"
}

variable "rds_postgres_database_name" {
  type = string
  description = "Name of the database to create in the RDS instance"
}

variable "rds_postgres_port" {
  type = number
  default = 5432
}

variable "rds_postgres_username" {
  type = string
}

variable "rds_postgres_password" {
  type = string
}
