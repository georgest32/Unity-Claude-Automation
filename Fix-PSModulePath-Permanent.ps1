# Fix-PSModulePath-Permanent.ps1
# Permanently fix PSModulePath for Unity-Claude-Automation
# Date: 2025-08-21

Write-Host "=== Permanent PSModulePath Fix for Unity-Claude-Automation ===" -ForegroundColor Cyan

$moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"

# Check if path exists
if (-not (Test-Path $moduleBasePath)) {
    Write-Host "ERROR: Modules directory not found at: $moduleBasePath" -ForegroundColor Red
    exit 1
}

Write-Host "Modules directory found: $moduleBasePath" -ForegroundColor Green

# Get current machine-level PSModulePath
$currentMachinePath = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
$currentUserPath = [Environment]::GetEnvironmentVariable("PSModulePath", "User")

Write-Host ""
Write-Host "Current PSModulePath:" -ForegroundColor Yellow
Write-Host "  Machine: $currentMachinePath" -ForegroundColor Gray
Write-Host "  User: $currentUserPath" -ForegroundColor Gray

# Check if already in path
$allPaths = @()
if ($currentMachinePath) { $allPaths += $currentMachinePath -split ';' }
if ($currentUserPath) { $allPaths += $currentUserPath -split ';' }

$alreadyInPath = $allPaths -contains $moduleBasePath

Write-Host ""
if ($alreadyInPath) {
    Write-Host "[SUCCESS] Modules path is already in PSModulePath" -ForegroundColor Green
} else {
    Write-Host "Adding to User PSModulePath..." -ForegroundColor Yellow
    
    if ($currentUserPath) {
        $newUserPath = "$moduleBasePath;$currentUserPath"
    } else {
        $newUserPath = $moduleBasePath
    }
    
    # Set user-level environment variable
    [Environment]::SetEnvironmentVariable("PSModulePath", $newUserPath, "User")
    
    # Also set for current session
    $env:PSModulePath = "$moduleBasePath;$($env:PSModulePath)"
    
    Write-Host "[SUCCESS] Added to User PSModulePath: $moduleBasePath" -ForegroundColor Green
    Write-Host "[SUCCESS] Applied to current session" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan

# Verify modules can be discovered
$testModules = @(
    'Unity-Claude-IntegratedWorkflow',
    'Unity-Claude-ParallelProcessing',
    'Unity-Claude-RunspaceManagement',
    'Unity-Claude-UnityParallelization',
    'Unity-Claude-ClaudeParallelization'
)

$discoveredCount = 0
foreach ($moduleName in $testModules) {
    $module = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue
    if ($module) {
        Write-Host "[SUCCESS] $moduleName v$($module.Version)" -ForegroundColor Green
        $discoveredCount++
    } else {
        Write-Host "[MISSING] $moduleName" -ForegroundColor Red
    }
}

Write-Host ""
if ($discoveredCount -eq $testModules.Count) {
    Write-Host "[SUCCESS] All $discoveredCount/$($testModules.Count) modules discoverable" -ForegroundColor Green
    Write-Host ""
    Write-Host "PSModulePath fix complete! You can now:" -ForegroundColor White
    Write-Host "1. Run Test-Week3-Day5-EndToEndIntegration.ps1 directly" -ForegroundColor Gray  
    Write-Host "2. Import modules by name without full paths" -ForegroundColor Gray
    Write-Host "3. Use PowerShell auto-discovery for all Unity-Claude modules" -ForegroundColor Gray
} else {
    Write-Host "[WARNING] Only $discoveredCount/$($testModules.Count) modules discoverable" -ForegroundColor Yellow
    Write-Host "You may need to restart PowerShell to see the changes" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Fix Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCs/Bn7ZrVNxb5npW0EAgaGQY
# 3MKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUW/l6/PNwK2zwUZk3ri5g9e4TrnYwDQYJKoZIhvcNAQEBBQAEggEAPhOH
# 8rrJ6R9vTZwTN/Sar4+HsYjKRw1ucHwVWYMFk0sufZ6OXvJ/IxVIF4KAbEXtgO3D
# imxZ6/HC+kkRg99J1C7VL795wpbrpbxBwXeFlAnwSH+g7cY1emjv1b1f4L9+XJhT
# q4eCX/9kCWyS+5ypgEGnPtSjZ6ZervOv8f4hkhA5eyg7JZmnyp6i+1de3AbceIqD
# dFhsnuJUsPFFUQrGKDq8RSk2rZXRrK/49HrHA2ZnwUEtnehxJzeH2mMbwE3Cabo7
# W8oi+7aeU4EHN+D3P/drK2JEZ+lNWA92p0l8R5OJK8MaY5M0Cy1GmL9pcGCt+J/0
# XPUqi8rV2URAekCc9A==
# SIG # End signature block
