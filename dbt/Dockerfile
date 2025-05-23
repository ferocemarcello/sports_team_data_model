FROM python:3.9-slim-buster

WORKDIR /usr/app/dbt

# Install dbt and its PostgreSQL adapter
RUN pip install --no-cache-dir dbt-postgres

# No other COPY commands are needed here for project files.
# dbt project files and profiles.yml are mounted via docker-compose.yml volumes.