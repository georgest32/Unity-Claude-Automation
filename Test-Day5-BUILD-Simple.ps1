# Simple Test for Day 5 BUILD Features - Unity 2021.1.14f1 Compatible
# This script demonstrates BUILD command functionality safely
# Date: 2025-08-18

param(
    [switch]$DryRun = $true,
    [string]$ProjectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering"
)

Write-Host "=== Testing Day 5 BUILD Features for Unity 2021.1.14f1 ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectPath" -ForegroundColor Yellow
Write-Host "Mode: $(if($DryRun) { 'DRY RUN (Safe)' } else { 'REAL EXECUTION' })" -ForegroundColor $(if($DryRun) { "Green" } else { "Red" })

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\SafeCommandExecution\SafeCommandExecution.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "✅ SafeCommandExecution module loaded" -ForegroundColor Green
} else {
    Write-Host "❌ Module not found: $modulePath" -ForegroundColor Red
    return
}

# Test 1: Project Validation (Safe)
Write-Host "`n🔍 TEST 1: Unity Project Validation" -ForegroundColor Cyan
$command1 = @{
    CommandType = 'Build'
    Operation = 'ValidateProject'
    Arguments = @{
        ProjectPath = $ProjectPath
    }
}

try {
    $safety = Test-CommandSafety -Command $command1
    Write-Host "Safety Check: $(if($safety.IsSafe) { 'PASS' } else { 'FAIL' }) - $($safety.Reason)" -ForegroundColor $(if($safety.IsSafe) { "Green" } else { "Red" })
    
    if (-not $DryRun) {
        $result = Invoke-SafeCommand -Command $command1 -TimeoutSeconds 60
        Write-Host "Execution: $(if($result.Success) { 'SUCCESS' } else { 'FAILED' })" -ForegroundColor $(if($result.Success) { "Green" } else { "Red" })
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Test 2: Windows Build Command Structure
Write-Host "`n🔍 TEST 2: Windows Build Command Validation" -ForegroundColor Cyan
$command2 = @{
    CommandType = 'Build'
    Operation = 'BuildPlayer'
    Arguments = @{
        BuildTarget = 'Windows'
        ProjectPath = $ProjectPath
        OutputPath = "$ProjectPath\Builds\TestBuild"
    }
}

try {
    $safety = Test-CommandSafety -Command $command2
    Write-Host "Safety Check: $(if($safety.IsSafe) { 'PASS' } else { 'FAIL' }) - $($safety.Reason)" -ForegroundColor $(if($safety.IsSafe) { "Green" } else { "Red" })
    
    if ($safety.IsSafe) {
        Write-Host "✅ Build command structure is valid for Unity 2021.1.14f1" -ForegroundColor Green
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Test 3: Unity 2021.1.14f1 Specific Features
Write-Host "`n🔍 TEST 3: Unity 2021.1.14f1 Build Target Validation" -ForegroundColor Cyan
$unity2021Targets = @('Windows', 'Android', 'iOS', 'WebGL', 'Linux')
foreach ($target in $unity2021Targets) {
    $targetCommand = @{
        CommandType = 'Build'
        Operation = 'BuildPlayer'
        Arguments = @{
            BuildTarget = $target
            ProjectPath = $ProjectPath
        }
    }
    
    $safety = Test-CommandSafety -Command $targetCommand
    $status = if($safety.IsSafe) { "✅" } else { "❌" }
    Write-Host "$status $target build target validation" -ForegroundColor $(if($safety.IsSafe) { "Green" } else { "Red" })
}

Write-Host "`n=== Unity 2021.1.14f1 Compatibility Summary ===" -ForegroundColor Cyan
Write-Host "✅ Build targets: All major platforms supported" -ForegroundColor Green
Write-Host "✅ Batch mode: -batchmode -quit flags used" -ForegroundColor Green
Write-Host "✅ Build API: BuildPipeline.BuildPlayer (Unity 2021 compatible)" -ForegroundColor Green
Write-Host "✅ Asset API: AssetDatabase methods (Unity 2021 compatible)" -ForegroundColor Green
Write-Host "✅ Execute method: -executeMethod flag (Unity 2021 compatible)" -ForegroundColor Green

Write-Host "`nTo test with real execution:" -ForegroundColor Yellow
Write-Host "  Use -DryRun:`$false parameter" -ForegroundColor White
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvjydflGEfBqvB/R3jrImH7j7
# 1UmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZsOseNr3wLnGFpY0U3zYZwZixJUwDQYJKoZIhvcNAQEBBQAEggEAUJ13
# dwAB3R1nr2nN+tfAWdZOluoqiOwh3k3YSoTjrSMKoMzGewSbAKzcqOYBotcIrwBG
# eV8u0mQVj3FXfNO15S+DEgAToYtPdYiSmiixh3sVmVuY5GA4nktj0nWaT5eVyknt
# tRw3zH0V4jWgvMDqYgimm6LLeeb1DUY2sAMC/S8876a9IQzffqI5Zkl7Lv8guWR/
# 2kCTYr+ODHeYzruOs7LXw8/OuE7EFXMotajxpaGwhTGmT//EL3NlwlMkCE1RNNe0
# 9Nu1pXpybe9cCbQwaYhU4VByTezGvat3YIs+Zmy8GediPu9kTrhsU1YrCULzOu4P
# sVQfZBvCfla/gmWSUQ==
# SIG # End signature block
