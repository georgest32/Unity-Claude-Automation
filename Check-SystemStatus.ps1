# Check-SystemStatus.ps1
# Comprehensive status check for Enhanced Documentation System v2.0.0
# Date: 2025-08-29

Write-Host "=== Enhanced Documentation System v2.0.0 - Status Check ===" -ForegroundColor Cyan

# Check container status
Write-Host "`n📦 Container Status:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test all service endpoints
Write-Host "`n🌐 Service Health Check:" -ForegroundColor Yellow

$services = @{
    "Documentation Web" = "http://localhost:8080"
    "API Service" = "http://localhost:8091/health"
    "LangGraph AI" = "http://localhost:8000/health"
    "AutoGen GroupChat" = "http://localhost:8001/health"
}

$workingServices = 0

foreach ($serviceName in $services.Keys) {
    $url = $services[$serviceName]
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Host "  ✅ $serviceName - HEALTHY (HTTP $($response.StatusCode))" -ForegroundColor Green
        $workingServices++
    } catch {
        Write-Host "  ❌ $serviceName - NOT ACCESSIBLE" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
    }
}

# Service availability summary
$totalServices = $services.Count
$healthPercent = [math]::Round(($workingServices / $totalServices) * 100, 1)

Write-Host "`n📊 System Health: $healthPercent% ($workingServices/$totalServices services)" -ForegroundColor $(if ($healthPercent -eq 100) { "Green" } elseif ($healthPercent -ge 75) { "Yellow" } else { "Red" })

# Week 4 Features Check
Write-Host "`n🔮 Week 4 Predictive Analysis Features:" -ForegroundColor Yellow

try {
    if (Get-Command Get-GitCommitHistory -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ Code Evolution Analysis - AVAILABLE" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Code Evolution Analysis - NOT LOADED" -ForegroundColor Red
    }
    
    if (Get-Command Get-TechnicalDebt -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ Maintenance Prediction - AVAILABLE" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Maintenance Prediction - NOT LOADED" -ForegroundColor Red
    }
    
    if (Get-Command Get-MaintenancePrediction -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ ML-based Forecasting - AVAILABLE" -ForegroundColor Green
    } else {
        Write-Host "  ❌ ML-based Forecasting - NOT LOADED" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  ⚠️ Week 4 feature check failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# AI Integration Test
Write-Host "`n🤖 AI Integration Status:" -ForegroundColor Yellow

# Test PowerShell container AI bridge
try {
    $psTest = docker exec powershell-service pwsh -c "Get-Command Get-GitCommitHistory -ErrorAction SilentlyContinue | Select-Object Name"
    if ($psTest) {
        Write-Host "  ✅ PowerShell-AI Bridge - OPERATIONAL" -ForegroundColor Green
    } else {
        Write-Host "  ❌ PowerShell-AI Bridge - NOT OPERATIONAL" -ForegroundColor Red
    }
} catch {
    Write-Host "  ⚠️ PowerShell container test failed" -ForegroundColor Yellow
}

# Final Assessment
Write-Host "`n🎯 System Assessment:" -ForegroundColor Cyan

if ($workingServices -eq $totalServices) {
    Write-Host "🎉 ENHANCED DOCUMENTATION SYSTEM v2.0.0 FULLY OPERATIONAL!" -ForegroundColor Green
    Write-Host "   All services healthy and integrated with AI capabilities" -ForegroundColor Green
    Write-Host "`n🚀 Ready for AI-powered documentation and code analysis!" -ForegroundColor Green
} elseif ($workingServices -ge 3) {
    Write-Host "⚡ System mostly operational with $workingServices/$totalServices services working" -ForegroundColor Yellow
    Write-Host "   Core functionality available, some AI services may need more time" -ForegroundColor Yellow
} else {
    Write-Host "⚠️ System needs troubleshooting - only $workingServices/$totalServices services working" -ForegroundColor Red
}

Write-Host "`n=== Status Check Complete ===" -ForegroundColor Cyan