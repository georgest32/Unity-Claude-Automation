# Validate-Complete-System.ps1
# Comprehensive validation of Enhanced Documentation System v2.0.0
# Definitive confirmation that everything is working
# Date: 2025-08-29

Write-Host "=== COMPREHENSIVE SYSTEM VALIDATION ===" -ForegroundColor Cyan
Write-Host "Enhanced Documentation System v2.0.0 - Complete Verification" -ForegroundColor Yellow

function Write-ValidateLog {
    param([string]$Message, [string]$Level = "Info")
    $color = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "Test" = "Cyan" }[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

$validationResults = @{
    ContainerStatus = @{}
    ServiceEndpoints = @{}
    Week4Features = @{}
    AIIntegration = @{}
    FunctionalTests = @{}
}

try {
    # VALIDATION 1: Container Status
    Write-ValidateLog "VALIDATION 1: Container Infrastructure Status" -Level "Test"
    
    $containers = docker ps --format "{{.Names}},{{.Status}},{{.Ports}}"
    $expectedContainers = @("docs-web", "powershell-service", "langgraph-ai", "autogen-groupchat")
    $apiContainer = $containers | Where-Object { $_ -match "api" }
    
    foreach ($container in $expectedContainers) {
        $found = $containers | Where-Object { $_ -match $container }
        if ($found) {
            $validationResults.ContainerStatus[$container] = "Running"
            Write-ValidateLog "  ✅ $container - RUNNING" -Level "Success"
        } else {
            $validationResults.ContainerStatus[$container] = "Missing"
            Write-ValidateLog "  ❌ $container - MISSING" -Level "Error"
        }
    }
    
    # Check API container (may have timestamp in name)
    if ($apiContainer) {
        $validationResults.ContainerStatus["api-service"] = "Running" 
        Write-ValidateLog "  ✅ API service - RUNNING ($($apiContainer.Split(',')[0]))" -Level "Success"
    } else {
        $validationResults.ContainerStatus["api-service"] = "Missing"
        Write-ValidateLog "  ❌ API service - MISSING" -Level "Error"
    }
    
    # VALIDATION 2: Service Endpoint Functionality
    Write-ValidateLog "VALIDATION 2: Service Endpoint Functionality" -Level "Test"
    
    $endpoints = @{
        "Documentation Web" = "http://localhost:8080"
        "API Health" = "http://localhost:8091/health"
        "API Root" = "http://localhost:8091/"
        "LangGraph Health" = "http://localhost:8000/health"
        "AutoGen Health" = "http://localhost:8001/health"
    }
    
    foreach ($endpointName in $endpoints.Keys) {
        $url = $endpoints[$endpointName]
        
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
            $validationResults.ServiceEndpoints[$endpointName] = "Working"
            Write-ValidateLog "  ✅ $endpointName - WORKING (HTTP $($response.StatusCode))" -Level "Success"
            
            # Test response content for APIs
            if ($endpointName -match "Health" -or $endpointName -match "Root") {
                try {
                    $content = $response.Content | ConvertFrom-Json
                    if ($content.status -or $content.service) {
                        Write-ValidateLog "    Response: $($content.service -or $content.status)" -Level "Success"
                    }
                } catch {
                    Write-ValidateLog "    Response: JSON content received" -Level "Success"
                }
            }
            
        } catch {
            $validationResults.ServiceEndpoints[$endpointName] = "Failed"
            Write-ValidateLog "  ❌ $endpointName - FAILED ($($_.Exception.Message))" -Level "Error"
        }
    }
    
    # VALIDATION 3: Week 4 Features in Local PowerShell
    Write-ValidateLog "VALIDATION 3: Week 4 Features in Local PowerShell Session" -Level "Test"
    
    $week4Functions = @("Get-GitCommitHistory", "Get-TechnicalDebt", "Get-MaintenancePrediction", "Get-CodeChurnMetrics")
    
    foreach ($func in $week4Functions) {
        $command = Get-Command $func -ErrorAction SilentlyContinue
        if ($command) {
            $validationResults.Week4Features[$func] = "Available"
            Write-ValidateLog "  ✅ $func - AVAILABLE (Module: $($command.ModuleName))" -Level "Success"
        } else {
            $validationResults.Week4Features[$func] = "Missing"
            Write-ValidateLog "  ❌ $func - NOT AVAILABLE" -Level "Error"
        }
    }
    
    # VALIDATION 4: PowerShell Container AI Integration
    Write-ValidateLog "VALIDATION 4: PowerShell Container AI Integration" -Level "Test"
    
    # Test container module access
    $containerModuleTest = docker exec powershell-service pwsh -c "Get-ChildItem /opt/modules -Recurse -Filter 'Predictive-*.psm1' | Measure-Object | Select-Object -ExpandProperty Count"
    
    if ($containerModuleTest -eq "2") {
        $validationResults.AIIntegration["ContainerModules"] = "Available"
        Write-ValidateLog "  ✅ Container Modules - 2 Week 4 modules found" -Level "Success"
    } else {
        $validationResults.AIIntegration["ContainerModules"] = "Limited"
        Write-ValidateLog "  ⚠️ Container Modules - $containerModuleTest modules found" -Level "Warning"
    }
    
    # Test AI service connectivity from container
    $containerAITest = docker exec powershell-service pwsh -c "try { (Invoke-WebRequest 'http://langgraph-ai:8000/health' -TimeoutSec 3).StatusCode } catch { 'FAILED' }"
    
    if ($containerAITest -eq "200") {
        $validationResults.AIIntegration["AIConnectivity"] = "Working"
        Write-ValidateLog "  ✅ AI Connectivity - LangGraph accessible from container" -Level "Success"
    } else {
        $validationResults.AIIntegration["AIConnectivity"] = "Failed"
        Write-ValidateLog "  ❌ AI Connectivity - Failed from container" -Level "Error"
    }
    
    # VALIDATION 5: Functional Tests
    Write-ValidateLog "VALIDATION 5: End-to-End Functional Tests" -Level "Test"
    
    # Test Week 4 function execution locally
    if (Get-Command Get-GitCommitHistory -ErrorAction SilentlyContinue) {
        try {
            $commits = Get-GitCommitHistory -MaxCount 3 -Since "1.week.ago"
            $validationResults.FunctionalTests["CodeEvolution"] = "Working"
            Write-ValidateLog "  ✅ Code Evolution Analysis - $($commits.Count) commits analyzed" -Level "Success"
        } catch {
            $validationResults.FunctionalTests["CodeEvolution"] = "Failed"
            Write-ValidateLog "  ❌ Code Evolution Analysis - Failed: $($_.Exception.Message)" -Level "Error"
        }
    }
    
    # Test API endpoints with actual data
    try {
        $apiResponse = Invoke-WebRequest -Uri "http://localhost:8091/" -TimeoutSec 10 -UseBasicParsing
        $apiData = $apiResponse.Content | ConvertFrom-Json
        
        if ($apiData.version -eq "2.0.0") {
            $validationResults.FunctionalTests["APIFunctionality"] = "Working"
            Write-ValidateLog "  ✅ API Functionality - Version $($apiData.version) confirmed" -Level "Success"
        } else {
            $validationResults.FunctionalTests["APIFunctionality"] = "Partial"
            Write-ValidateLog "  ⚠️ API Functionality - Unexpected version response" -Level "Warning"
        }
    } catch {
        $validationResults.FunctionalTests["APIFunctionality"] = "Failed"
        Write-ValidateLog "  ❌ API Functionality - Failed: $($_.Exception.Message)" -Level "Error"
    }
    
    # COMPREHENSIVE RESULTS
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "COMPREHENSIVE VALIDATION RESULTS" -ForegroundColor Cyan
    Write-Host "="*80 -ForegroundColor Cyan
    
    # Calculate overall success
    $allResults = @()
    $allResults += $validationResults.ContainerStatus.Values
    $allResults += $validationResults.ServiceEndpoints.Values  
    $allResults += $validationResults.Week4Features.Values
    $allResults += $validationResults.AIIntegration.Values
    $allResults += $validationResults.FunctionalTests.Values
    
    $workingCount = ($allResults | Where-Object { $_ -eq "Working" -or $_ -eq "Available" -or $_ -eq "Running" }).Count
    $totalCount = $allResults.Count
    $successRate = [math]::Round(($workingCount / $totalCount) * 100, 1)
    
    Write-Host "`n🎯 OVERALL SYSTEM STATUS: $successRate% ($workingCount/$totalCount components working)" -ForegroundColor $(if ($successRate -ge 95) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
    
    if ($successRate -ge 95) {
        Write-Host "`n🎉 ENHANCED DOCUMENTATION SYSTEM v2.0.0 IS FULLY OPERATIONAL!" -ForegroundColor Green
        Write-Host "✅ All critical components working" -ForegroundColor Green
        Write-Host "✅ Week 4 predictive analysis features available" -ForegroundColor Green  
        Write-Host "✅ AI services integrated and accessible" -ForegroundColor Green
        Write-Host "✅ PowerShell-AI bridge functional" -ForegroundColor Green
        Write-Host "`n🚀 SYSTEM READY FOR PRODUCTION USE!" -ForegroundColor Green
    } elseif ($successRate -ge 80) {
        Write-Host "`n⚡ System is mostly operational with excellent functionality" -ForegroundColor Yellow
        Write-Host "   Core features working, minor optimizations available" -ForegroundColor Yellow
    } else {
        Write-Host "`n⚠️ System needs additional troubleshooting" -ForegroundColor Red
    }
    
    # Save validation results
    $validationResults | ConvertTo-Json -Depth 5 | Out-File -FilePath "system-validation-results.json" -Encoding UTF8
    Write-ValidateLog "Validation results saved to: system-validation-results.json" -Level "Info"
    
} catch {
    Write-ValidateLog "Comprehensive validation failed: $($_.Exception.Message)" -Level "Error"
}

Write-Host "`n=== COMPREHENSIVE SYSTEM VALIDATION COMPLETE ===" -ForegroundColor Green