# Watch-AndReport-API.ps1
# Real-time error monitoring with Claude API integration
# TRUE BACKGROUND OPERATION - No window switching!

[CmdletBinding()]
param(
    [string]$WatchPath = (Join-Path $PSScriptRoot 'AutomationLogs'),
    [switch]$AutoSubmit,
    [int]$ErrorThreshold = 5,
    [switch]$SaveResponses,
    [string]$ResponsePath = (Join-Path $PSScriptRoot 'ClaudeAPIResponses'),
    [decimal]$MaxCostPerSession = 1.00  # Safety limit in dollars
)

Clear-Host
Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║       Unity-Claude Error Monitor (API Mode)              ║
║                                                           ║
║  ✨ TRUE BACKGROUND OPERATION via Claude API ✨          ║
║                                                           ║
║  Press Q to quit | E to export | S to submit            ║
║  Press A to toggle auto-submit (currently: $(if ($AutoSubmit) { "ON" } else { "OFF" }))          ║
║  Press C to check API status | T for token usage        ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Check API key
if (-not $env:ANTHROPIC_API_KEY) {
    Write-Host "❌ ERROR: ANTHROPIC_API_KEY not configured!" -ForegroundColor Red
    Write-Host "   Run: .\Setup-ClaudeAPI.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ API Key configured" -ForegroundColor Green
Write-Host "Monitoring: $WatchPath" -ForegroundColor Gray
Write-Host ""

# Initialize tracking variables
$script:ErrorCount = 0
$script:ErrorBuffer = @()
$script:LastExport = $null
$script:AutoSubmitEnabled = $AutoSubmit
$script:LastSubmission = $null
$script:SubmissionInProgress = $false
$script:TotalTokensUsed = @{Input = 0; Output = 0}
$script:EstimatedCost = 0
$script:SubmissionJobs = @()

# Create response directory if needed
if ($SaveResponses -and -not (Test-Path $ResponsePath)) {
    New-Item -ItemType Directory -Path $ResponsePath -Force | Out-Null
}

# Function to calculate cost
function Get-TokenCost {
    param([int]$InputTokens, [int]$OutputTokens)
    
    $inputCost = ($InputTokens / 1000000) * 3    # $3 per million
    $outputCost = ($OutputTokens / 1000000) * 15  # $15 per million
    return $inputCost + $outputCost
}

# Function to submit to Claude API
function Submit-ToClaudeAPI {
    param([string]$ExportPath)
    
    if ($script:SubmissionInProgress) {
        Write-Host "⏳ Submission already in progress..." -ForegroundColor Yellow
        return
    }
    
    # Check cost limit
    if ($script:EstimatedCost -ge $MaxCostPerSession) {
        Write-Host "⚠️  Cost limit reached (`$$MaxCostPerSession). Submissions paused." -ForegroundColor Red
        return
    }
    
    $script:SubmissionInProgress = $true
    Write-Host "`n🤖 Submitting to Claude API..." -ForegroundColor Cyan
    
    # Create a background job for API submission
    $job = Start-Job -ScriptBlock {
        param($ScriptRoot, $ExportPath, $SaveResponses, $ResponsePath, $ApiKey)
        
        $env:ANTHROPIC_API_KEY = $ApiKey
        $apiScript = Join-Path $ScriptRoot 'Submit-ErrorsToClaude-API.ps1'
        
        if (Test-Path $apiScript) {
            $params = @{
                ErrorLogPath = $ExportPath
            }
            
            if ($SaveResponses) {
                $params['SaveResponse'] = $true
            }
            
            $output = & $apiScript @params 2>&1
            
            # Parse output for token usage
            $tokenInfo = @{Input = 0; Output = 0}
            if ($output -match "Input: (\d+) tokens") {
                $tokenInfo.Input = [int]$matches[1]
            }
            if ($output -match "Output: (\d+) tokens") {
                $tokenInfo.Output = [int]$matches[1]
            }
            
            return @{
                Success = $true
                Output = $output -join "`n"
                Tokens = $tokenInfo
                Timestamp = Get-Date
            }
        } else {
            return @{
                Success = $false
                Error = "API script not found"
            }
        }
    } -ArgumentList $PSScriptRoot, $ExportPath, $SaveResponses, $ResponsePath, $env:ANTHROPIC_API_KEY
    
    $script:SubmissionJobs += $job
    
    # Register job completion event
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($Event.Sender.State -eq 'Completed') {
            $result = Receive-Job -Job $Event.Sender
            
            if ($result.Success) {
                Write-Host "`n✅ Claude API response received!" -ForegroundColor Green
                
                # Update token tracking
                if ($result.Tokens) {
                    $script:TotalTokensUsed.Input += $result.Tokens.Input
                    $script:TotalTokensUsed.Output += $result.Tokens.Output
                    
                    $cost = Get-TokenCost -InputTokens $result.Tokens.Input `
                                         -OutputTokens $result.Tokens.Output
                    $script:EstimatedCost += $cost
                    
                    Write-Host "   Tokens: In=$($result.Tokens.Input), Out=$($result.Tokens.Output)" -ForegroundColor Gray
                    Write-Host "   Cost: `$$([Math]::Round($cost, 4))" -ForegroundColor Yellow
                }
                
                # Show first few lines of response
                $lines = $result.Output -split "`n"
                $preview = ($lines | Select-Object -First 5) -join "`n"
                if ($lines.Count -gt 5) {
                    $preview += "`n   ... (see full response in saved file)"
                }
                Write-Host "   Preview: $preview" -ForegroundColor White
                
            } else {
                Write-Host "`n❌ API submission failed: $($result.Error)" -ForegroundColor Red
            }
            
            $script:SubmissionInProgress = $false
            $script:LastSubmission = $result.Timestamp
            
            # Clean up
            Remove-Job -Job $Event.Sender
            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
            Remove-Job -Id $Event.SourceIdentifier
            
            # Remove from tracking
            $script:SubmissionJobs = $script:SubmissionJobs | Where-Object { $_.Id -ne $Event.Sender.Id }
        }
    } | Out-Null
    
    Write-Host "   Job started (ID: $($job.Id))" -ForegroundColor Gray
    Write-Host "   Continuing to monitor while Claude processes..." -ForegroundColor Green
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
                    Write-Host "`n⚠️  Error threshold reached! Auto-submitting..." -ForegroundColor Magenta
                    
                    # Export errors
                    $exportScript = Join-Path $PSScriptRoot 'Export-ErrorsForClaude-Fixed.ps1'
                    if (Test-Path $exportScript) {
                        $exportPath = & $exportScript -ErrorType 'Last' `
                                                      -IncludeConsole `
                                                      -IncludeTestResults
                    } else {
                        $exportPath = Join-Path $PSScriptRoot "AutoExport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                        $script:ErrorBuffer -join "`n" | Set-Content $exportPath
                    }
                    
                    # Submit via API
                    Submit-ToClaudeAPI -ExportPath $exportPath
                    
                    $script:ErrorCount = 0
                }
            }
        }
    }
}

# Function to export errors
function Export-CurrentErrors {
    Write-Host "`nExporting errors..." -ForegroundColor Yellow
    
    $exportScript = Join-Path $PSScriptRoot 'Export-ErrorsForClaude-Fixed.ps1'
    if (Test-Path $exportScript) {
        $exportPath = & $exportScript -ErrorType 'Last' `
                                      -IncludeConsole `
                                      -IncludeTestResults
    } else {
        $exportPath = Join-Path $PSScriptRoot "ManualExport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $script:ErrorBuffer -join "`n" | Set-Content $exportPath
    }
    
    $script:LastExport = $exportPath
    Write-Host "Exported to: $exportPath" -ForegroundColor Green
    
    return $exportPath
}

# Main monitoring loop
Write-Host "Monitoring started at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green

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
                
                # Wait for pending jobs
                if ($script:SubmissionJobs.Count -gt 0) {
                    Write-Host "Waiting for pending API calls..." -ForegroundColor Yellow
                    $script:SubmissionJobs | Wait-Job -Timeout 10 | Out-Null
                }
                
                # Show session summary
                Write-Host ""
                Write-Host "═══ Session Summary ═══" -ForegroundColor Cyan
                Write-Host "Total Errors Detected: $($script:ErrorBuffer.Count)" -ForegroundColor White
                Write-Host "API Tokens Used: In=$($script:TotalTokensUsed.Input), Out=$($script:TotalTokensUsed.Output)" -ForegroundColor White
                Write-Host "Estimated Cost: `$$([Math]::Round($script:EstimatedCost, 4))" -ForegroundColor Yellow
                
                # Clean up jobs
                Get-Job | Remove-Job -Force
                
                Write-Host "Monitor stopped." -ForegroundColor Green
                exit
            }
            
            'E' {
                Export-CurrentErrors
            }
            
            'S' {
                # Manual submit to Claude API
                if (-not $script:LastExport) {
                    $exportPath = Export-CurrentErrors
                } else {
                    $exportPath = $script:LastExport
                }
                Submit-ToClaudeAPI -ExportPath $exportPath
            }
            
            'A' {
                # Toggle auto-submit
                $script:AutoSubmitEnabled = -not $script:AutoSubmitEnabled
                $status = if ($script:AutoSubmitEnabled) { 'ON' } else { 'OFF' }
                $color = if ($script:AutoSubmitEnabled) { 'Green' } else { 'Yellow' }
                Write-Host "`nAuto-submit to Claude API: $status" -ForegroundColor $color
            }
            
            'C' {
                # Check API status
                Write-Host "`n═══ API Status ═══" -ForegroundColor Cyan
                Write-Host "API Key: $(if ($env:ANTHROPIC_API_KEY) { '✅ Configured' } else { '❌ Not Set' })" -ForegroundColor White
                Write-Host "Endpoint: https://api.anthropic.com/v1/messages" -ForegroundColor Gray
                Write-Host "Model: claude-3-5-sonnet-20241022" -ForegroundColor Gray
                Write-Host "Cost Limit: `$$MaxCostPerSession" -ForegroundColor Yellow
                Write-Host "Remaining: `$$([Math]::Round($MaxCostPerSession - $script:EstimatedCost, 4))" -ForegroundColor Green
                Write-Host ""
            }
            
            'T' {
                # Show token usage
                Write-Host "`n═══ Token Usage ═══" -ForegroundColor Cyan
                Write-Host "Input Tokens: $($script:TotalTokensUsed.Input)" -ForegroundColor White
                Write-Host "Output Tokens: $($script:TotalTokensUsed.Output)" -ForegroundColor White
                Write-Host "Total Cost: `$$([Math]::Round($script:EstimatedCost, 4))" -ForegroundColor Yellow
                
                if ($script:EstimatedCost -gt 0) {
                    $avgCost = $script:EstimatedCost / ($script:TotalTokensUsed.Input + $script:TotalTokensUsed.Output) * 1000
                    Write-Host "Avg Cost/1K tokens: `$$([Math]::Round($avgCost, 4))" -ForegroundColor Gray
                }
                Write-Host ""
            }
            
            'J' {
                # Show job status
                Write-Host "`n═══ Background Jobs ═══" -ForegroundColor Cyan
                if ($script:SubmissionJobs.Count -gt 0) {
                    $script:SubmissionJobs | ForEach-Object {
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
                Write-Host "S - Submit to Claude API" -ForegroundColor White
                Write-Host "A - Toggle auto-submit" -ForegroundColor White
                Write-Host "C - Check API status" -ForegroundColor White
                Write-Host "T - Show token usage" -ForegroundColor White
                Write-Host "J - Show background jobs" -ForegroundColor White
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOyOH7BBjr940oB8NubAXDnCG
# 1y+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQaU67fwwK3ot85MensW0rX4IwuowDQYJKoZIhvcNAQEBBQAEggEAfCFF
# CoCDIr7NWwvxqlzrrW5YDAKLrClTlmwEBudolDUViPp5rCcA/z8NrxOij8DG2deY
# tCFpoeGcW4lhrldtDRqw+7oKRXQhFqZK9gpwV/dZrxnnzHTwyclIfVeRcDUOPOBG
# IM8mbULBvNmCxmxJIrZpxaSjNMhaEKCye2njr2IbhzCfV0PNTrnpw4lJGUGPkPj/
# gWacC7I/MID/6HLLAsat48a0XYp8k03TT4oygP5Wd1KY4JcVRJoxpfxHa4tPBbXa
# Hg18lAtVwsXZN5FHqXu0MpyV25drDh/6/G9NXZhWhCrRHf0I64F8JUtBy2zmsstt
# 6QT/Mu0Kee4Mes8eCw==
# SIG # End signature block
