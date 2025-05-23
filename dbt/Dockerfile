FROM python:3.12-slim-buster

WORKDIR /usr/app/dbt

# Install dbt and its PostgreSQL adapter
RUN pip install --no-cache-dir dbt-postgres

# Copy dbt project files (will be mounted by docker-compose)
# This Dockerfile primarily sets up the environment, project files come from volume mounts.