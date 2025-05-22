terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.25.0"
    }
  }
}

# Provider configuration to connect to the PostgreSQL Docker container
provider "postgresql" {
  host            = "localhost"
  port            = 5432
  database        = "postgres" # Connect to the default 'postgres' database initially
  username        = "postgres"
  password        = "postgres"
  sslmode         = "disable" # Disable SSL for local development
  connect_timeout = 15
}

# Create the main database for analytics
resource "postgresql_database" "spond_analytics" {
  name  = "spond_analytics"
  owner = "postgres" # The owner role for the new database
}

# Create tables using a null_resource and local-exec provisioner
# This is a workaround because the cyrilgdn/postgresql provider does not
# directly support 'postgresql_table' resource type.
resource "null_resource" "create_tables" {
  # Ensure this resource runs after the database is created
  depends_on = [postgresql_database.spond_analytics]

  # Trigger a re-run if the schema.sql file changes
  triggers = {
    schema_hash = filemd5("${path.module}/../data/schema.sql")
  }

  provisioner "local-exec" {
    # Execute psql command inside the running 'spond-postgres' Docker container
    # The -i flag allows piping the SQL file content as standard input
    # The PGPASSWORD environment variable is used for authentication
    command = "docker exec -i spond-postgres psql -U postgres -d spond_analytics < ${path.module}/../data/schema.sql"
    environment = {
      PGPASSWORD = "postgres" # Use the password set for the postgres user
    }
    # Set working directory to terraform module path for correct file path resolution
    working_dir = path.module
  }
}