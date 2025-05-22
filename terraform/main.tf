# Configure the PostgreSQL provider
# Need to install the PostgreSQL provider: terraform init
terraform {
  required_providers {
    postgresql = {
      source  = "dbt-labs/postgresql"
      version = "~> 1.0" # Use a compatible version
    }
  }
}

resource "postgresql_database" "spond_db" {
  name  = "spond_analytics"
  owner = "postgres" # Or a dedicated user if you create one
}

resource "postgresql_schema" "public" {
  name     = "public"
  database = postgresql_database.spond_db.name
  owner    = "postgres"
}

# Define tables
resource "postgresql_table" "teams" {
  database_name = postgresql_database.spond_db.name
  name          = "teams"
  schema_name   = postgresql_schema.public.name
  owner         = "postgres"
  force_recreate = true # For development, allows easy recreation

  column {
    name = "team_id"
    type = "TEXT"
    nullable = false
  }
  column {
    name = "group_activity"
    type = "TEXT"
  }
  column {
    name = "country_code"
    type = "TEXT"
  }
  column {
    name = "created_at"
    type = "BIGINT" # Storing as seconds from epoch
  }

  primary_key {
    columns = ["team_id"]
  }
}

resource "postgresql_table" "members" {
  database_name = postgresql_database.spond_db.name
  name          = "members"
  schema_name   = postgresql_schema.public.name
  owner         = "postgres"
  force_recreate = true

  column {
    name = "membership_id"
    type = "TEXT"
    nullable = false
  }
  column {
    name = "group_id"
    type = "TEXT"
  }
  column {
    name = "role_title"
    type = "TEXT"
  }
  column {
    name = "joined_at"
    type = "BIGINT"
  }

  primary_key {
    columns = ["membership_id"]
  }

  # Foreign Key Constraint
  # This constraint requires the 'teams' table to exist first.
  # Terraform handles dependencies implicitly based on resource references.
  foreign_key {
    columns        = ["group_id"]
    foreign_table  = postgresql_table.teams.name
    foreign_schema = postgresql_schema.public.name
    foreign_columns = ["team_id"]
    on_delete      = "CASCADE" # Or "SET NULL", depending on desired behavior for data deletion [cite: 26]
  }
}

resource "postgresql_table" "events" {
  database_name = postgresql_database.spond_db.name
  name          = "events"
  schema_name   = postgresql_schema.public.name
  owner         = "postgres"
  force_recreate = true

  column {
    name = "event_id"
    type = "TEXT"
    nullable = false
  }
  column {
    name = "team_id"
    type = "TEXT"
  }
  column {
    name = "event_start"
    type = "BIGINT"
  }
  column {
    name = "event_end"
    type = "BIGINT"
  }
  column {
    name = "created_at"
    type = "BIGINT"
  }

  primary_key {
    columns = ["event_id"]
  }

  foreign_key {
    columns        = ["team_id"]
    foreign_table  = postgresql_table.teams.name
    foreign_schema = postgresql_schema.public.name
    foreign_columns = ["team_id"]
    on_delete      = "CASCADE"
  }
}

resource "postgresql_table" "event_rsvps" {
  database_name = postgresql_database.spond_db.name
  name          = "event_rsvps"
  schema_name   = postgresql_schema.public.name
  owner         = "postgres"
  force_recreate = true

  column {
    name = "event_rsvp_id"
    type = "TEXT"
    nullable = false
  }
  column {
    name = "event_id"
    type = "TEXT"
  }
  column {
    name = "member_id"
    type = "TEXT"
  }
  column {
    name = "rsvp_status"
    type = "INTEGER" # Enum (0=unanswered; 1=accepted; 2=declined) [cite: 14]
  }
  column {
    name = "responded_at"
    type = "BIGINT"
  }

  primary_key {
    columns = ["event_rsvp_id"]
  }

  foreign_key {
    columns        = ["event_id"]
    foreign_table  = postgresql_table.events.name
    foreign_schema = postgresql_schema.public.name
    foreign_columns = ["event_id"]
    on_delete      = "CASCADE"
  }

  foreign_key {
    columns        = ["member_id"]
    foreign_table  = postgresql_table.members.name
    foreign_schema = postgresql_schema.public.name
    foreign_columns = ["membership_id"]
    on_delete      = "CASCADE"
  }
}
