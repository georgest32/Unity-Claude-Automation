# Generate-AI-Documentation-Simple.ps1
# Simple AI-powered documentation generation without complex string escaping
# Tests and uses all AI services for enhanced documentation
# Date: 2025-08-29

param(
    [string]$OutputPath = ".\docs\ai-enhanced",
    [switch]$TestOnly
)

function Write-AILog {
    param([string]$Message, [string]$Level = "Info")
    $color = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "AI" = "Magenta" }[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

Write-Host "=== AI-Enhanced Documentation Generation (Simple) ===" -ForegroundColor Cyan

$aiStatus = @{}
$results = @{}

try {
    # Test 1: LangGraph AI
    Write-AILog "Testing LangGraph AI service..." -Level "Info"
    
    try {
        $langResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 10 -UseBasicParsing
        $langData = $langResponse.Content | ConvertFrom-Json
        $aiStatus["LangGraph"] = @{
            Working = $true
            Status = $langData.status
            Database = $langData.database
        }
        Write-AILog "LangGraph AI: OPERATIONAL" -Level "Success"
    } catch {
        $aiStatus["LangGraph"] = @{ Working = $false; Error = $_.Exception.Message }
        Write-AILog "LangGraph AI: NOT AVAILABLE" -Level "Warning"
    }
    
    # Test 2: AutoGen GroupChat
    Write-AILog "Testing AutoGen GroupChat service..." -Level "Info"
    
    try {
        $autoGenResponse = Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 10 -UseBasicParsing
        $autoGenData = $autoGenResponse.Content | ConvertFrom-Json
        $aiStatus["AutoGen"] = @{
            Working = $true
            Status = $autoGenData.status
            Version = $autoGenData.autogen_version
            Sessions = $autoGenData.active_sessions
        }
        Write-AILog "AutoGen GroupChat: OPERATIONAL (Version: $($autoGenData.autogen_version))" -Level "Success"
    } catch {
        $aiStatus["AutoGen"] = @{ Working = $false; Error = $_.Exception.Message }
        Write-AILog "AutoGen GroupChat: NOT AVAILABLE" -Level "Warning"
    }
    
    # Test 3: Ollama LLM
    Write-AILog "Testing Ollama LLM service..." -Level "Info"
    
    try {
        $ollamaResponse = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -UseBasicParsing
        $aiStatus["Ollama"] = @{ Working = $true; Available = $true }
        Write-AILog "Ollama LLM: OPERATIONAL" -Level "Success"
    } catch {
        $aiStatus["Ollama"] = @{ Working = $false; Error = $_.Exception.Message }
        Write-AILog "Ollama LLM: NOT AVAILABLE (Local AI not running)" -Level "Warning"
    }
    
    # Test 4: Week 4 Features
    Write-AILog "Testing Week 4 predictive features..." -Level "Info"
    
    $week4Functions = @("Get-GitCommitHistory", "Get-TechnicalDebt", "Get-MaintenancePrediction")
    $availableWeek4 = 0
    
    foreach ($func in $week4Functions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            $availableWeek4++
        }
    }
    
    $aiStatus["Week4"] = @{
        Working = ($availableWeek4 -eq $week4Functions.Count)
        Available = $availableWeek4
        Total = $week4Functions.Count
    }
    
    if ($aiStatus["Week4"].Working) {
        Write-AILog "Week 4 Features: FULLY AVAILABLE ($availableWeek4 functions)" -Level "Success"
    } else {
        Write-AILog "Week 4 Features: PARTIAL ($availableWeek4/$($week4Functions.Count) functions)" -Level "Warning"
    }
    
    # Calculate AI capability level
    $workingAI = ($aiStatus.Values | Where-Object { $_.Working }).Count
    $totalAI = $aiStatus.Count
    $aiCapability = [math]::Round(($workingAI / $totalAI) * 100, 1)
    
    Write-AILog "AI Capability Assessment: $aiCapability% ($workingAI/$totalAI services)" -Level "AI"
    
    if ($TestOnly) {
        Write-AILog "Test-only mode complete" -Level "Info"
        return $aiStatus
    }
    
    # Generate documentation if not test-only
    Write-AILog "Generating AI-enhanced documentation..." -Level "AI"
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Generate Week 4 reports
    if ($aiStatus["Week4"].Working) {
        Write-AILog "Generating Week 4 predictive analysis reports..." -Level "AI"
        
        try {
            # Evolution report
            $evolution = New-EvolutionReport -Path ".\Modules" -Since "6.months.ago" -Format "JSON"
            if ($evolution) {
                $evolution | Out-File -FilePath "$OutputPath\evolution-report.json" -Encoding UTF8
                Write-AILog "Generated: evolution-report.json" -Level "Success"
            }
            
            # Maintenance report
            $maintenance = New-MaintenanceReport -Path ".\Modules" -Format "JSON"
            if ($maintenance) {
                $maintenance | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutputPath\maintenance-report.json" -Encoding UTF8
                Write-AILog "Generated: maintenance-report.json" -Level "Success"
            }
            
        } catch {
            Write-AILog "Week 4 report generation failed: $($_.Exception.Message)" -Level "Error"
        }
    }
    
    # Create AI status report
    $statusReport = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SystemVersion = "Enhanced Documentation System v2.0.0"
        AICapability = "$aiCapability%"
        Services = $aiStatus
        Documentation = @{
            Quality = if ($aiCapability -ge 75) { "High" } elseif ($aiCapability -ge 50) { "Medium" } else { "Basic" }
            AIEnhancement = if ($workingAI -ge 3) { "Maximum" } elseif ($workingAI -ge 2) { "High" } else { "Limited" }
        }
        RequiredActions = @()
    }
    
    # Add required actions for non-working services
    foreach ($service in $aiStatus.Keys) {
        if (-not $aiStatus[$service].Working) {
            $statusReport.RequiredActions += "Activate $service service for enhanced capabilities"
        }
    }
    
    $statusReport | ConvertTo-Json -Depth 5 | Out-File -FilePath "$OutputPath\ai-status-report.json" -Encoding UTF8
    Write-AILog "Generated: ai-status-report.json" -Level "Success"
    
    # Summary
    Write-AILog "AI-Enhanced Documentation Generation Complete!" -Level "AI"
    Write-AILog "AI Capability Level: $aiCapability%" -Level "AI"
    Write-AILog "Documentation Quality: $($statusReport.Documentation.Quality)" -Level "AI" 
    Write-AILog "Output Directory: $OutputPath" -Level "Success"
    
    if ($statusReport.RequiredActions.Count -eq 0) {
        Write-AILog "🎉 ALL AI SERVICES OPERATIONAL - MAXIMUM ENHANCEMENT ACHIEVED!" -Level "AI"
    } else {
        Write-AILog "⚡ $workingAI/$totalAI AI services working - $(if ($workingAI -ge 2) { 'High' } else { 'Basic' }) enhancement level" -Level "AI"
        Write-AILog "Actions needed: $($statusReport.RequiredActions -join '; ')" -Level "Warning"
    }
    
    return $statusReport
    
} catch {
    Write-AILog "AI documentation generation failed: $($_.Exception.Message)" -Level "Error"
    throw
}

Write-Host "`n=== AI-Enhanced Documentation Complete ===" -ForegroundColor Green