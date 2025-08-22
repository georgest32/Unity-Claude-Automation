# Update-ClaudeCodePID.ps1
# Function to detect and update Claude Code CLI PID in system_status.json
# This should be called periodically by SystemStatusMonitoring

function Update-ClaudeCodePID {
    param(
        [string]$StatusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
    )
    
    $claudePID = $null
    $detectionMethod = "Unknown"
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    
    # Log to main automation log
    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" `
                -Value "[$timestamp] [DEBUG] [ClaudeCodePID] Starting Claude Code PID detection"
    
    try {
        # FIRST: Check if we have a PID marker file with the actual terminal PID
        $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
        if (Test-Path $markerFile) {
            $markerContent = Get-Content $markerFile
            if ($markerContent.Count -ge 2) {
                $markerPID = [int]$markerContent[1]
                # Verify this PID is still running
                $process = Get-Process -Id $markerPID -ErrorAction SilentlyContinue
                if ($process) {
                    $claudePID = $markerPID
                    $detectionMethod = "Terminal Window (from marker)"
                    Write-Host "  Found Claude Code terminal from marker: PID $claudePID" -ForegroundColor Green
                }
            }
        }
        
        # If no marker, check for Node.js processes running claude-code
        if (-not $claudePID) {
            $nodeProcesses = Get-WmiObject Win32_Process -Filter "name = 'node.exe'" | 
                Where-Object { $_.CommandLine -like "*@anthropic-ai/claude-code*" -or 
                              $_.CommandLine -like "*claude-code*cli.js*" }
            
            if ($nodeProcesses) {
                $claudePID = $nodeProcesses[0].ProcessId
                $detectionMethod = "Node.js Process"
                Write-Host "  Found Claude Code via Node.js: PID $claudePID" -ForegroundColor Green
            }
        }
        
        # Method 2: Check Windows Terminal instances with specific titles
        if (-not $claudePID) {
            $terminalProcesses = Get-Process | Where-Object { 
                $_.MainWindowTitle -like "*Claude Code*" -or 
                $_.MainWindowTitle -like "*claude chat*" 
            }
            
            if ($terminalProcesses) {
                $claudePID = $terminalProcesses[0].Id
                $detectionMethod = "Window Title"
                Write-Host "  Found Claude Code via Window Title: PID $claudePID" -ForegroundColor Green
            }
        }
        
        # Method 3: Check for PowerShell processes with Claude Code in command line
        if (-not $claudePID) {
            $psProcesses = Get-WmiObject Win32_Process -Filter "name = 'powershell.exe' OR name = 'pwsh.exe'" |
                Where-Object { $_.CommandLine -like "*claude*" }
            
            if ($psProcesses) {
                $claudePID = $psProcesses[0].ProcessId
                $detectionMethod = "PowerShell Process"
                Write-Host "  Found Claude Code via PowerShell: PID $claudePID" -ForegroundColor Green
            }
        }
        
        # Update system_status.json if we found the PID
        if ($claudePID) {
            if (Test-Path $StatusFile) {
                $status = Get-Content $StatusFile -Raw | ConvertFrom-Json
                
                # Ensure SystemInfo section exists
                if (-not $status.SystemInfo) {
                    $status | Add-Member -MemberType NoteProperty -Name "SystemInfo" -Value @{} -Force
                }
                
                # ROBUST FIX: Preserve ALL existing fields to prevent JSON round-trip loss
                $existingClaudeInfo = $null
                if ($status.SystemInfo.PSObject.Properties.Name -contains 'ClaudeCodeCLI') {
                    $existingClaudeInfo = $status.SystemInfo.ClaudeCodeCLI
                }
                
                # Create complete ClaudeCodeCLI object preserving all existing fields
                $claudeInfo = [PSCustomObject]@{
                    ProcessId = $claudePID
                    DetectionMethod = $detectionMethod
                    LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                    Status = "Active"
                }
                
                # Preserve ALL existing fields from previous object
                if ($existingClaudeInfo) {
                    # Add all existing properties to new object
                    $existingClaudeInfo.PSObject.Properties | ForEach-Object {
                        $propName = $_.Name
                        $propValue = $_.Value
                        
                        # Don't overwrite the fields we're updating
                        if ($propName -notin @('ProcessId', 'DetectionMethod', 'LastDetected', 'Status')) {
                            # Add existing property to new object
                            $claudeInfo | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue -Force
                            
                            Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" `
                                        -Value "[$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'))] [DEBUG] [ClaudeCodePID] Preserved field: $propName = $propValue"
                        }
                    }
                }
                
                # Add as a property of SystemInfo using Add-Member to handle property creation
                $status.SystemInfo | Add-Member -MemberType NoteProperty -Name "ClaudeCodeCLI" -Value $claudeInfo -Force
                
                # Save the updated status
                $status | ConvertTo-Json -Depth 10 | Set-Content $StatusFile -Encoding UTF8
                
                Write-Host "  Updated system_status.json with Claude Code PID: $claudePID" -ForegroundColor Green
                return $claudePID
            }
        } else {
            Write-Host "  Claude Code CLI not detected" -ForegroundColor Yellow
            
            # Update status to show not detected
            if (Test-Path $StatusFile) {
                $status = Get-Content $StatusFile -Raw | ConvertFrom-Json
                
                if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI) {
                    $status.SystemInfo.ClaudeCodeCLI.Status = "Not Detected"
                    $status.SystemInfo.ClaudeCodeCLI.LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                    $status | ConvertTo-Json -Depth 10 | Set-Content $StatusFile -Encoding UTF8
                }
            }
        }
        
    } catch {
        Write-Host "  Error detecting Claude Code CLI: $_" -ForegroundColor Red
    }
    
    return $null
}

# Run immediately if executed directly
if ($MyInvocation.InvocationName -eq '&' -or $MyInvocation.Line -eq '') {
    Write-Host "Detecting Claude Code CLI Process..." -ForegroundColor Cyan
    $detectedPID = Update-ClaudeCodePID
    if ($detectedPID) {
        Write-Host "Claude Code CLI detected: PID $detectedPID" -ForegroundColor Green
    } else {
        Write-Host "Claude Code CLI not found" -ForegroundColor Yellow
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXrlbodM6KQGMhKrO32ySTlxi
# zP+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUbZZQO2H88IDaQAiHexw4SS9k0JQwDQYJKoZIhvcNAQEBBQAEggEAneVl
# Yb81mI84Yc9PdUZz4ecv8kvRn5nmaMWXdz6EXq3flhbmD7ayXxwRWPcKfgKdrbwe
# LQWN+zBisMgBM/lPtRWH1WAmhIPylZcfp0MWvh0qHAWlnbzktp3Kj/NMcMBZd/q1
# m0+bNV1M7ugzYv2nzhTcsKMtGrWlcCX4fcW3GVHShOCYAXYMRNGqrPEBbLyDbBjl
# OmVvqIW4VF5PrTITNZjzHgQ9miZmOZ2hh7NLVcCKpMupvcnsP090XEOZ62kplUT1
# AdLqK+L0oVfyx9oRemctRh6R7i0w6knIAwECMuwxL+jldBFvgy7gGAixVmw/tAkG
# 8fLFzS+gk8N1dLj/dg==
# SIG # End signature block
