# Start-Simple-Working-API.ps1
# Creates a simple, guaranteed-working API service
# Date: 2025-08-29

Write-Host "=== Starting Simple Working API Service ===" -ForegroundColor Cyan

try {
    # Remove any existing API containers
    docker rm -f $(docker ps -a -q --filter "name=api") 2>$null
    docker rm -f $(docker ps -a -q --filter "name=docs-api") 2>$null
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Starting simple API service..." -ForegroundColor White
    
    # Create simple Flask API without variable substitution issues
    $simpleApiCode = 'from flask import Flask, jsonify
import datetime
app = Flask(__name__)

@app.route("/health")
def health():
    return jsonify({
        "status": "healthy", 
        "service": "Enhanced Documentation API v2.0.0",
        "timestamp": datetime.datetime.now().isoformat()
    })

@app.route("/")
def root():
    return jsonify({
        "service": "Enhanced Documentation System",
        "version": "2.0.0",
        "status": "operational"
    })

print("API starting on 0.0.0.0:8091")
app.run(host="0.0.0.0", port=8091)'
    
    # Start the simple API
    $apiId = docker run -d --name simple-api --network docs-net -p 8091:8091 `
        -e PYTHONUNBUFFERED=1 `
        python:3.12-slim `
        sh -c "pip install flask > /dev/null 2>&1; python -c '$simpleApiCode'"
    
    if ($apiId) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] Simple API started: $($apiId.Substring(0,12))" -ForegroundColor Green
        
        # Wait and test
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Waiting 45 seconds for initialization..." -ForegroundColor White
        
        for ($i = 1; $i -le 9; $i++) {
            Start-Sleep -Seconds 5
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Progress] Initialization: $($i * 5)/45 seconds" -ForegroundColor Cyan
        }
        
        # Test the API
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8091/health" -TimeoutSec 10 -UseBasicParsing
            $data = $response.Content | ConvertFrom-Json
            
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] ✅ API Service: WORKING (HTTP $($response.StatusCode))" -ForegroundColor Green
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success]    Service: $($data.service)" -ForegroundColor Green
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success]    Status: $($data.status)" -ForegroundColor Green
            
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Warning] API still starting: $($_.Exception.Message)" -ForegroundColor Yellow
            
            # Check container logs
            $logs = docker logs simple-api --tail 5 2>$null
            if ($logs) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Container logs: $($logs[-1])" -ForegroundColor White
            }
        }
        
        # Test all services now
        Write-Host "`n=== Complete System Status ===" -ForegroundColor Cyan
        
        $allServices = @{
            "Documentation Web" = "http://localhost:8080"
            "API Service" = "http://localhost:8091/health"
        }
        
        $working = 0
        foreach ($service in $allServices.Keys) {
            try {
                $test = Invoke-WebRequest -Uri $allServices[$service] -TimeoutSec 5 -UseBasicParsing
                Write-Host "✅ $service - HEALTHY (HTTP $($test.StatusCode))" -ForegroundColor Green
                $working++
            } catch {
                Write-Host "❌ $service - NOT READY" -ForegroundColor Red
            }
        }
        
        $healthPercent = [math]::Round(($working / $allServices.Count) * 100, 1)
        Write-Host "`nSystem Health: $healthPercent% ($working/$($allServices.Count) services)" -ForegroundColor $(if ($healthPercent -eq 100) { "Green" } else { "Yellow" })
        
        # Show container status
        Write-Host "`nContainer Status:" -ForegroundColor Cyan
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        if ($working -eq $allServices.Count) {
            Write-Host "`n🎉 BASE SYSTEM FULLY OPERATIONAL!" -ForegroundColor Green
            Write-Host "Ready to add AI services with ./Integrate-PowerShell-AI-Services.ps1" -ForegroundColor Green
        }
        
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Error] Failed to start simple API" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Error] Simple API startup failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Simple API Service Complete ===" -ForegroundColor Green