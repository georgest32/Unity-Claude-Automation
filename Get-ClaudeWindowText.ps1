# Get-ClaudeWindowText.ps1
# Captures text from Claude Code CLI window using UI Automation

function Get-ClaudeWindowText {
    param(
        [int]$MaxAttempts = 10,
        [int]$DelayMs = 1000
    )
    
    Write-Host "Attempting to capture Claude Code CLI window text..." -ForegroundColor Yellow
    
    try {
        # Load UI Automation
        Add-Type -AssemblyName UIAutomationClient
        Add-Type -AssemblyName UIAutomationTypes
        
        $automation = [System.Windows.Automation.AutomationElement]
        $root = $automation::RootElement
        
        # Find Claude Code CLI window
        $condition = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::NameProperty,
            "Claude Code CLI"
        )
        
        $claudeWindow = $null
        $attempts = 0
        
        while (-not $claudeWindow -and $attempts -lt $MaxAttempts) {
            $attempts++
            Write-Host "  Attempt $attempts/$MaxAttempts..." -ForegroundColor Gray
            
            # Try to find window with various patterns
            $windows = $root.FindAll(
                [System.Windows.Automation.TreeScope]::Children,
                [System.Windows.Automation.Condition]::TrueCondition
            )
            
            foreach ($window in $windows) {
                $name = $window.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
                if ($name -like "*Claude*" -or $name -like "*claude*") {
                    $claudeWindow = $window
                    Write-Host "  Found window: $name" -ForegroundColor Green
                    break
                }
            }
            
            if (-not $claudeWindow) {
                Start-Sleep -Milliseconds $DelayMs
            }
        }
        
        if (-not $claudeWindow) {
            Write-Host "Could not find Claude Code CLI window" -ForegroundColor Red
            return $null
        }
        
        # Try to get text from the window
        Write-Host "Extracting text from window..." -ForegroundColor Yellow
        
        # Method 1: TextPattern
        $textPattern = $claudeWindow.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)
        if ($textPattern) {
            $text = $textPattern.DocumentRange.GetText(-1)
            Write-Host "✓ Captured text using TextPattern" -ForegroundColor Green
            return $text
        }
        
        # Method 2: ValuePattern
        $valuePattern = $claudeWindow.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
        if ($valuePattern) {
            $text = $valuePattern.Current.Value
            Write-Host "✓ Captured text using ValuePattern" -ForegroundColor Green
            return $text
        }
        
        # Method 3: Search for text elements
        Write-Host "Searching for text elements..." -ForegroundColor Yellow
        $textCondition = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::Text
        )
        
        $textElements = $claudeWindow.FindAll(
            [System.Windows.Automation.TreeScope]::Descendants,
            $textCondition
        )
        
        $allText = ""
        foreach ($element in $textElements) {
            $elementText = $element.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
            $allText += "$elementText`n"
        }
        
        if ($allText) {
            Write-Host "✓ Captured text from text elements" -ForegroundColor Green
            return $allText
        }
        
        Write-Host "Could not extract text from window" -ForegroundColor Red
        return $null
        
    } catch {
        Write-Host "Error capturing window text: $_" -ForegroundColor Red
        return $null
    }
}

# Alternative: Use clipboard automation
function Get-ClaudeResponseViaClipboard {
    param(
        [int]$TimeoutSeconds = 30
    )
    
    Write-Host "Using clipboard capture method..." -ForegroundColor Yellow
    Write-Host "Please select all text in Claude (Ctrl+A) and copy (Ctrl+C)" -ForegroundColor Cyan
    
    Add-Type -AssemblyName System.Windows.Forms
    
    $initialClipboard = [System.Windows.Forms.Clipboard]::GetText()
    $startTime = Get-Date
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
        $currentClipboard = [System.Windows.Forms.Clipboard]::GetText()
        
        if ($currentClipboard -ne $initialClipboard -and $currentClipboard) {
            # Check if it contains a recommendation
            if ($currentClipboard -match '\[RECOMMENDATION:.*\]') {
                Write-Host "✓ Captured Claude response with recommendation!" -ForegroundColor Green
                
                # Save to file
                $responseFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\claude_response_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                
                $responseData = @{
                    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
                    type = "claude_response"
                    response = $currentClipboard
                    captureMethod = "clipboard"
                }
                
                $responseData | ConvertTo-Json -Depth 10 | Set-Content $responseFile -Encoding UTF8
                Write-Host "Saved to: $responseFile" -ForegroundColor Green
                
                return $currentClipboard
            }
        }
        
        Start-Sleep -Milliseconds 500
        Write-Host "." -NoNewline
    }
    
    Write-Host "`nTimeout" -ForegroundColor Red
    return $null
}

# Test if running directly
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "=== Claude Window Text Capture Test ===" -ForegroundColor Cyan
    
    $text = Get-ClaudeWindowText
    if ($text) {
        Write-Host "`nCaptured text:" -ForegroundColor Green
        Write-Host $text -ForegroundColor White
    } else {
        Write-Host "`nTrying clipboard method..." -ForegroundColor Yellow
        $text = Get-ClaudeResponseViaClipboard
        if ($text) {
            Write-Host "`nCaptured via clipboard:" -ForegroundColor Green
            Write-Host $text -ForegroundColor White
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9sESoCDFPKi7in+EHIa0lp9T
# b8qgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6BQWkcOpJV1SaCKP8OPTQ8USWf8wDQYJKoZIhvcNAQEBBQAEggEAqwzq
# mi86JuHbd863RseW7nPgw72eGTQuCe7svoC0EqY27M6BEYIUDktZasNxIYjXWcvM
# lFma79N5W0qF6Hb3MfOwOGpqpxjvoiiDCzxF/xOSMYiQSFV3aCDRC3wKV6HzzMby
# GkdbchSqTgXVKrjwW97ewVSH71FTdVUfbAvK/w4GG5bL7nhN+9bW902ZdG5ujTQa
# 9l4H287eZAF7mjVc4hLU+baKSvgIP1K6w9GetmY4YnOSfujQK8lF62bbwexmFrMb
# p2Ov2pTY6uGFYs/Uu4JrXlL/87SJfsjqH9AYLaXx6O4egd5Bx5CWS7bBTh9F1UlM
# T+w1EBUghPvHKFyItg==
# SIG # End signature block
