# Multi-stage build for PowerShell modules container
# Stage 1: Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS builder

# Set PowerShell as the default shell
SHELL ["pwsh", "-Command"]

# Create module directory
RUN New-Item -Path /opt/modules -ItemType Directory -Force

# Copy PowerShell modules
COPY Modules/ /opt/modules/

# Install any required PowerShell modules from PSGallery
RUN Install-Module -Name PSScriptAnalyzer -Scope AllUsers -Force -AllowClobber; \
    Install-Module -Name Pester -Scope AllUsers -Force -AllowClobber

# Stage 2: Runtime stage
FROM mcr.microsoft.com/dotnet/sdk:9.0

# Install PowerShell if not included
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set PowerShell as the default shell
SHELL ["pwsh", "-Command"]

# Create non-root user
RUN useradd -m -s /bin/bash psuser

# Copy modules from builder stage
COPY --from=builder /opt/modules /opt/modules

# Set PSModulePath
ENV PSModulePath="/opt/modules:/usr/local/share/powershell/Modules:/root/.local/share/powershell/Modules"

# Create working directory
WORKDIR /app

# Copy startup script
COPY docker/powershell/startup.ps1 /app/startup.ps1

# Health check to verify PowerShell is working and modules are loaded
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["pwsh", "-Command", "if (Get-Module -ListAvailable -Name Unity-Claude-*) { exit 0 } else { exit 1 }"]

# Switch to non-root user
USER psuser

# Expose port for PowerShell remoting (optional)
EXPOSE 5985 5986

# Default command
CMD ["pwsh", "-File", "/app/startup.ps1"]