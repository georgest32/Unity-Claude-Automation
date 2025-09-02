# Unity-Claude-Automation Docker Configuration

## Overview

This directory contains Docker configurations for containerizing the Unity-Claude-Automation multi-agent system. The setup uses Docker Compose to orchestrate multiple services with proper isolation and networking.

## Services

### 1. PowerShell Modules Service (`powershell-modules`)
- **Base Image**: mcr.microsoft.com/dotnet/sdk:9.0
- **Port**: 5985, 5986 (PowerShell remoting)
- **Purpose**: Hosts Unity-Claude PowerShell modules
- **Health Check**: Verifies module availability

### 2. LangGraph REST API (`langgraph-api`)
- **Base Image**: python:3.12-slim
- **Port**: 8000
- **Purpose**: Provides REST API for agent orchestration
- **Dependencies**: FastAPI, LangGraph, SQLite

### 3. AutoGen GroupChat (`autogen-groupchat`)
- **Base Image**: python:3.12-slim
- **Port**: 8001
- **Purpose**: Multi-agent collaboration service
- **Dependencies**: PyAutoGen, FastAPI

### 4. Documentation Server (`docs-server`)
- **Base Image**: nginx:alpine
- **Port**: 8080
- **Purpose**: Serves MkDocs documentation
- **Static Files**: Built during container creation

### 5. File Monitor (`file-monitor`)
- **Base Image**: mcr.microsoft.com/dotnet/sdk:9.0
- **Purpose**: Monitors file changes and triggers actions
- **Volumes**: Watches project directory

## Quick Start

### Prerequisites
1. Docker Desktop installed with WSL2 backend
2. Docker Compose v2.0+
3. PowerShell 7.0+

### Setup Steps

1. **Copy environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

2. **Build all services**:
   ```bash
   docker compose build
   ```

3. **Start services**:
   ```bash
   docker compose up -d
   ```

4. **Check service health**:
   ```bash
   docker compose ps
   docker compose logs
   ```

## Development Workflow

### Building Individual Services
```bash
# Build specific service
docker compose build powershell-modules

# Build with no cache
docker compose build --no-cache langgraph-api
```

### Viewing Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f langgraph-api
```

### Accessing Services
- **Documentation**: http://localhost:8080
- **LangGraph API**: http://localhost:8000
- **AutoGen API**: http://localhost:8001

### Debugging
```bash
# Execute command in running container
docker compose exec powershell-modules pwsh

# Access container shell
docker compose exec langgraph-api /bin/bash
```

## Production Deployment

### Security Considerations
1. Never commit `.env` file with real credentials
2. Use Docker secrets for sensitive data
3. Run containers as non-root users
4. Implement proper health checks
5. Use read-only volumes where possible

### Registry Setup
```bash
# Tag images with version
docker tag unity-claude-powershell:latest myregistry.com/unity-claude-powershell:1.0.0

# Push to registry
docker push myregistry.com/unity-claude-powershell:1.0.0
```

### Scaling
```bash
# Scale specific service
docker compose up -d --scale autogen-groupchat=3
```

## Volumes

- `module-data`: PowerShell modules storage
- `langgraph-data`: LangGraph SQLite database
- `monitoring-logs`: File change logs
- `shared-config`: Shared configuration files

## Networks

- `unity-claude-net`: Custom bridge network (172.20.0.0/16)
  - Provides service isolation
  - Enables service discovery by name

## Troubleshooting

### Common Issues

1. **Container fails to start**:
   - Check logs: `docker compose logs [service-name]`
   - Verify Docker Desktop is running
   - Ensure WSL2 is properly configured

2. **Module import errors**:
   - Verify modules are copied correctly
   - Check PSModulePath environment variable
   - Review startup.ps1 script logs

3. **API connection refused**:
   - Verify port mappings
   - Check service health: `docker compose ps`
   - Ensure no port conflicts

4. **Permission denied errors**:
   - Check user permissions in Dockerfile
   - Verify volume mount permissions
   - Run with appropriate user context

## Maintenance

### Cleanup
```bash
# Stop all services
docker compose down

# Remove volumes (WARNING: deletes data)
docker compose down -v

# Remove unused images
docker image prune -a
```

### Updates
```bash
# Pull latest base images
docker compose pull

# Rebuild and restart
docker compose up -d --build
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Docker Build and Push
on:
  push:
    branches: [main]
    
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and push
        run: |
          docker compose build
          docker compose push
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Host (Windows/WSL2)            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │ PowerShell  │  │  LangGraph  │  │   AutoGen   │   │
│  │   Modules   │◄─┤   REST API  │◄─┤  GroupChat  │   │
│  └─────────────┘  └─────────────┘  └─────────────┘   │
│         ▲                ▲                ▲           │
│         └────────────────┼────────────────┘           │
│                          │                            │
│  ┌─────────────┐  ┌─────────────┐                   │
│  │    Docs     │  │    File     │                   │
│  │   Server    │  │   Monitor   │                   │
│  └─────────────┘  └─────────────┘                   │
│                                                       │
│            unity-claude-net (172.20.0.0/16)          │
└───────────────────────────────────────────────────────┘
```

## Version History

- **1.0.0** - Initial containerization with 5 core services
- **1.1.0** - (Planned) Add MCP server containers
- **1.2.0** - (Planned) Kubernetes deployment manifests

## Support

For issues and questions:
- Check logs first: `docker compose logs`
- Review this README and troubleshooting section
- Consult IMPORTANT_LEARNINGS.md for known issues