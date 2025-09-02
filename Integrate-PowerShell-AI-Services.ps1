# Integrate-PowerShell-AI-Services.ps1
# Creates PowerShell-AI bridge for Enhanced Documentation System
# Integrates Week 4 predictive features with LangGraph and AutoGen
# Date: 2025-08-29

param(
    [switch]$TestIntegration,
    [switch]$StartAIServices
)

function Write-IntegrateLog {
    param([string]$Message, [string]$Level = "Info")
    $color = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "Debug" = "Cyan" }[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

Write-Host "=== PowerShell-AI Services Integration ===" -ForegroundColor Cyan

if ($StartAIServices) {
    # Start AI services with corrected build process
    Write-IntegrateLog "Starting LangGraph AI service..." -Level "Info"
    
    try {
        # Build and start LangGraph (using project root as build context)
        docker build -f docker/python/langgraph/Dockerfile.fixed -t langgraph-ai:latest .
        
        if ($LASTEXITCODE -eq 0) {
            $langGraphId = docker run -d --name langgraph-ai --network docs-net -p 8000:8000 `
                -e PYTHONUNBUFFERED=1 -e HOST=0.0.0.0 -e PORT=8000 `
                -v "${PWD}/agents:/app/agents:ro" `
                langgraph-ai:latest
            
            Write-IntegrateLog "LangGraph AI started: $($langGraphId.Substring(0,12))" -Level "Success"
        } else {
            Write-IntegrateLog "LangGraph build failed" -Level "Error"
        }
        
        # Build and start AutoGen
        Write-IntegrateLog "Starting AutoGen GroupChat service..." -Level "Info"
        
        docker build -f docker/python/autogen/Dockerfile.fixed -t autogen-groupchat:latest .
        
        if ($LASTEXITCODE -eq 0) {
            $autoGenId = docker run -d --name autogen-groupchat --network docs-net -p 8001:8001 `
                -e PYTHONUNBUFFERED=1 -e AUTOGEN_USE_DOCKER=0 -e HOST=0.0.0.0 -e PORT=8001 `
                -v "${PWD}/agents:/app/agents:ro" `
                autogen-groupchat:latest
            
            Write-IntegrateLog "AutoGen GroupChat started: $($autoGenId.Substring(0,12))" -Level "Success"
        } else {
            Write-IntegrateLog "AutoGen build failed" -Level "Error"
        }
        
    } catch {
        Write-IntegrateLog "AI service startup failed: $($_.Exception.Message)" -Level "Error"
    }
}

if ($TestIntegration) {
    Write-IntegrateLog "Testing PowerShell-AI integration..." -Level "Info"
    
    # Test Week 4 PowerShell modules are available
    Write-IntegrateLog "Testing Week 4 Predictive Analysis modules..." -Level "Info"
    
    try {
        # Test Code Evolution Analysis
        if (Get-Command Get-GitCommitHistory -ErrorAction SilentlyContinue) {
            $commits = Get-GitCommitHistory -MaxCount 5 -Since "1.week.ago"
            Write-IntegrateLog "Code Evolution Analysis: AVAILABLE ($($commits.Count) commits analyzed)" -Level "Success"
        } else {
            Write-IntegrateLog "Code Evolution Analysis: NOT AVAILABLE" -Level "Warning"
        }
        
        # Test Maintenance Prediction
        if (Get-Command Get-TechnicalDebt -ErrorAction SilentlyContinue) {
            $debt = Get-TechnicalDebt -Path ".\Modules" -FilePattern "*.psm1" -OutputFormat "Summary"
            Write-IntegrateLog "Maintenance Prediction: AVAILABLE ($($debt.TotalItems) debt items)" -Level "Success"
        } else {
            Write-IntegrateLog "Maintenance Prediction: NOT AVAILABLE" -Level "Warning"
        }
        
        # Test AI service endpoints
        $aiEndpoints = @{
            "LangGraph AI" = "http://localhost:8000/health"
            "AutoGen GroupChat" = "http://localhost:8001/health"
        }
        
        foreach ($aiService in $aiEndpoints.Keys) {
            try {
                $response = Invoke-WebRequest -Uri $aiEndpoints[$aiService] -TimeoutSec 5 -UseBasicParsing
                Write-IntegrateLog "$aiService - ACCESSIBLE (HTTP $($response.StatusCode))" -Level "Success"
            } catch {
                Write-IntegrateLog "$aiService - NOT ACCESSIBLE ($($_.Exception.Message))" -Level "Warning"
            }
        }
        
        # Test PowerShell container AI integration
        Write-IntegrateLog "Testing PowerShell container AI integration..." -Level "Info"
        
        try {
            $psExecResult = docker exec powershell-service pwsh -c "Import-Module /opt/modules/Unity-Claude-CPG/Core/Predictive-Evolution.psm1 -ErrorAction SilentlyContinue; Get-Command Get-GitCommitHistory -ErrorAction SilentlyContinue | Select-Object Name, ModuleName"
            
            if ($psExecResult) {
                Write-IntegrateLog "PowerShell-AI integration: WORKING" -Level "Success"
                Write-IntegrateLog "Available commands in container: $($psExecResult)" -Level "Debug"
            } else {
                Write-IntegrateLog "PowerShell-AI integration: LIMITED" -Level "Warning"
            }
        } catch {
            Write-IntegrateLog "PowerShell container test failed: $($_.Exception.Message)" -Level "Warning"
        }
        
    } catch {
        Write-IntegrateLog "Integration testing failed: $($_.Exception.Message)" -Level "Error"
    }
}

# Default: Start and test everything
if (-not $StartAIServices -and -not $TestIntegration) {
    Write-IntegrateLog "Starting complete AI service integration..." -Level "Info"
    
    # Start AI services
    & $PSCommandPath -StartAIServices
    
    # Wait for initialization
    Write-IntegrateLog "Waiting 3 minutes for AI services to initialize..." -Level "Info"
    Start-Sleep -Seconds 180
    
    # Test integration
    Write-IntegrateLog "Testing complete integration..." -Level "Info"
    & $PSCommandPath -TestIntegration
    
    # Final status
    Write-IntegrateLog "Complete Enhanced Documentation System Status:" -Level "Info"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    Write-IntegrateLog "Enhanced Documentation System v2.0.0 with AI Services:" -Level "Success"
    Write-IntegrateLog "  Documentation: http://localhost:8080" -Level "Success"
    Write-IntegrateLog "  API: http://localhost:8091" -Level "Success"
    Write-IntegrateLog "  LangGraph AI: http://localhost:8000" -Level "Success"
    Write-IntegrateLog "  AutoGen GroupChat: http://localhost:8001" -Level "Success"
    Write-IntegrateLog "  PowerShell + Week 4 Features: Available in container" -Level "Success"
}

Write-Host "`n=== PowerShell-AI Integration Complete ===" -ForegroundColor Green