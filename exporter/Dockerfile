# 1. Base image (Slightly newer version for better security)
FROM python:3.11-slim

# 2. Set the internal folder where the app will live
WORKDIR /app

# 3. Copy only requirements first (Optimizes Docker layer caching)
COPY src/requirements.txt .

# 4. Install libraries from the requirements file
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy your exporter code from the src folder
COPY src/exporter.py .

# 6. Run the script (matches your new filename)
CMD ["python", "exporter.py"]
