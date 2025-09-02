#!/usr/bin/env python3
"""
Enhanced Health Check Server for Unity-Claude Automation
Provides comprehensive health checks for all services
Version: 2025-08-24
"""

import asyncio
import json
import time
from datetime import datetime
from typing import Dict, Any, List, Optional
from enum import Enum

import httpx
from fastapi import FastAPI, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field


class HealthStatus(str, Enum):
    """Health status enumeration"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"


class ServiceHealth(BaseModel):
    """Service health model"""
    name: str
    status: HealthStatus
    latency_ms: float
    last_check: datetime
    error: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class DependencyHealth(BaseModel):
    """Dependency health model"""
    name: str
    type: str  # database, api, queue, etc.
    status: HealthStatus
    latency_ms: float
    error: Optional[str] = None


class SystemHealth(BaseModel):
    """System-wide health model"""
    status: HealthStatus
    timestamp: datetime
    uptime_seconds: float
    version: str = "1.0.0"
    services: List[ServiceHealth]
    dependencies: List[DependencyHealth]
    metrics: Dict[str, Any]


# FastAPI app initialization
app = FastAPI(
    title="Unity-Claude Health Check Service",
    version="1.0.0",
    description="Comprehensive health monitoring for Unity-Claude Automation"
)

# Global state
start_time = time.time()
health_cache: Dict[str, Any] = {}
cache_ttl = 30  # seconds


# Service configurations
SERVICES = {
    "langgraph-api": {
        "url": "http://langgraph-api:8000/health",
        "timeout": 5,
        "critical": True
    },
    "autogen-groupchat": {
        "url": "http://autogen-groupchat:8001/health",
        "timeout": 5,
        "critical": True
    },
    "powershell-modules": {
        "url": "http://powershell-modules:5985/health",
        "timeout": 10,
        "critical": False
    },
    "grafana": {
        "url": "http://grafana:3000/api/health",
        "timeout": 5,
        "critical": False
    },
    "prometheus": {
        "url": "http://prometheus:9090/-/ready",
        "timeout": 5,
        "critical": True
    },
    "loki": {
        "url": "http://loki:3100/ready",
        "timeout": 5,
        "critical": False
    },
    "alertmanager": {
        "url": "http://alertmanager:9093/-/healthy",
        "timeout": 5,
        "critical": False
    }
}


# Dependencies configurations
DEPENDENCIES = {
    "docker": {
        "type": "container_runtime",
        "check": lambda: check_docker_health()
    },
    "filesystem": {
        "type": "storage",
        "check": lambda: check_filesystem_health()
    },
    "network": {
        "type": "network",
        "check": lambda: check_network_health()
    }
}


async def check_service_health(name: str, config: Dict[str, Any]) -> ServiceHealth:
    """Check individual service health"""
    start = time.time()
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                config["url"],
                timeout=config["timeout"]
            )
            
            latency_ms = (time.time() - start) * 1000
            
            if response.status_code == 200:
                return ServiceHealth(
                    name=name,
                    status=HealthStatus.HEALTHY,
                    latency_ms=latency_ms,
                    last_check=datetime.utcnow(),
                    metadata={"status_code": response.status_code}
                )
            elif 200 < response.status_code < 300:
                return ServiceHealth(
                    name=name,
                    status=HealthStatus.DEGRADED,
                    latency_ms=latency_ms,
                    last_check=datetime.utcnow(),
                    error=f"Status code: {response.status_code}",
                    metadata={"status_code": response.status_code}
                )
            else:
                return ServiceHealth(
                    name=name,
                    status=HealthStatus.UNHEALTHY,
                    latency_ms=latency_ms,
                    last_check=datetime.utcnow(),
                    error=f"Status code: {response.status_code}",
                    metadata={"status_code": response.status_code}
                )
                
    except httpx.TimeoutException:
        return ServiceHealth(
            name=name,
            status=HealthStatus.UNHEALTHY,
            latency_ms=config["timeout"] * 1000,
            last_check=datetime.utcnow(),
            error="Timeout"
        )
    except Exception as e:
        return ServiceHealth(
            name=name,
            status=HealthStatus.UNHEALTHY,
            latency_ms=(time.time() - start) * 1000,
            last_check=datetime.utcnow(),
            error=str(e)
        )


async def check_docker_health() -> DependencyHealth:
    """Check Docker daemon health"""
    start = time.time()
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "http://unix:/var/run/docker.sock/version",
                timeout=5
            )
            latency_ms = (time.time() - start) * 1000
            
            if response.status_code == 200:
                return DependencyHealth(
                    name="docker",
                    type="container_runtime",
                    status=HealthStatus.HEALTHY,
                    latency_ms=latency_ms
                )
    except:
        pass
    
    return DependencyHealth(
        name="docker",
        type="container_runtime",
        status=HealthStatus.UNHEALTHY,
        latency_ms=(time.time() - start) * 1000,
        error="Docker daemon not accessible"
    )


async def check_filesystem_health() -> DependencyHealth:
    """Check filesystem health"""
    start = time.time()
    try:
        import shutil
        usage = shutil.disk_usage("/")
        percent_used = (usage.used / usage.total) * 100
        
        latency_ms = (time.time() - start) * 1000
        
        if percent_used < 80:
            status = HealthStatus.HEALTHY
        elif percent_used < 90:
            status = HealthStatus.DEGRADED
        else:
            status = HealthStatus.UNHEALTHY
            
        return DependencyHealth(
            name="filesystem",
            type="storage",
            status=status,
            latency_ms=latency_ms,
            error=None if status == HealthStatus.HEALTHY else f"Disk usage: {percent_used:.1f}%"
        )
    except Exception as e:
        return DependencyHealth(
            name="filesystem",
            type="storage",
            status=HealthStatus.UNHEALTHY,
            latency_ms=(time.time() - start) * 1000,
            error=str(e)
        )


async def check_network_health() -> DependencyHealth:
    """Check network connectivity"""
    start = time.time()
    try:
        async with httpx.AsyncClient() as client:
            # Check internal network
            response = await client.get("http://prometheus:9090/-/ready", timeout=2)
            latency_ms = (time.time() - start) * 1000
            
            if response.status_code == 200:
                return DependencyHealth(
                    name="network",
                    type="network",
                    status=HealthStatus.HEALTHY,
                    latency_ms=latency_ms
                )
    except:
        pass
    
    return DependencyHealth(
        name="network",
        type="network",
        status=HealthStatus.UNHEALTHY,
        latency_ms=(time.time() - start) * 1000,
        error="Internal network connectivity issues"
    )


async def get_system_health() -> SystemHealth:
    """Get comprehensive system health"""
    # Check cache
    cache_key = "system_health"
    if cache_key in health_cache:
        cached_data, cached_time = health_cache[cache_key]
        if time.time() - cached_time < cache_ttl:
            return cached_data
    
    # Check all services
    service_checks = []
    for name, config in SERVICES.items():
        service_checks.append(check_service_health(name, config))
    
    services = await asyncio.gather(*service_checks)
    
    # Check dependencies
    dep_checks = []
    for name, config in DEPENDENCIES.items():
        dep_checks.append(config["check"]())
    
    dependencies = await asyncio.gather(*dep_checks)
    
    # Determine overall status
    critical_services = [s for s in services if SERVICES[s.name].get("critical", False)]
    if any(s.status == HealthStatus.UNHEALTHY for s in critical_services):
        overall_status = HealthStatus.UNHEALTHY
    elif any(s.status == HealthStatus.DEGRADED for s in services):
        overall_status = HealthStatus.DEGRADED
    else:
        overall_status = HealthStatus.HEALTHY
    
    # Collect metrics
    metrics = {
        "services_healthy": len([s for s in services if s.status == HealthStatus.HEALTHY]),
        "services_degraded": len([s for s in services if s.status == HealthStatus.DEGRADED]),
        "services_unhealthy": len([s for s in services if s.status == HealthStatus.UNHEALTHY]),
        "average_latency_ms": sum(s.latency_ms for s in services) / len(services) if services else 0
    }
    
    system_health = SystemHealth(
        status=overall_status,
        timestamp=datetime.utcnow(),
        uptime_seconds=time.time() - start_time,
        services=services,
        dependencies=dependencies,
        metrics=metrics
    )
    
    # Update cache
    health_cache[cache_key] = (system_health, time.time())
    
    return system_health


# Health check endpoints
@app.get("/health")
async def health():
    """Basic health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.utcnow()}


