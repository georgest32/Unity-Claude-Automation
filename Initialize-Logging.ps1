# Initialize-Logging.ps1
# Creates and manages a rolling log file for Unity-Claude-Automation
# Date: 2025-08-17

[CmdletBinding()]
param(
    [int]$MaxLines = 1000000,  # Default 1 million lines
    [string]$LogFile = (Join-Path $PSScriptRoot "unity_claude_automation.log"),
    [switch]$Clear
)

# Clear log if requested
if ($Clear -and (Test-Path $LogFile)) {
    Remove-Item $LogFile -Force
    Write-Host "Cleared existing log file" -ForegroundColor Yellow
}

# Create log file if it doesn't exist
if (-not (Test-Path $LogFile)) {
    $header = @"
================================================================================================
Unity-Claude-Automation Rolling Log
Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Max Lines: $MaxLines
================================================================================================

"@
    $header | Out-File $LogFile -Encoding UTF8
    Write-Host "Created new log file: $LogFile" -ForegroundColor Green
}

# Function to write to rolling log
function Write-RollingLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "General"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    # Append to log file
    $logEntry | Out-File $LogFile -Append -Encoding UTF8
    
    # Check if we need to trim the log
    $lineCount = (Get-Content $LogFile | Measure-Object -Line).Lines
    if ($lineCount -gt $MaxLines) {
        # Keep only the last 90% of max lines to avoid constant trimming
        $keepLines = [int]($MaxLines * 0.9)
        $content = Get-Content $LogFile | Select-Object -Last $keepLines
        
        $trimHeader = @"
================================================================================================
Log Trimmed: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Kept Last $keepLines Lines
================================================================================================

"@
        ($trimHeader + ($content -join "`n")) | Out-File $LogFile -Encoding UTF8
    }
}

# Export the logging function for use in other scripts
$Global:WriteRollingLog = ${function:Write-RollingLog}

Write-Host "Logging initialized successfully" -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host "Use Write-RollingLog to add entries" -ForegroundColor Gray

# Test the logging
Write-RollingLog -Message "Logging system initialized" -Level "INFO" -Component "Initialize-Logging"

return $LogFile
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUD2Dyan4Tru890gI6463Z/wiB
# dkWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUd3HXikxyen/6Mhoh+nDLK7a5vXcwDQYJKoZIhvcNAQEBBQAEggEAscGV
# qX/jFSvTnk3oBTqr6l0tElNZf2eTva7IzJd2IShCLqNA1GdsZySfrRk2D/wEYwSy
# ZhbXbDNVXPEm4dQBPAX9rw3vBGLvdecLg4+mNWz6rJbDgS3y5Ov57J3M2tHEzWd8
# 3FBhJAyFNYA6Rji9wxQKytXnj+4Jt9F/iXRfQ821+2t973RPj9ci1FTwp4riSGRC
# 38KKru3cZf2d53Ry0c4OIrVEVTQYKYbp97pX4iiqP6g0QDjZn0i/o6HriD/3ViJN
# 2e2J2d3YYVG/CVEd5cQMRMtzLhDzh+fETdanLjUVHz6mRrvxC3A8LVzbVDNmAImk
# xRAg5vND+wmsbgi3pg==
# SIG # End signature block
