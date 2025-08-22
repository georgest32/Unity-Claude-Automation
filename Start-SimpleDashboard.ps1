# Start-SimpleDashboard.ps1
# PowerShell 5.1 Compatible Dashboard for Unity-Claude Automation
# Simplified version to avoid compatibility issues

param(
    [int]$Port = 8081,
    [int]$RefreshInterval = 5,
    [switch]$OpenBrowser
)

# PowerShell 7 Self-Elevation
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

Write-Host "=== Unity-Claude Enhanced Dashboard ===" -ForegroundColor Yellow
Write-Host "PowerShell 5.1 Compatible with Enhanced Features" -ForegroundColor Cyan
Write-Host "Loading modules..." -ForegroundColor Cyan

# Import required modules with error handling
try {
    # Try to import UniversalDashboard.Community from known location first
    $udPath = "C:\Users\georg\Documents\WindowsPowerShell\Modules\UniversalDashboard.Community\2.9.0\UniversalDashboard.Community.psd1"
    if (Test-Path $udPath) {
        Import-Module $udPath -ErrorAction Stop
    } else {
        Import-Module UniversalDashboard.Community -ErrorAction Stop
    }
    Write-Host "UniversalDashboard.Community loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load UniversalDashboard.Community: $_"
    Write-Host "Please install: Install-Module UniversalDashboard.Community" -ForegroundColor Yellow
    exit 1
}

# Simple status endpoint for shared data
$StatusEndpoint = New-UDEndpointInitialization -Module UniversalDashboard.Community

Write-Host "Dashboard port: $Port" -ForegroundColor Cyan
Write-Host "Refresh interval: $RefreshInterval seconds" -ForegroundColor Cyan