@app.get("/health/live")
async def liveness():
    """Liveness probe - checks if service is running"""
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "status": "alive",
            "timestamp": datetime.utcnow().isoformat(),
            "uptime_seconds": time.time() - start_time
        }
    )


@app.get("/health/ready")
async def readiness(response: Response):
    """Readiness probe - checks if service is ready to handle requests"""
    system_health = await get_system_health()
    
    # For readiness, we are more lenient - allow degraded services
    # Only return 503 if critical services are completely down
    critical_services_unhealthy = any(
        s.status == HealthStatus.UNHEALTHY 
        for s in system_health.services 
        if SERVICES[s.name].get("critical", False)
    )
    
    if critical_services_unhealthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    else:
        response.status_code = status.HTTP_200_OK
    
    return {
        "status": "ready" if not critical_services_unhealthy else "not_ready",
        "system_status": system_health.status,
        "timestamp": system_health.timestamp.isoformat(),
        "critical_services": [
            {"name": s.name, "status": s.status}
            for s in system_health.services
            if SERVICES[s.name].get("critical", False)
        ]
    }


@app.get("/health/startup")
async def startup():
    """Startup probe - checks if service has started successfully"""
    if time.time() - start_time < 10:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "starting", "message": "Service is starting up"}
        )
    return {"status": "started", "timestamp": datetime.utcnow()}


