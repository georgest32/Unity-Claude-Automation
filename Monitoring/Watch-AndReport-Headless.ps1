# Watch-AndReport-Headless.ps1
# Enhanced error monitoring with TRUE background Claude submission
# NO WINDOW SWITCHING - runs completely in background!

[CmdletBinding()]
param(
    [string]$WatchPath = (Join-Path $PSScriptRoot 'AutomationLogs'),
    [switch]$AutoSubmit,
    [int]$ErrorThreshold = 5,
    [switch]$SaveResponses,
    [string]$ResponsePath = (Join-Path $PSScriptRoot 'ClaudeResponses')
)

Clear-Host
Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║       Unity-Claude Error Monitor (Headless Mode)         ║
║                                                           ║
║  TRUE BACKGROUND OPERATION - No window switching!        ║
║                                                           ║
║  Press Q to quit | E to export | S to submit            ║
║  Press A to toggle auto-submit (currently: OFF)          ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$script:ErrorCount = 0
$script:ErrorBuffer = @()
$script:LastExport = $null
$script:AutoSubmitEnabled = $AutoSubmit
$script:LastSubmission = $null
$script:SubmissionInProgress = $false

# Create response directory if needed
if ($SaveResponses -and -not (Test-Path $ResponsePath)) {
    New-Item -ItemType Directory -Path $ResponsePath -Force | Out-Null
}

# Function to submit to Claude in background
function Submit-ToClaudeBackground {
    param([string]$ExportPath)
    
    if ($script:SubmissionInProgress) {
        Write-Host "Submission already in progress..." -ForegroundColor Yellow
        return
    }
    
    $script:SubmissionInProgress = $true
    Write-Host "`n🤖 Submitting to Claude (background)..." -ForegroundColor Cyan
    
    # Create a background job for the submission
    $job = Start-Job -ScriptBlock {
        param($ScriptRoot, $ExportPath, $SaveResponses, $ResponsePath)
        
        $headlessScript = Join-Path $ScriptRoot 'Submit-ErrorsToClaude-Headless.ps1'
        
        if (Test-Path $headlessScript) {
            $outputFile = $null
            if ($SaveResponses) {
                $outputFile = Join-Path $ResponsePath "Response_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            }
            
            if ($ExportPath) {
                & $headlessScript -ErrorLogPath $ExportPath -OutputFile $outputFile
            } else {
                & $headlessScript -ErrorType 'Last' -OutputFile $outputFile
            }
            
            return @{
                Success = $true
                OutputFile = $outputFile
                Timestamp = Get-Date
            }
        } else {
            return @{
                Success = $false
                Error = "Headless script not found"
            }
        }
    } -ArgumentList $PSScriptRoot, $ExportPath, $SaveResponses, $ResponsePath
    
    # Register job completion event
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($Event.Sender.State -eq 'Completed') {
            $result = Receive-Job -Job $Event.Sender
            
            if ($result.Success) {
                Write-Host "`n✅ Claude submission complete!" -ForegroundColor Green
                if ($result.OutputFile) {
                    Write-Host "   Response saved: $(Split-Path $result.OutputFile -Leaf)" -ForegroundColor Gray
                }
            } else {
                Write-Host "`n❌ Submission failed: $($result.Error)" -ForegroundColor Red
            }
            
            $script:SubmissionInProgress = $false
            $script:LastSubmission = $result.Timestamp
            
            # Clean up the job
            Remove-Job -Job $Event.Sender
            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
            Remove-Job -Id $Event.SourceIdentifier
        }
    } | Out-Null
    
    Write-Host "   Job started (ID: $($job.Id))" -ForegroundColor Gray
    Write-Host "   You can continue working while Claude processes..." -ForegroundColor Green
}

