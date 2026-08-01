# ---- Stage 1: build ----
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ---- Stage 2: runtime ----
FROM python:3.11-slim

WORKDIR /app

# Create a non-root user
RUN useradd --create-home appuser

# Copy the installed packages from the builder stage
COPY --from=builder /root/.local /home/appuser/.local
COPY app ./app

# Make the copied packages owned by, and findable by, appuser
RUN chown -R appuser:appuser /home/appuser/.local /app
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]