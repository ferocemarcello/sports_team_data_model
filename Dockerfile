# Use a lightweight Python base image based on Debian 12 (Bookworm)
# and the latest stable Python version (3.12) for improved security and performance.
FROM python:3.12-slim-bookworm

# Set environment variables for PostgreSQL connection defaults
ENV PG_HOST=db
ENV PG_PORT=5432
ENV PG_DB=spond_db
ENV PG_USER=spond_user
ENV PG_PASSWORD=spond_password

# Install system dependencies required for psycopg2 (PostgreSQL client library)
# and then clean up apt cache to keep image size small
RUN apt-get update && \
    apt-get install -y libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

# Copy the requirements file and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Set the working directory inside the container
WORKDIR /app

# Copy the ingestion script and the 'data' directory into the container
COPY ingest_data.py .
COPY data/ ./data/

# Command to execute when the container starts
CMD ["python", "ingest_data.py"]