@app.get("/health/detailed", response_model=SystemHealth)
async def detailed_health():
    """Detailed health check with all service statuses"""
    return await get_system_health()


@app.get("/metrics")
async def metrics():
    """Prometheus-compatible metrics endpoint"""
    system_health = await get_system_health()
    
    # Format metrics in Prometheus exposition format
    lines = [
        "# HELP unity_claude_health_status Overall system health (1=healthy, 0.5=degraded, 0=unhealthy)",
        "# TYPE unity_claude_health_status gauge",
        f"unity_claude_health_status {1 if system_health.status == HealthStatus.HEALTHY else 0.5 if system_health.status == HealthStatus.DEGRADED else 0}",
        "",
        "# HELP unity_claude_uptime_seconds Service uptime in seconds",
        "# TYPE unity_claude_uptime_seconds counter",
        f"unity_claude_uptime_seconds {system_health.uptime_seconds}",
        "",
        "# HELP unity_claude_service_health Service health status by name",
        "# TYPE unity_claude_service_health gauge"
    ]
    
    for service in system_health.services:
        value = 1 if service.status == HealthStatus.HEALTHY else 0.5 if service.status == HealthStatus.DEGRADED else 0
        lines.append(f'unity_claude_service_health{{service="{service.name}"}} {value}')
    
    lines.extend([
        "",
        "# HELP unity_claude_service_latency_ms Service response latency in milliseconds",
        "# TYPE unity_claude_service_latency_ms gauge"
    ])
    
    for service in system_health.services:
        lines.append(f'unity_claude_service_latency_ms{{service="{service.name}"}} {service.latency_ms}')
    
    return Response(content="\n".join(lines), media_type="text/plain")


@app.post("/webhook/alerts")
async def webhook_alerts(alert_payload: dict):
    """Webhook endpoint for receiving Alertmanager alerts"""
    print(f"Received alert webhook: {json.dumps(alert_payload, indent=2)}")
    return {"status": "received", "timestamp": datetime.utcnow()}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=9999)