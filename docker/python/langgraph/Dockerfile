# Multi-stage build for LangGraph REST API service
# Stage 1: Build dependencies
FROM python:3.12 AS builder

# Install UV for fast package management
RUN pip install uv

# Create virtual environment
RUN uv venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements
COPY agents/requirements.txt /tmp/requirements.txt

# Install dependencies using UV
RUN uv pip install -r /tmp/requirements.txt && \
    uv pip install fastapi uvicorn langgraph langgraph-checkpoint-sqlite httpx

# Stage 2: Runtime
FROM python:3.12-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash apiuser

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Set environment variables
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# Create working directory
WORKDIR /app

# Copy application code
COPY agents/langgraph_rest_server.py /app/
COPY agents/powershell_autogen_bridge.py /app/
COPY agents/message_queue_handler.py /app/
COPY agents/agent_message_protocol.py /app/

# Create data directory for SQLite
RUN mkdir -p /app/data && chown -R apiuser:apiuser /app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Switch to non-root user
USER apiuser

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "langgraph_rest_server:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]