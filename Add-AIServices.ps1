# Add-AIServices.ps1
# Adds LangGraph and AutoGen AI services to the working Enhanced Documentation System
# Integrates with PowerShell container for complete AI functionality
# Date: 2025-08-29

param(
    [switch]$BuildFromFixed,
    [switch]$Verbose
)

function Write-AILog {
    param([string]$Message, [string]$Level = "Info")
    $color = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "Debug" = "Cyan" }[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

Write-Host "=== Adding AI Services to Enhanced Documentation System ===" -ForegroundColor Cyan

try {
    # Step 1: Build LangGraph service with fixed Dockerfile
    Write-AILog "Step 1: Building LangGraph AI service" -Level "Info"
    
    if ($BuildFromFixed) {
        # Use fixed Dockerfile with proper build context
        Write-AILog "Building LangGraph from fixed Dockerfile (context: project root)" -Level "Info"
        $buildOutput = docker build -f docker/python/langgraph/Dockerfile.fixed -t langgraph-ai:latest . 2>&1
    } else {
        # Build using original approach but with root context
        Write-AILog "Building LangGraph from original Dockerfile (context: project root)" -Level "Info"  
        $buildOutput = docker build -f docker/python/langgraph/Dockerfile -t langgraph-ai:latest . 2>&1
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-AILog "LangGraph AI service built successfully" -Level "Success"
    } else {
        Write-AILog "LangGraph build failed: $($buildOutput[-3..-1] -join '; ')" -Level "Error"
        throw "LangGraph build failed"
    }
    
    # Step 2: Build AutoGen service
    Write-AILog "Step 2: Building AutoGen GroupChat service" -Level "Info"
    
    if ($BuildFromFixed) {
        $buildOutput = docker build -f docker/python/autogen/Dockerfile.fixed -t autogen-groupchat:latest . 2>&1
    } else {
        $buildOutput = docker build -f docker/python/autogen/Dockerfile -t autogen-groupchat:latest . 2>&1
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-AILog "AutoGen GroupChat service built successfully" -Level "Success"
    } else {
        Write-AILog "AutoGen build failed: $($buildOutput[-3..-1] -join '; ')" -Level "Error"
        throw "AutoGen build failed"
    }
    
    # Step 3: Add LangGraph to running system
    Write-AILog "Step 3: Starting LangGraph AI service" -Level "Info"
    
    $langGraphCmd = docker run -d --name langgraph-ai --network docs-net -p 8000:8000 `
        -e PYTHONUNBUFFERED=1 `
        -e HOST=0.0.0.0 `
        -e PORT=8000 `
        -v "${PWD}/agents:/app/agents:ro" `
        langgraph-ai:latest
    
    if ($langGraphCmd) {
        Write-AILog "LangGraph AI service started: $($langGraphCmd.Substring(0,12))" -Level "Success"
    } else {
        Write-AILog "LangGraph service failed to start" -Level "Error"
    }
    
    # Step 4: Add AutoGen to running system  
    Write-AILog "Step 4: Starting AutoGen GroupChat service" -Level "Info"
    
    $autoGenCmd = docker run -d --name autogen-groupchat --network docs-net -p 8001:8001 `
        -e PYTHONUNBUFFERED=1 `
        -e AUTOGEN_USE_DOCKER=0 `
        -e HOST=0.0.0.0 `
        -e PORT=8001 `
        -v "${PWD}/agents:/app/agents:ro" `
        autogen-groupchat:latest
    
    if ($autoGenCmd) {
        Write-AILog "AutoGen GroupChat service started: $($autoGenCmd.Substring(0,12))" -Level "Success"
    } else {
        Write-AILog "AutoGen service failed to start" -Level "Error"
    }
    
    # Step 5: Wait for AI service initialization
    Write-AILog "Step 5: Waiting for AI services to initialize (3 minutes)" -Level "Info"
    
    for ($i = 1; $i -le 18; $i++) {
        Start-Sleep -Seconds 10
        Write-AILog "AI initialization progress: $($i * 10)/180 seconds" -Level "Debug"
    }
    
    # Step 6: Test AI service integration
    Write-AILog "Step 6: Testing AI service integration" -Level "Info"
    
    $aiServices = @{
        "LangGraph AI" = "http://localhost:8000/health"
        "AutoGen GroupChat" = "http://localhost:8001/health"
    }
    
    $workingAI = 0
    
    foreach ($serviceName in $aiServices.Keys) {
        $serviceUrl = $aiServices[$serviceName]
        
        try {
            $response = Invoke-WebRequest -Uri $serviceUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            Write-AILog "$serviceName - HEALTHY (HTTP $($response.StatusCode))" -Level "Success"
            $workingAI++
        } catch {
            Write-AILog "$serviceName - NOT READY ($($_.Exception.Message))" -Level "Warning"
            
            # Check container logs for debugging
            $containerName = ($serviceName.ToLower() -replace '\s+', '-')
            if ($serviceName -eq "LangGraph AI") { $containerName = "langgraph-ai" }
            if ($serviceName -eq "AutoGen GroupChat") { $containerName = "autogen-groupchat" }
            
            try {
                $logs = docker logs $containerName --tail 3 2>$null
                if ($logs) {
                    Write-AILog "Recent logs: $($logs[-1])" -Level "Debug"
                }
            } catch {
                Write-AILog "Could not retrieve logs for $containerName" -Level "Debug"
            }
        }
    }
    
    # Step 7: Complete system status
    Write-AILog "Step 7: Complete Enhanced Documentation System status" -Level "Info"
    
    # Check all services
    Write-AILog "All running containers:" -Level "Info"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Final integration status
    $totalServices = 5  # docs-web, powershell-service, api-service, langgraph-ai, autogen-groupchat
    $runningContainers = (docker ps --format "{{.Names}}").Count
    
    Write-AILog "Container Status: $runningContainers containers running" -Level "Info"
    Write-AILog "AI Services: $workingAI/2 AI services responding" -Level "Info"
    
    if ($workingAI -eq 2) {
        Write-AILog "ENHANCED DOCUMENTATION SYSTEM WITH AI FULLY OPERATIONAL!" -Level "Success"
        Write-AILog "Documentation: http://localhost:8080" -Level "Success"
        Write-AILog "API: http://localhost:8091" -Level "Success"
        Write-AILog "LangGraph AI: http://localhost:8000" -Level "Success"
        Write-AILog "AutoGen GroupChat: http://localhost:8001" -Level "Success"
        Write-AILog "PowerShell + AI Integration: Complete" -Level "Success"
    } else {
        Write-AILog "AI services need additional time to initialize" -Level "Warning"
        Write-AILog "Infrastructure ready - AI services starting up" -Level "Info"
    }
    
} catch {
    Write-AILog "AI service integration failed: $($_.Exception.Message)" -Level "Error"
    exit 1
}

Write-Host "`n=== AI Services Integration Complete ===" -ForegroundColor Green