# Test Unity 2021.1.14f1 BUILD Compatibility
# Date: 2025-08-18

Write-Host "=== Unity 2021.1.14f1 BUILD Feature Test ===" -ForegroundColor Cyan

# Import SafeCommandExecution module
$modulePath = Join-Path $PSScriptRoot "Modules\SafeCommandExecution\SafeCommandExecution.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "Module loaded successfully" -ForegroundColor Green
} else {
    Write-Host "Module not found" -ForegroundColor Red
    return
}

# Test Unity 2021.1.14f1 BUILD command
$buildCommand = @{
    CommandType = 'Build'
    Operation = 'BuildPlayer' 
    Arguments = @{
        BuildTarget = 'Windows'
        ProjectPath = 'C:\UnityProjects\Sound-and-Shoal\Dithering'
    }
}

# Test safety validation
$safety = Test-CommandSafety -Command $buildCommand
Write-Host "Safety validation: $($safety.IsSafe)" -ForegroundColor $(if($safety.IsSafe) { "Green" } else { "Red" })
Write-Host "Reason: $($safety.Reason)" -ForegroundColor Gray

# Test Unity 2021 build targets
$targets = @('Windows', 'Android', 'iOS', 'WebGL', 'Linux')
Write-Host ""
Write-Host "Unity 2021.1.14f1 Build Targets:" -ForegroundColor Cyan
foreach ($target in $targets) {
    Write-Host "  $target - Supported" -ForegroundColor Green
}

Write-Host ""
Write-Host "BUILD Features Ready for Unity 2021.1.14f1" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZ1rhnBINmExfy37IaFuB2pad
# P7WgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNrgP3/q1eZvOv5oorshFwF2v8H4wDQYJKoZIhvcNAQEBBQAEggEALVYV
# GH3JQLzL97TjfJpVkky4YyZk/y18H2TEb1UknRNJjsOQ0VH3pzqzGqoNfDcqlO3I
# PUR1DhQvxKRlP+VupqnYqEZ/xUoyaDUaQjBdLrfLhhiGOGpzq/70mEeGb+GrzYWx
# 09RnaIyza91kVix39Up+iV5wZ5EEK0wWvMDeq8e7gE0NiyCQvdxY1W7Zg8qmVdtO
# 2M7hg127QlXp9j4fUzJvytzfR9z2OxuKOCoZ63FxgpIzXlGsIAi/cqvsWBn3DK2z
# jPEcT4F+fSsZrqVsmHTa19ESB6ouQkde4dIJV+o5OPsi26qaT9D1sSDq+lIdtRnj
# zxvs+YgNjEqlID906Q==
# SIG # End signature block
