terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
  }
}

resource "postgresql_database" "spond_analytics" {
  name  = "spond_analytics"
  owner = "postgres"
}