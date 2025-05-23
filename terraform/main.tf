terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
  }
}

# Add this provider block if it's not already there,
# or add sslmode = "disable" if the block exists.
provider "postgresql" {
  host            = "localhost" # Terraform connects directly to the exposed host port
  port            = 5432
  username        = "postgres"
  password        = "postgres" # Or use a variable/secret for production
  database        = "spond_analytics" # Ensure this matches your DB_NAME
  sslmode         = "disable" # <--- ADD THIS LINE
}

resource "postgresql_database" "spond_analytics" {
  name  = "spond_analytics"
  owner = "postgres"
}