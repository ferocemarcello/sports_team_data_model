# Use the specified base image
FROM python:3.12-slim-bookworm

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the ingestion script and the data directory into the container
COPY ingest_data.py .
COPY data/ ./data/

# Expose the default PostgreSQL port, though not strictly necessary for a local simulation within the container
EXPOSE 5432

# Command to run the ingestion script when the container starts
# This will be overridden by the setup.sh script for the full flow
CMD ["python", "ingest_data.py"]