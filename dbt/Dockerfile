FROM python:3.12-slim-buster

WORKDIR /usr/app/dbt

RUN pip install --no-cache-dir dbt-postgres

# dbt project files and profiles.yml are mounted via docker-compose.yml volumes.