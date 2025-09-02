# Container Registry Setup Guide

## Overview

This guide covers the setup and usage of GitHub Container Registry (ghcr.io) for the Unity-Claude-Automation project.

## Quick Start

### 1. Local Authentication

```powershell
# Create a Personal Access Token (PAT) on GitHub with 'write:packages' scope
# https://github.com/settings/tokens

# Login to GitHub Container Registry
docker login ghcr.io -u YOUR_GITHUB_USERNAME

# Enter your PAT as the password when prompted
```

### 2. Build and Push Images

```powershell
# Build and push all services with version bump
.\docker\Manage-DockerVersion.ps1 -BumpType patch -Push

# Build specific service
.\docker\Manage-DockerVersion.ps1 -Services @('langgraph-api') -Push

# Custom version
.\docker\Manage-DockerVersion.ps1 -CustomVersion "1.0.0" -Push

# Dry run (test without making changes)
.\docker\Manage-DockerVersion.ps1 -BumpType minor -Push -DryRun
```

### 3. Deploy Services

```powershell
# Deploy latest version to dev environment
.\docker\Deploy-DockerServices.ps1 -Environment dev -Version latest

# Deploy specific version to production
.\docker\Deploy-DockerServices.ps1 -Environment prod -Version "1.2.3"

# Rollback to previous deployment
.\docker\Deploy-DockerServices.ps1 -Rollback

# Dry run deployment
.\docker\Deploy-DockerServices.ps1 -Environment staging -Version "1.2.3" -DryRun
```

## GitHub Actions CI/CD

The `.github/workflows/docker-build-push.yml` workflow automatically:

1. Builds multi-architecture images (amd64, arm64)
2. Tags with semantic versioning
3. Pushes to GitHub Container Registry
4. Runs security scanning with Trivy

### Triggering Builds

- **Push to main**: Builds and tags as `latest`
- **Push to develop**: Builds and tags as `develop`
- **Create release**: Builds and tags with version number
- **Manual trigger**: Use workflow dispatch with custom version

## Image Naming Convention

All images follow this pattern:
```
ghcr.io/[username]/unity-claude-[service-name]:[tag]
```

### Services

- `powershell-modules`: PowerShell automation modules
- `langgraph-api`: LangGraph REST API service
- `autogen-groupchat`: AutoGen multi-agent orchestration
- `docs-server`: Documentation server (MkDocs/Nginx)
- `file-monitor`: File system monitoring service

### Tagging Strategy

- `latest`: Most recent build from main branch
- `X.Y.Z`: Specific semantic version (e.g., 1.2.3)
- `X.Y`: Minor version (updates with patches)
- `X`: Major version (updates with minor/patches)
- `branch-SHA`: Branch name with commit SHA
- `develop`: Latest from develop branch

## Local Development

### Stop MkDocs to Free Port 8000

The MkDocs dev server conflicts with LangGraph API on port 8000:

```powershell
# Find and stop MkDocs process
Get-Process -Name "python*" | Where-Object {
    $_.CommandLine -like "*mkdocs*serve*"
} | Stop-Process -Force

# Or use the consolidated service manager
.\Start-AllServices.ps1 -StopAll
```

### Service Ports

- **8000**: LangGraph REST API
- **8001**: AutoGen GroupChat API
- **8080**: Documentation server (production)

## Version Management

### Version File

The current version is stored in `.docker-version` file.

### Bumping Versions

```powershell
# Patch version (1.2.3 -> 1.2.4)
.\docker\Manage-DockerVersion.ps1 -BumpType patch

# Minor version (1.2.3 -> 1.3.0)
.\docker\Manage-DockerVersion.ps1 -BumpType minor

# Major version (1.2.3 -> 2.0.0)
.\docker\Manage-DockerVersion.ps1 -BumpType major
```

### Git Tags

When pushing images, the script creates a git tag:

```powershell
# After successful push, the script creates tag v1.2.3
# Push the tag to remote
git push origin v1.2.3
```

## Health Checks

All services implement health check endpoints:

- **LangGraph API**: `GET http://localhost:8000/health`
- **AutoGen GroupChat**: `GET http://localhost:8001/health`
- **Documentation**: `GET http://localhost:8080/health`

The deployment script waits for all health checks to pass before considering deployment successful.

## Rollback Procedure

If deployment fails or issues are detected:

```powershell
# Automatic rollback to last known good deployment
.\docker\Deploy-DockerServices.ps1 -Rollback

# Rollback happens automatically if:
# - Health checks fail
# - Services fail to start
# - Image pull fails
```

Backups are stored in `.\docker\backups\` directory.

## Security Scanning

GitHub Actions automatically runs Trivy security scanning on all images. Results are uploaded to the GitHub Security tab.

To run locally:

```bash
# Install Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ghcr.io/[username]/unity-claude-langgraph-api:latest
```

## Troubleshooting

### Authentication Issues

```powershell
# Verify authentication
docker pull ghcr.io/[username]/unity-claude-langgraph-api:latest

# Re-authenticate
docker logout ghcr.io
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

### Port Conflicts

```powershell
# Check what's using a port
netstat -ano | findstr :8000

# Kill process using port
Stop-Process -Id [PID] -Force
```

### Container Logs

```powershell
# View service logs
docker-compose logs -f langgraph-api

# View all logs
docker-compose logs -f

# View last 100 lines
docker-compose logs --tail=100
```

### Clean Up

```powershell
# Stop all services
docker-compose down

# Remove all containers and volumes
docker-compose down -v

# Remove unused images
docker image prune -a
```

## Best Practices

1. **Always test locally** before pushing to registry
2. **Use semantic versioning** consistently
3. **Tag releases** in git after successful deployment
4. **Monitor health endpoints** after deployment
5. **Keep backups** of previous deployments
6. **Run security scans** regularly
7. **Document breaking changes** in release notes
8. **Use environment-specific** compose files for different stages

## Environment Variables

Set these in your `.env` file:

```env
DOCKER_REGISTRY=ghcr.io
DOCKER_NAMESPACE=your-github-username
DOCKER_TAG=latest
ANTHROPIC_API_KEY=your-key
OPENAI_API_KEY=your-key
```

## Next Steps

1. Set up monitoring and alerting
2. Implement log aggregation
3. Add performance metrics
4. Create staging environment
5. Set up automated testing in CI/CD