# Function to check for new errors
function Check-Errors {
    $logFiles = Get-ChildItem -Path $WatchPath -Filter "*.log" -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
    
    if ($logFiles) {
        $content = Get-Content $logFiles.FullName -Tail 50
        $errors = $content | Where-Object { $_ -match '\[ERROR\]|error CS|Exception' }
        
        foreach ($error in $errors) {
            if ($error -notin $script:ErrorBuffer) {
                $script:ErrorBuffer += $error
                $script:ErrorCount++
                
                # Display error
                $timestamp = Get-Date -Format 'HH:mm:ss'
                Write-Host "[$timestamp] ERROR DETECTED:" -ForegroundColor Red
                Write-Host "  $error" -ForegroundColor Yellow
                
                # Auto-submit if threshold reached
                if ($script:AutoSubmitEnabled -and $script:ErrorCount -ge $ErrorThreshold) {
                    Write-Host "`n⚠ Error threshold reached! Auto-submitting..." -ForegroundColor Magenta
                    
                    # Export errors
                    $exportPath = & (Join-Path $PSScriptRoot 'Export-ErrorsForClaude.ps1') `
                                    -ErrorType 'Last' `
                                    -IncludeConsole `
                                    -IncludeTestResults
                    
                    # Submit in background
                    Submit-ToClaudeBackground -ExportPath $exportPath
                    
                    $script:ErrorCount = 0
                }
            }
        }
    }
}

# Function to export errors
function Export-CurrentErrors {
    Write-Host "`nExporting errors..." -ForegroundColor Yellow
    
    $exportPath = & (Join-Path $PSScriptRoot 'Export-ErrorsForClaude.ps1') `
                    -ErrorType 'Last' `
                    -IncludeConsole `
                    -IncludeTestResults
    
    $script:LastExport = $exportPath
    Write-Host "Exported to: $exportPath" -ForegroundColor Green
    
    return $exportPath
}

# Main monitoring loop
Write-Host "Monitoring started at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
Write-Host "Watching: $WatchPath" -ForegroundColor Gray
Write-Host ""

$timer = New-Object System.Timers.Timer
$timer.Interval = 2000  # Check every 2 seconds
$timer.AutoReset = $true
$timer.add_Elapsed({ Check-Errors })
$timer.Start()

# Handle keyboard input
while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            'Q' {
                Write-Host "`nStopping monitor..." -ForegroundColor Yellow
                $timer.Stop()
                
                # Wait for any pending submissions
                if ($script:SubmissionInProgress) {
                    Write-Host "Waiting for pending submission to complete..." -ForegroundColor Yellow
                    Get-Job | Wait-Job -Timeout 10 | Out-Null
                }
                
                # Clean up jobs
                Get-Job | Remove-Job -Force
                
                Write-Host "Monitor stopped." -ForegroundColor Green
                exit
            }
            
            'E' {
                Export-CurrentErrors
            }
            
            'S' {
                # Submit to Claude in background
                Submit-ToClaudeBackground -ExportPath $script:LastExport
            }
            
            'A' {
                # Toggle auto-submit
                $script:AutoSubmitEnabled = -not $script:AutoSubmitEnabled
                $status = if ($script:AutoSubmitEnabled) { 'ON' } else { 'OFF' }
                $color = if ($script:AutoSubmitEnabled) { 'Green' } else { 'Yellow' }
                Write-Host "`nAuto-submit to Claude: $status" -ForegroundColor $color
            }
            
            'J' {
                # Show job status
                Write-Host "`n═══ Background Jobs ═══" -ForegroundColor Cyan
                $jobs = Get-Job
                if ($jobs) {
                    $jobs | ForEach-Object {
                        Write-Host "Job $($_.Id): $($_.State)" -ForegroundColor White
                    }
                } else {
                    Write-Host "No active jobs" -ForegroundColor Gray
                }
                Write-Host ""
            }
            
            'H' {
                # Show help
                Write-Host "`n═══ Keyboard Shortcuts ═══" -ForegroundColor Cyan
                Write-Host "Q - Quit monitoring" -ForegroundColor White
                Write-Host "E - Export errors to file" -ForegroundColor White
                Write-Host "S - Submit to Claude (background)" -ForegroundColor White
                Write-Host "A - Toggle auto-submit" -ForegroundColor White
                Write-Host "J - Show background job status" -ForegroundColor White
                Write-Host "H - Show this help" -ForegroundColor White
                Write-Host ""
            }
        }
    }
    
    Start-Sleep -Milliseconds 100
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUM+cYM6kGRsGnb6tbqfMn5LE6
# dXqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUu1jjjx3wOxJ57nKnthZ22bmRRr8wDQYJKoZIhvcNAQEBBQAEggEApaf1
# HqLceGkZtkCdmyhcnUe7Mxz70p0AIDbA/0YIn5dHccO98BVeH12LoVy3kF2eBBvn
# A+/xz10DBZvMvrEvBS3wuNyGhHkUJNFbrVxooofHfavFSOUAqe+PZG6GzaEJ9ayB
# zi+8v/RFXAP+oEUVx6Y8Xmk1W6pg0WjVjuRBYe6OYuzviptr5QK0EF5HWqXN9kAt
# Xpvlx2jAIJzAw4pLr41fgL0mODTu/OMRMXPgVM9eNQw8hvjg9q+7Z73L4qBt2x8L
# Q1YG6hZ3k3eQTrL6TpzWE3TtbbNu3IjSdq4IjnxsW3BKLZrk4wTvoJLDfiTjA56k
# i8iokrRUw+8P2ZnX2Q==
# SIG # End signature block
