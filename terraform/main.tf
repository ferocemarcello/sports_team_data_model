resource "postgresql_database" "spond_analytics" {
  name  = "spond_analytics"
  owner = "postgres"
}
# Removed the 'null_resource.create_tables' block
# as table creation is now handled by ingest_data.py