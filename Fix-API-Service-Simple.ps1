# Fix-API-Service-Simple.ps1
# Simple direct fix for API service - no loops, no conflicts
# Date: 2025-08-29

Write-Host "=== Simple API Service Fix ===" -ForegroundColor Cyan

# Step 1: Remove ALL existing API containers
Write-Host "Removing all API-related containers..." -ForegroundColor Yellow
docker rm -f api-service 2>$null
docker rm -f api-service-fixed 2>$null

# Step 2: Create API service with unique name
Write-Host "Creating API service with unique name..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "HHmmss"
$apiName = "docs-api-$timestamp"

$apiCmd = docker run -d --name $apiName --network docs-net -p 8091:8091 `
    -e PYTHONUNBUFFERED=1 `
    python:3.12-slim `
    sh -c 'pip install --no-cache-dir flask && python -c "
from flask import Flask, jsonify
app = Flask(__name__)

@app.route(\"/health\")
def health():
    return jsonify({\"status\": \"healthy\", \"service\": \"Enhanced Documentation API v2.0.0\"})

@app.route(\"/\")
def index():
    return jsonify({\"service\": \"Enhanced Documentation System\", \"version\": \"2.0.0\", \"status\": \"operational\"})

print(\"API starting on 0.0.0.0:8091\")
app.run(host=\"0.0.0.0\", port=8091)
"'

if ($apiCmd) {
    Write-Host "API service started: $apiName ($($apiCmd.Substring(0,12)))" -ForegroundColor Green
    
    # Wait and test
    Write-Host "Waiting 45 seconds for API initialization..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8091/health" -TimeoutSec 10 -UseBasicParsing
        Write-Host "✅ API Service: WORKING (HTTP $($response.StatusCode))" -ForegroundColor Green
        
        # Test the endpoint content
        $content = $response.Content | ConvertFrom-Json
        Write-Host "   Service: $($content.service)" -ForegroundColor Cyan
        Write-Host "   Status: $($content.status)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "❌ API Service: Still initializing - $($_.Exception.Message)" -ForegroundColor Red
        
        # Check container logs
        $logs = docker logs $apiName --tail 5 2>$null
        if ($logs) {
            Write-Host "Recent logs: $($logs[-1])" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "❌ Failed to start API service" -ForegroundColor Red
}

# Final status check
Write-Host "`nFinal system status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n=== API Service Fix Complete ===" -ForegroundColor Green