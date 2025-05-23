terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
  }
}

provider "postgresql" {
  host            = "localhost"
  port            = 5432
  username        = "postgres"
  password        = "postgres"
  database        = "postgres" # Important: connect to 'postgres' to create 'spond_analytics'
  sslmode         = "disable"
}

resource "postgresql_database" "spond_analytics" {
  name  = "spond_analytics"
  owner = "postgres"
}