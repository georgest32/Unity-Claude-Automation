# Unity-Claude-WindowDetection-Enhanced.psm1
# Enhanced window detection that uses system_status.json for Claude Code CLI PID

function Find-ClaudeCodeCLIWindow-Enhanced {
    <#
    .SYNOPSIS
    Finds the Claude Code CLI window using the PID from system_status.json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    Write-Host "[WindowDetection] Using enhanced detection with system_status.json..." -ForegroundColor Yellow
    
    try {
        # First, try to get the Claude Code CLI PID from system_status.json
        $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
        
        if (Test-Path $statusFile) {
            $status = Get-Content $statusFile -Raw | ConvertFrom-Json
            
            if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI -and $status.SystemInfo.ClaudeCodeCLI.ProcessId) {
                $claudePID = $status.SystemInfo.ClaudeCodeCLI.ProcessId
                Write-Host "[WindowDetection] Found Claude Code CLI PID in system_status.json: $claudePID" -ForegroundColor Green
                
                # Try to get the process by PID
                $claudeProcess = Get-Process -Id $claudePID -ErrorAction SilentlyContinue
                
                if ($claudeProcess) {
                    Write-Host "[WindowDetection] [+] Found Claude Code CLI process!" -ForegroundColor Green
                    Write-Host "  Process: $($claudeProcess.ProcessName) (PID: $claudePID)" -ForegroundColor Gray
                    
                    # Check if it's a Node.js process
                    if ($claudeProcess.ProcessName -eq "node") {
                        Write-Host "  Type: Node.js process (likely running Claude Code CLI)" -ForegroundColor Gray
                        
                        # Get the parent window (terminal hosting the Node.js process)
                        # Node.js usually doesn't have a MainWindowTitle, so we need to find its parent terminal
                        $terminals = Get-Process | Where-Object { 
                            $_.MainWindowTitle -and 
                            ($_.ProcessName -match "WindowsTerminal|powershell|pwsh|cmd|conhost")
                        }
                        
                        # Look for terminal with "claude" in the title or command line
                        $claudeTerminal = $terminals | Where-Object {
                            $_.MainWindowTitle -match "claude" -or
                            $_.MainWindowTitle -match "Claude Code"
                        } | Select-Object -First 1
                        
                        if ($claudeTerminal) {
                            Write-Host "  Found Claude terminal window: $($claudeTerminal.MainWindowTitle)" -ForegroundColor Green
                            Write-Host "  Terminal PID: $($claudeTerminal.Id)" -ForegroundColor Gray
                            
                            return @{
                                Success = $true
                                ProcessId = $claudeTerminal.Id
                                NodeProcessId = $claudePID
                                ProcessName = $claudeTerminal.ProcessName
                                WindowTitle = $claudeTerminal.MainWindowTitle
                                WindowHandle = $claudeTerminal.MainWindowHandle
                                Confidence = 100
                                DetectionMethod = "system_status.json + terminal"
                            }
                        } else {
                            # No terminal with Claude in title, return the Node.js process info
                            Write-Host "  Warning: Could not find terminal window, using Node.js process" -ForegroundColor Yellow
                            
                            return @{
                                Success = $true
                                ProcessId = $claudePID
                                NodeProcessId = $claudePID
                                ProcessName = $claudeProcess.ProcessName
                                WindowTitle = "Node.js Claude Code CLI (PID: $claudePID)"
                                WindowHandle = $claudeProcess.MainWindowHandle
                                Confidence = 90
                                DetectionMethod = "system_status.json + node"
                            }
                        }
                    } else {
                        # Not a Node.js process, but the PID from system_status.json
                        return @{
                            Success = $true
                            ProcessId = $claudePID
                            ProcessName = $claudeProcess.ProcessName
                            WindowTitle = $claudeProcess.MainWindowTitle
                            WindowHandle = $claudeProcess.MainWindowHandle
                            Confidence = 95
                            DetectionMethod = "system_status.json"
                        }
                    }
                } else {
                    Write-Host "[WindowDetection] Process with PID $claudePID not found (may have exited)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "[WindowDetection] No Claude Code CLI PID found in system_status.json" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[WindowDetection] system_status.json not found" -ForegroundColor Yellow
        }
        
        # Fallback: Look for the actual Claude Code window (not PowerShell windows)
        Write-Host "[WindowDetection] Falling back to window title search..." -ForegroundColor Yellow
        
        # Specifically look for terminals with "claude" in the title but exclude autonomous agent windows
        $claudeWindows = Get-Process | Where-Object { 
            $_.MainWindowTitle -and 
            $_.MainWindowTitle -match "claude" -and
            $_.MainWindowTitle -notmatch "Administrator.*PowerShell" -and
            $_.ProcessName -notmatch "powershell|pwsh"
        }
        
        if ($claudeWindows) {
            $window = $claudeWindows | Select-Object -First 1
            Write-Host "[WindowDetection] Found window by title: $($window.MainWindowTitle)" -ForegroundColor Green
            
            return @{
                Success = $true
                ProcessId = $window.Id
                ProcessName = $window.ProcessName
                WindowTitle = $window.MainWindowTitle
                WindowHandle = $window.MainWindowHandle
                Confidence = 70
                DetectionMethod = "title_search"
            }
        }
        
        Write-Host "[WindowDetection] No Claude Code CLI window found" -ForegroundColor Red
        return @{
            Success = $false
            Error = "Claude Code CLI window not found via PID or title search"
        }
        
    } catch {
        Write-Host "[WindowDetection] Error: $_" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Export the enhanced function
Export-ModuleMember -Function Find-ClaudeCodeCLIWindow-Enhanced
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQcUG66Ol2cCAjzW5Emn3OL//
# +uegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsdBgV58LbFwsVuXpRSoC7vsjg7wwDQYJKoZIhvcNAQEBBQAEggEAGAHY
# JfPR/CRLPulrX2EyGqdB/DMtOyig+USeSG5NTDBmqoiAy019Jd/nofJ0k7PbYgXT
# YUdf42Fsd7hfhyHsk5RJWppIEsOr8kmkBeR9w1hxVrY6woKS3CoaHm+0/O9LrM6B
# lecrwXAa+ujJgW6DCasEB2Hms+DE3pql1zuVGSyRlUxFRMm1py6hUUt0+pXi3MMZ
# Tv7z4CvmMgFwy4iK2ZYrQ14970AJkHBGD4a3IvPKcdEI1UOUu3EVPeUAvkmKYCWf
# LWnDf9/Hv9oLYlGStpkCVKtE94tfHVyzHbKt6bmh3dauGoIo7b5bzrcuNf00Xa0f
# KoENYq12iLjcFwJcyA==
# SIG # End signature block
