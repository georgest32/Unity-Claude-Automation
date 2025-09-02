# Monitoring Service with File Watcher
FROM mcr.microsoft.com/dotnet/sdk:9.0

# Install PowerShell modules for monitoring
SHELL ["pwsh", "-Command"]

# Create non-root user
RUN useradd -m -s /bin/bash monitoruser

# Create directories
RUN New-Item -Path /opt/monitoring -ItemType Directory -Force; \
    New-Item -Path /var/log/monitoring -ItemType Directory -Force

# Copy monitoring modules
COPY Modules/Unity-Claude-FileMonitor/ /opt/modules/Unity-Claude-FileMonitor/
COPY Modules/Unity-Claude-DocumentationDrift/ /opt/modules/Unity-Claude-DocumentationDrift/

# Set PSModulePath
ENV PSModulePath="/opt/modules:/usr/local/share/powershell/Modules"

# Copy monitoring script
COPY docker/monitoring/monitor.ps1 /opt/monitoring/monitor.ps1

# Set permissions
RUN chown -R monitoruser:monitoruser /opt/monitoring /var/log/monitoring

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["pwsh", "-Command", "if (Get-Process pwsh) { exit 0 } else { exit 1 }"]

# Switch to non-root user
USER monitoruser

# Working directory
WORKDIR /opt/monitoring

# Volume for watching files
VOLUME ["/watch", "/var/log/monitoring"]

# Run monitoring service
CMD ["pwsh", "-File", "/opt/monitoring/monitor.ps1"]