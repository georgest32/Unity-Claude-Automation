# Debug-UnityProjectRegistrationState.ps1
# Investigate Unity project registration persistence issue
# Trace the exact state of module registries and function calls
# Date: 2025-08-21

[CmdletBinding()]
param()

Write-Host "=== Unity Project Registration State Debugging ===" -ForegroundColor Cyan
Write-Host "Investigating registration persistence issue" -ForegroundColor White
Write-Host ""

# Load modules in same sequence as test script
$moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
if ($env:PSModulePath -notlike "*$moduleBasePath*") {
    $env:PSModulePath = "$moduleBasePath;$($env:PSModulePath)"
}

try {
    Write-Host "1. Loading modules in test sequence..." -ForegroundColor Yellow
    
    # Load TestMocks first (same as test script)
    Write-Host "   Loading Unity-Project-TestMocks..." -ForegroundColor Gray
    Import-Module ".\Unity-Project-TestMocks.psm1" -Force -Global -ErrorAction Stop
    
    # Load real modules
    Write-Host "   Loading Unity-Claude-ParallelProcessing..." -ForegroundColor Gray
    Import-Module "$moduleBasePath\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1" -Force -Global -ErrorAction Stop
    
    Write-Host "   Loading Unity-Claude-RunspaceManagement..." -ForegroundColor Gray
    Import-Module "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1" -Force -Global -ErrorAction Stop
    
    Write-Host "   Loading Unity-Claude-UnityParallelization..." -ForegroundColor Gray
    Import-Module "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1" -Force -Global -ErrorAction Stop
    
    Write-Host "   Modules loaded successfully" -ForegroundColor Green
    
} catch {
    Write-Host "   ERROR: Module loading failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Analyzing Test-UnityProjectAvailability function sources..." -ForegroundColor Yellow

# Check all available Test-UnityProjectAvailability functions
$availabilityFunctions = Get-Command Test-UnityProjectAvailability -All -ErrorAction SilentlyContinue
Write-Host "   Found $($availabilityFunctions.Count) Test-UnityProjectAvailability function(s):" -ForegroundColor White

foreach ($func in $availabilityFunctions) {
    Write-Host "     Source: $($func.Source)" -ForegroundColor Gray
    Write-Host "     Module: $($func.ModuleName)" -ForegroundColor Gray
    Write-Host "     CommandType: $($func.CommandType)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "3. Testing Unity project registration with real UnityParallelization module..." -ForegroundColor Yellow

# Create mock projects and register with REAL module
$mockProjects = @("Unity-Project-1", "Unity-Project-2", "Unity-Project-3")
$mockProjectsBasePath = "C:\MockProjects"

$registrationResults = @{}
foreach ($projectName in $mockProjects) {
    $projectPath = Join-Path $mockProjectsBasePath $projectName
    
    Write-Host "   [DEBUG] Registering $projectName..." -ForegroundColor Cyan
    
    try {
        # Ensure project directory exists
        if (-not (Test-Path $projectPath)) {
            New-Item -Path $projectPath -ItemType Directory -Force | Out-Null
            New-Item -Path "$projectPath\Assets" -ItemType Directory -Force | Out-Null
            New-Item -Path "$projectPath\ProjectSettings" -ItemType Directory -Force | Out-Null
            @"
m_EditorVersion: 2021.1.14f1
m_EditorVersionWithRevision: 2021.1.14f1 (54ba63c7b9e8)
"@ | Set-Content "$projectPath\ProjectSettings\ProjectVersion.txt" -Encoding UTF8
        }
        
        # Register using REAL UnityParallelization function
        Write-Host "     Calling Register-UnityProject..." -ForegroundColor Gray
        $registration = Register-UnityProject -ProjectPath $projectPath -ProjectName $projectName -MonitoringEnabled
        
        # Test availability using REAL UnityParallelization function (specify module)
        Write-Host "     Testing availability with UnityParallelization module function..." -ForegroundColor Gray
        $realAvailability = & (Get-Command Test-UnityProjectAvailability -Module Unity-Claude-UnityParallelization) -ProjectName $projectName
        
        $registrationResults[$projectName] = @{
            RegistrationSuccess = $registration -ne $null
            RealAvailability = $realAvailability.Available
            Reason = $realAvailability.Reason
        }
        
        $status = if ($realAvailability.Available) { "SUCCESS" } else { "FAILED" }
        $color = if ($realAvailability.Available) { "Green" } else { "Red" }
        Write-Host "     [$status] $projectName - Available: $($realAvailability.Available)" -ForegroundColor $color
        if (-not $realAvailability.Available) {
            Write-Host "       Reason: $($realAvailability.Reason)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "     [ERROR] Registration failed: $($_.Exception.Message)" -ForegroundColor Red
        $registrationResults[$projectName] = @{
            RegistrationSuccess = $false
            Error = $_.Exception.Message
        }
    }
}

Write-Host ""
Write-Host "4. Testing workflow creation with registered projects..." -ForegroundColor Yellow

# Test workflow creation (same as failing test)
try {
    Write-Host "   Creating IntegratedWorkflow 'DebugTestWorkflow'..." -ForegroundColor Gray
    $workflow = New-IntegratedWorkflow -WorkflowName "DebugTestWorkflow" -MaxUnityProjects 2 -MaxClaudeSubmissions 3
    
    if ($workflow) {
        Write-Host "   [SUCCESS] Workflow created successfully!" -ForegroundColor Green
        Write-Host "     Workflow Name: $($workflow.Name)" -ForegroundColor Gray
        Write-Host "     Workflow Type: $($workflow.GetType().Name)" -ForegroundColor Gray
    } else {
        Write-Host "   [FAILED] Workflow creation returned null" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   [ERROR] Workflow creation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Error details: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host ""
Write-Host "5. Final state analysis..." -ForegroundColor Yellow

# Check final registration state
foreach ($projectName in $mockProjects) {
    try {
        # Test with explicit module function call
        $finalAvailability = & (Get-Command Test-UnityProjectAvailability -Module Unity-Claude-UnityParallelization) -ProjectName $projectName
        
        $status = if ($finalAvailability.Available) { "AVAILABLE" } else { "NOT_AVAILABLE" }
        $color = if ($finalAvailability.Available) { "Green" } else { "Red" }
        Write-Host "   [$status] $projectName (Real module check)" -ForegroundColor $color
        if (-not $finalAvailability.Available) {
            Write-Host "     Reason: $($finalAvailability.Reason)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "   [ERROR] $projectName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Debug Analysis Summary ===" -ForegroundColor Cyan

$successfulRegistrations = ($registrationResults.Values | Where-Object { $_.RealAvailability -eq $true }).Count
Write-Host "Successful registrations: $successfulRegistrations/$($mockProjects.Count)" -ForegroundColor $(if ($successfulRegistrations -eq $mockProjects.Count) { "Green" } else { "Red" })

Write-Host ""
Write-Host "Root Cause Analysis:" -ForegroundColor White
Write-Host "- Check if multiple Test-UnityProjectAvailability functions exist" -ForegroundColor Gray
Write-Host "- Verify UnityParallelization module's script:RegisteredUnityProjects state" -ForegroundColor Gray
Write-Host "- Investigate module scope isolation between registration and workflow creation" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Debug Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1tnghfzQ4QUnLdoKxq7VCjPe
# pl+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU3nuPVANF5g2pZm9Pqhjm7xJMFbQwDQYJKoZIhvcNAQEBBQAEggEAoy68
# 5iwt00I8P7e2xYf81v/Y2tmCukRD3DLqo8EhPoshbXV+djZQVPeb4XF+AFqmqSVW
# GXtsyjJavsd1gi/oPMgkPi5nI22pRodW/DxwJomyvmsKoLmK5kn6Gi2qib4a7y/a
# QAxChfRiOVJ3BUkvePopVGlCBWmwwQ0DGzyYpnxSjpuv31xY1oyTAAsjE0HslJrN
# aaV5mON/9jCwr8WFHp1uDis2/cgvroFP8IjU2vlIYIZTPyNVcYXzsj19BA39vZJ3
# L7ERMS+HCc/rSry6+f70WD++3nYyrSANfj722VFfO5cUvtV+eJaN19SqPtVggLEh
# JlWWOacO3bgnQa55dg==
# SIG # End signature block
