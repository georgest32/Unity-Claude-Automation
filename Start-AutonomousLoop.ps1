# Start-AutonomousLoop.ps1
# Startup script for autonomous feedback loop in new window
# Date: 2025-08-18

param(
    [int]$MaxCycles = 50,
    [int]$CycleTimeoutMs = 300000,
    [string]$SessionName = "AutoSession"
)

# Ensure we're in the correct directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Starting Unity-Claude Autonomous Feedback Loop..." -ForegroundColor Cyan
Write-Host "Project Directory: $(Get-Location)" -ForegroundColor Gray

try {
    # Load the integration engine
    Write-Host "Loading Integration Engine..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-IntegrationEngine.psm1" -Force
    Write-Host "Integration Engine loaded successfully" -ForegroundColor Green
    
    # Check module availability
    $commands = Get-Command -Module Unity-Claude-IntegrationEngine
    Write-Host "Available commands: $($commands.Name -join ', ')" -ForegroundColor Gray
    
    # Start autonomous operation
    Write-Host "Starting autonomous feedback loop..." -ForegroundColor Yellow
    Write-Host "Max Cycles: $MaxCycles" -ForegroundColor Gray
    Write-Host "Cycle Timeout: ${CycleTimeoutMs}ms" -ForegroundColor Gray
    Write-Host "Session Name: $SessionName" -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop gracefully" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    Start-AutonomousFeedbackLoop -MaxCycles $MaxCycles -CycleTimeoutMs $CycleTimeoutMs
    
} catch {
    Write-Host "Error starting autonomous loop: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error details: $($_.Exception)" -ForegroundColor DarkRed
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2/n4QJgACu6HGlT9A6mIB30g
# 8eigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8MUviflbd98fra/aShPh04kXVEIwDQYJKoZIhvcNAQEBBQAEggEAHGq1
# kseTaFauIkZQQYWoZTAWhHc0lCtXECtFFGzUMZx6ECQtFq/Dp+IAwUmZ3fzuI3xb
# LcWNs9bS+U2QKgSxSn33Zt+Hli7P3dPXxoNnq2NpEgMEoCyjmaWPgyQOyUKCLD36
# rhsRJf+qVBbzUod9fRr35U5/Qkm4DaNvPnF+1di7L8rYDmpJHeUePx2ClrrHpG41
# TRyGip0I+FjCduIgW55xPy4qRHXvSqd1O0efef3E2vtCqxlZVbu48ISHbFN4f18N
# 91ZQhUtqQRqXmuUFf5e//ez6yyzWWAU74u9+JyHjWfc0ZZzsanEb6xjhd3lyvvGA
# jCgn6Mwbrfy3IiRR+w==
# SIG # End signature block
