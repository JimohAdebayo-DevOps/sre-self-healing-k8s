# Using the same Python version as RAID exporter
FROM python:3.11-slim

# Set environment variables for production
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies for Postgres (needed for psycopg2)
RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Collect static files (CSS/JS) so the UI looks good
RUN python manage.py collectstatic --noinput

# Run with Gunicorn (Production Server) instead of 'runserver'
CMD ["gunicorn", "gridops_core.wsgi:application", "--bind", "0.0.0.0:8000"]

