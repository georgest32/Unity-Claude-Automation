# Docker and Containerization Learnings

*Docker containerization, registry management, and production deployment insights*

## Phase 6: Docker Containerization (2025-08-24)

### PowerShell in Docker
- **Critical**: Use mcr.microsoft.com/dotnet/sdk:9.0 as base image (includes pwsh)
- Standalone PowerShell images deprecated, now integrated with .NET SDK
- Windows Server Core needed for full PowerShell functionality (Nanoserver lacks WMI/PowerShell)
- Module installation requires ContainerAdministrator user for AllUsers scope
- Set PSModulePath environment variable for module discovery

### Multi-Stage Build Best Practices
- **Essential**: Separate build and runtime stages to minimize image size
- Build stage: Install tools, compile, run tests
- Runtime stage: Copy only necessary artifacts from build stage
- Python: Use python:3.12 for build, python:3.12-slim for runtime
- UV package manager 10x faster than pip/Poetry for Python dependencies

### Docker Compose Orchestration
- **2025 Update**: Native support for AI agents in Docker Compose
- Custom networks essential (avoid default bridge)
- Named volumes for shared data between containers
- Health checks critical for production monitoring
- Service dependencies managed with depends_on

### Security in Containers
- **Never use ENV/ARG for secrets**: They persist in final image
- Use Docker secrets: Encrypted at rest and in transit
- Mount secrets at /run/secrets/<secret_name>
- Run containers as non-root users
- Implement read-only filesystems where possible

### Windows/WSL2 Considerations
- WSL2 provides better Linux container performance on Windows
- Cannot run Linux and Windows containers simultaneously (switching required)
- Docker Desktop manages its own virtual disk (v4.30+)
- Process isolation improved in Windows Server 2025

### Container Registry and Versioning
- Semantic versioning (major.minor.patch) for tags
- Never deploy with :latest tag in production
- Tag immutability critical - never overwrite same version
- CI/CD should be authority on version incrementing
- Multiple tags per build (1.0.0, 1.0, 1, latest)

## Container Registry and Production Deployment

### Learning #221: Container Registry and Production Deployment (2025-08-24)
**Context**: Phase 6 Day 1-2 Hours 5-8: Container Registry Setup - Complete production deployment infrastructure
**Critical Discovery**: GitHub Container Registry (ghcr.io) + semantic versioning + automated rollback = reliable production deployments
**Major Implementation Achievements**:
1. **GitHub Container Registry Integration**: Free for public images, integrated permissions, anonymous pulls supported
2. **Semantic Versioning Automation**: Manage-DockerVersion.ps1 handles major.minor.patch with git tag integration
3. **Multi-Architecture Builds**: GitHub Actions workflow supports linux/amd64 and linux/arm64 via Docker Buildx
4. **Automated Deployment & Rollback**: Deploy-DockerServices.ps1 with health checks and automatic rollback on failure
5. **Port Conflict Resolution**: MkDocs dev server (8000) vs LangGraph API resolved - use Docker/Nginx (8080) for docs
6. **Security Scanning**: Trivy integration in CI/CD pipeline for vulnerability detection
**Critical Technical Insights**:
- **Registry Authentication**: Use PAT with 'write:packages' scope for local dev, GITHUB_TOKEN in Actions
- **Health Check Dependencies**: Use depends_on with service_healthy condition for proper startup sequencing
- **Image Tagging Strategy**: semantic-version + commit-sha + branch for traceability
- **Multi-arch Considerations**: Use docker buildx for cross-platform compatibility
- **Resource Optimization**: Alpine-based images reduce size by 70%, multi-stage builds eliminate dev dependencies
- **Security Best Practices**: Non-root users, distroless final images, vulnerability scanning, secret management
**Performance Metrics**:
- Build time: 2-4 minutes for multi-architecture builds
- Image sizes: <100MB for production images (Alpine + multi-stage)
- Registry push: 30-60 seconds for typical images
- Health check response: <2 seconds for ready status
**Production Deployment Process**:
1. Automated semantic version increment based on commit messages
2. Multi-architecture build with Docker Buildx
3. Security scanning with Trivy (fail on HIGH/CRITICAL)
4. Push to GitHub Container Registry with multiple tags
5. Deploy to staging with health checks
6. Automated rollback if health checks fail within 5 minutes
7. Manual promotion to production with approval gate

## Monitoring Stack Implementation

### Learning #223: Monitoring & Logging Stack Implementation (2025-08-24)
**Context**: Phase 6 Day 3-4 Hours 5-8: Monitoring & Logging - Complete observability stack with Prometheus, Grafana, Loki, and Alertmanager
**Critical Discovery**: OpenTelemetry convergence + LGTM stack + unified health checks = production-ready observability
**Major Implementation Achievements**:
1. **Centralized Logging**: Loki + Fluent Bit for log aggregation with 7-day retention policy
2. **Performance Monitoring**: Prometheus + Grafana with cAdvisor and Node Exporter for comprehensive metrics
3. **Enhanced Health Checks**: Python FastAPI server with liveness/readiness/startup probes following 2025 best practices
4. **Alerting System**: Alertmanager with multi-channel routing (Slack, PagerDuty, email) and severity-based escalation
5. **PowerShell Integration**: Unity-Claude-Monitoring module for native PowerShell monitoring capabilities
6. **Docker Compose Stack**: Complete monitoring infrastructure in docker-compose.monitoring.yml
**Critical Technical Insights**:
- **OpenTelemetry Trend**: 2025 shows convergence towards vendor-neutral OpenTelemetry standard
- **Grafana Alloy**: Replaces multiple agents (Promtail, Node Exporter) with unified telemetry pipeline
- **Health Check Best Practices**: Keep probes lightweight, separate liveness/readiness concerns, use startup probes for slow apps
- **Windows Container Logging**: Requires LogMonitor tool for STDOUT pipeline creation
- **Alert Routing**: Multi-channel redundancy essential - use email/Pub/Sub as backup for critical alerts
- **Metric Scraping**: 15-second intervals standard, adaptive step sizing for range queries
**Performance Specifications**:
- Small deployment: 2-4 CPU cores, 4-8GB RAM for monitoring stack
- Log retention: 7 days default (configurable)
- Metric retention: 30 days in Prometheus TSDB
- Cache TTL: 30 seconds for health checks to reduce load
**Security Implementation**:
- TLS 1.2 minimum for all communications
- RBAC with Admin/Editor/Viewer roles in Grafana
- Audit logging for all operations
- No anonymous access by default