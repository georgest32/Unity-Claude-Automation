# Multi-stage build for AutoGen GroupChat service
# Stage 1: Build dependencies
FROM python:3.12 AS builder

# Install UV for fast package management
RUN pip install uv

# Create virtual environment
RUN uv venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
RUN uv pip install pyautogen fastapi uvicorn pydantic httpx

# Stage 2: Runtime
FROM python:3.12-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash agentuser

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Set environment variables
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV AUTOGEN_USE_DOCKER=0

# Create working directory
WORKDIR /app

# Copy application code
COPY agents/autogen_groupchat_server.py /app/
COPY agents/autogen_groupchat_config.py /app/
COPY agents/autogen_supervisor_config.py /app/
COPY agents/test_agent_interactions.py /app/
COPY agents/powershell_autogen_bridge.py /app/
COPY agents/message_queue_handler.py /app/
COPY agents/agent_message_protocol.py /app/

RUN chown -R agentuser:agentuser /app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Switch to non-root user
USER agentuser

# Expose port
EXPOSE 8001

# Run the application with proper host binding
CMD ["uvicorn", "autogen_groupchat_server:app", "--host", "0.0.0.0", "--port", "8001", "--reload", "--access-log"]