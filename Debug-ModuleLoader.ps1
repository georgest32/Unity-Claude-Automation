# Debug module loader
$ModuleRoot = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus'

Write-Host "Starting module loader debug..." -ForegroundColor Cyan

# Get all PS1 files
$files = Get-ChildItem -Path $ModuleRoot -Recurse -Filter '*.ps1'
Write-Host "Found $($files.Count) .ps1 files total"

# Look for mutex file
$mutexFile = $files | Where-Object { $_.Name -eq 'New-SubsystemMutex.ps1' }
if ($mutexFile) {
    Write-Host "Mutex file found at: $($mutexFile.FullName)" -ForegroundColor Green
    
    # Try to load it
    try {
        . $mutexFile.FullName
        Write-Host "Mutex file dot-sourced successfully" -ForegroundColor Green
        
        # Check if functions are available
        $functions = @('New-SubsystemMutex', 'Test-SubsystemMutex', 'Remove-SubsystemMutex')
        foreach ($func in $functions) {
            if (Get-Command $func -ErrorAction SilentlyContinue) {
                Write-Host "  Function available: $func" -ForegroundColor Green
            } else {
                Write-Host "  Function MISSING: $func" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "ERROR loading mutex file: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Mutex file NOT found in file collection!" -ForegroundColor Red
}

Write-Host "`nNow testing module import..." -ForegroundColor Cyan

# Remove and re-import module
Remove-Module Unity-Claude-SystemStatus -ErrorAction SilentlyContinue
Import-Module "$ModuleRoot\Unity-Claude-SystemStatus.psd1" -Force

# Check if functions are available after module import
Write-Host "`nChecking functions after module import:"
$functions = @('New-SubsystemMutex', 'Test-SubsystemMutex', 'Remove-SubsystemMutex', 'Write-SystemStatusLog')
foreach ($func in $functions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "  Module exports: $func" -ForegroundColor Green
    } else {
        Write-Host "  Module MISSING: $func" -ForegroundColor Yellow
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdujSWasJ4cN6WIuj33WdBgSC
# 4f6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUCjR7hrqtECGJiJphkt6ebQ4Lg7kwDQYJKoZIhvcNAQEBBQAEggEAFaZ2
# g7I+m9cpBoinQUbaNyLEO0lo0qwPdv37+7gHLVTwNiAYUdYyw11VbUmajKXyuQR5
# JtxY+DQDzIPCY5XlGugZxIfibc6vlVRb13ZmHFyJRJAYsFcWAxs84Q0KqofldyOe
# qnksyiE0e/jJdft7XTZkl0xnt0ioYvluP6ByiBEm2raMgCi3T2FoDHEP+4pq2UzL
# dTH+KUXYun+eJZjWyLJJI1sDBDM1kdTIAOeHw13lV/AcJTyGcA70d7f892JC6UiX
# HhuVoA1CfMlYZ7KfybtHvG51Gy38OiNxqzEgGHXyqThCGbhswDkzrP1AFWJbJh2f
# gBAsYpF8Sp+GDNER/A==
# SIG # End signature block