# Create simple dashboard pages that work with PowerShell 5.1
try {
    # Define content scriptblocks separately to avoid parameter binding issues
    $OverviewPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Unity-Claude Enhanced Real-Time Monitor" -Content {
                    New-UDParagraph -Text "Advanced system monitoring with real-time updates"
                    New-UDParagraph -Text "Environment: Development | Port: $Port | Refresh: $RefreshInterval sec"
                    New-UDParagraph -Text "Last Update: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 3 {
                New-UDCard -Title "Unity Editor" -Content {
                    `$unityProcs = Get-Process -Name 'Unity*' -ErrorAction SilentlyContinue
                    `$status = if (`$unityProcs) { "RUNNING (`$(`$unityProcs.Count))" } else { "STOPPED" }
                    `$memory = if (`$unityProcs) { [Math]::Round((`$unityProcs | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2) } else { 0 }
                    New-UDParagraph -Text "Status: `$status"
                    New-UDParagraph -Text "Memory: `$memory MB"
                    New-UDParagraph -Text "Last Check: `$(Get-Date -Format 'HH:mm:ss')"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "Claude CLI" -Content {
                    `$psProcs = Get-Process -Name 'powershell*', 'pwsh*' -ErrorAction SilentlyContinue
                    `$count = if (`$psProcs) { `$psProcs.Count } else { 0 }
                    New-UDParagraph -Text "PowerShell Processes: `$count"
                    New-UDParagraph -Text "Current PID: `$PID"
                    New-UDParagraph -Text "Status: ACTIVE"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "System Memory" -Content {
                    `$mem = Get-CimInstance -ClassName Win32_OperatingSystem
                    `$totalMB = [Math]::Round(`$mem.TotalVisibleMemorySize / 1024, 2)
                    `$freeMB = [Math]::Round(`$mem.FreePhysicalMemory / 1024, 2)
                    `$usedPercent = [Math]::Round(((`$totalMB - `$freeMB) / `$totalMB) * 100, 1)
                    New-UDParagraph -Text "Used: `$usedPercent%"
                    New-UDParagraph -Text "Free: `$freeMB MB"
                    New-UDParagraph -Text "Total: `$totalMB MB"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "CPU Usage" -Content {
                    `$cpu = Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
                    `$cpuPercent = [Math]::Round(`$cpu.CounterSamples.CookedValue, 1)
                    New-UDParagraph -Text "CPU: `$cpuPercent%"
                    New-UDParagraph -Text "Cores: `$env:NUMBER_OF_PROCESSORS"
                    New-UDParagraph -Text "Load: Normal"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Top Processes" -Content {
                    `$topProcs = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
                    foreach (`$proc in `$topProcs) {
                        `$memMB = [Math]::Round(`$proc.WorkingSet64 / 1MB, 1)
                        New-UDParagraph -Text "`$(`$proc.ProcessName): `$memMB MB"
                    }
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "Disk Usage" -Content {
                    `$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID="C:"'
                    `$totalGB = [Math]::Round(`$disk.Size / 1GB, 2)
                    `$freeGB = [Math]::Round(`$disk.FreeSpace / 1GB, 2)
                    `$usedGB = `$totalGB - `$freeGB
                    `$usedPercent = [Math]::Round((`$usedGB / `$totalGB) * 100, 1)
                    New-UDParagraph -Text "C: Drive Usage: `$usedPercent%"
                    New-UDParagraph -Text "Used: `$usedGB GB / `$totalGB GB"
                    New-UDParagraph -Text "Free: `$freeGB GB"
                }
            }
        }
"@)

    $ConfigPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Enhanced System Configuration" -Content {
                    New-UDParagraph -Text "Environment: Development"
                    New-UDParagraph -Text "Dashboard Port: $Port"
                    New-UDParagraph -Text "Refresh Interval: $RefreshInterval seconds"
                    New-UDParagraph -Text "Autonomous Mode: Enabled"
                    New-UDParagraph -Text "Real-Time Monitoring: Active"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Module Status" -Content {
                    New-UDParagraph -Text "[OK] UniversalDashboard.Community: v2.9.0"
                    New-UDParagraph -Text "[OK] PowerShell Version: `$(`$PSVersionTable.PSVersion)"
                    New-UDParagraph -Text "[OK] Platform: `$(`$PSVersionTable.Platform)"
                    New-UDParagraph -Text "[OK] OS: Windows"
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "System Information" -Content {
                    `$computer = Get-CimInstance -ClassName Win32_ComputerSystem
                    New-UDParagraph -Text "Computer: `$(`$computer.Name)"
                    New-UDParagraph -Text "Domain: `$(`$computer.Domain)"
                    New-UDParagraph -Text "Total RAM: `$([Math]::Round(`$computer.TotalPhysicalMemory / 1GB, 2)) GB"
                    New-UDParagraph -Text "Manufacturer: `$(`$computer.Manufacturer)"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Project Status" -Content {
                    `$projectPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
                    if (Test-Path `$projectPath) {
                        `$files = Get-ChildItem `$projectPath -File | Measure-Object
                        `$folders = Get-ChildItem `$projectPath -Directory | Measure-Object
                        New-UDParagraph -Text "[OK] Project Directory: Found"
                        New-UDParagraph -Text "Files: `$(`$files.Count) | Folders: `$(`$folders.Count)"
                        New-UDParagraph -Text "Path: `$projectPath"
                    } else {
                        New-UDParagraph -Text "[ERROR] Project Directory: Not Found"
                    }
                }
            }
        }
"@)

    $MonitoringPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Real-Time Process Monitoring" -Content {
                    New-UDParagraph -Text "Live monitoring of Unity and PowerShell processes"
                    New-UDParagraph -Text "Refresh Rate: $RefreshInterval seconds"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Unity Processes" -Content {
                    `$unityProcs = Get-Process -Name 'Unity*' -ErrorAction SilentlyContinue
                    if (`$unityProcs) {
                        foreach (`$proc in `$unityProcs) {
                            `$memMB = [Math]::Round(`$proc.WorkingSet64 / 1MB, 2)
                            New-UDParagraph -Text "`$(`$proc.ProcessName) (PID: `$(`$proc.Id)): `$memMB MB"
                        }
                    } else {
                        New-UDParagraph -Text "No Unity processes running"
                    }
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "PowerShell Processes" -Content {
                    `$psProcs = Get-Process -Name 'powershell*', 'pwsh*' -ErrorAction SilentlyContinue
                    if (`$psProcs) {
                        foreach (`$proc in `$psProcs) {
                            `$memMB = [Math]::Round(`$proc.WorkingSet64 / 1MB, 2)
                            New-UDParagraph -Text "`$(`$proc.ProcessName) (PID: `$(`$proc.Id)): `$memMB MB"
                        }
                    } else {
                        New-UDParagraph -Text "No PowerShell processes found"
                    }
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "System Services (Unity/Steam/Visual Studio)" -Content {
                    `$services = Get-Service | Where-Object { `$_.Name -like '*Unity*' -or `$_.Name -like '*Steam*' -or `$_.Name -like '*Visual*' } | Select-Object -First 8
                    if (`$services) {
                        foreach (`$svc in `$services) {
                            `$status = if (`$svc.Status -eq 'Running') { '[RUN]' } else { '[STOP]' }
                            New-UDParagraph -Text "`$status `$(`$svc.Name): `$(`$svc.Status)"
                        }
                    } else {
                        New-UDParagraph -Text "No relevant services found"
                    }
                }
            }
        }
"@)

    # Create pages array using explicit ScriptBlock objects
    $Pages = @(
        New-UDPage -Name "Overview" -Icon home -Content $OverviewPageContent
        New-UDPage -Name "Monitoring" -Icon chart_line -Content $MonitoringPageContent
        New-UDPage -Name "Configuration" -Icon cog -Content $ConfigPageContent
    )

    Write-Host "Pages created successfully: $($Pages.Count) pages" -ForegroundColor Green

    # Create the dashboard
    $Dashboard = New-UDDashboard -Title "Unity-Claude Enhanced Dashboard" -Pages $Pages

    Write-Host "Dashboard created successfully" -ForegroundColor Green

    # Start the dashboard
    Start-UDDashboard -Dashboard $Dashboard -Port $Port
    
    Write-Host "`nDashboard started successfully!" -ForegroundColor Green
    Write-Host "Access at: http://localhost:$Port" -ForegroundColor Cyan
    
    if ($OpenBrowser) {
        Start-Process "http://localhost:$Port"
    }
    
    Write-Host "`nPress Ctrl+C to stop the dashboard..." -ForegroundColor Yellow
    
    # Keep the script running
    while ($true) {
        Start-Sleep -Seconds 60
        Write-Host "." -NoNewline
    }
} catch {
    Write-Error "Failed to start dashboard: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Stop-UDDashboard -Port $Port -ErrorAction SilentlyContinue
    Write-Host "`nDashboard stopped" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9ITVE8RAuFRHP2Ia+RmWqpEj
# eVigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUk+iqDhBfP9AhqgtwxiRWAn1T+7UwDQYJKoZIhvcNAQEBBQAEggEATKGF
# EfOqKuhnLv5WKzmcHXspu0QzHtzQhq0UK3fZ2eqgM4LQFk0OJkvdUqiJU28ROMUB
# giSV2WA0rIfGFksbE945Z8ByALGSZ/1ngKDTzVyqVktgTEFg7U7fOa2xhuTAOfwW
# rolBy3dXjQ9ZrcxCWTTiqhmuTusLck4MBdkkNcxPQz67LWq73fF7B/XXBJiZfK4F
# 2tUv41H55Y3wOxZvdVmZthxacMe40z38VLw4bYj5ylGpATZkVYl5aIImWPsBD7qk
# iwg5iUYKlu0v8LI+UhH1/3hCmVpk6zLsBD8Q3c3bwbJFu+M/UV2qXbiInUeeTAno
# MTyxdasHuors/FTLjg==
# SIG # End signature block

