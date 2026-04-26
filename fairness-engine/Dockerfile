# ---------- FairTerms Fairness Engine ----------
# Multi-stage build for a lean production image

FROM python:3.11-slim AS builder

WORKDIR /app

# Install dependencies first (cache layer)
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Runtime stage ----------
FROM python:3.11-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy source code and data
COPY src/ ./src/
COPY data/ ./data/

# Environment defaults
ENV PORT=8080
ENV HOST=0.0.0.0
ENV BIGQUERY_ENABLED=false
ENV SEED_DATA_PATH=data/seed_data.csv

EXPOSE 8080

# Run with uvicorn
CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
