variable "PG_HOST" {
  description = "PostgreSQL host"
  type        = string
}

variable "PG_PORT" {
  description = "PostgreSQL port"
  type        = number
}

variable "PG_USER" {
  description = "PostgreSQL username"
  type        = string
}

variable "PG_PASSWORD" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "PG_DBNAME" {
  description = "PostgreSQL database name for initial connection (e.g., 'postgres')"
  type        = string
}