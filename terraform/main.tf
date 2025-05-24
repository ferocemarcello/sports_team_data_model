terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
  }
}

provider "postgresql" {
  host            = var.PG_HOST
  port            = var.PG_PORT
  username        = var.PG_USER
  password        = var.PG_PASSWORD
  database        = var.PG_DBNAME
  sslmode         = "disable"
}

resource "postgresql_database" "spond_analytics" {
  name  = "spond_analytics"
  owner = "postgres"
}