# Start-EnhancedDashboard.ps1
# Day 19: Enhanced Real-Time Dashboard with Configuration Integration
# Provides comprehensive monitoring with live data updates


# PowerShell 7 Self-Elevation

param(
    [int]$Port = 8081,
    [int]$RefreshInterval = 5,  # seconds (faster for real-time)

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

[switch]$OpenBrowser,
    [ValidateSet("development", "production", "test")]
    [string]$Environment = "development"
)

Write-Host "=== Unity-Claude Enhanced Real-Time Dashboard ===" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Loading modules and configuration..." -ForegroundColor Cyan

# Import required modules
try {
    # Try to import UniversalDashboard.Community from known location first
    $udPath = "C:\Users\georg\Documents\WindowsPowerShell\Modules\UniversalDashboard.Community\2.9.0\UniversalDashboard.Community.psd1"
    if (Test-Path $udPath) {
        Import-Module $udPath -ErrorAction Stop
    } else {
        Import-Module UniversalDashboard.Community -ErrorAction Stop
    }
    Import-Module (Join-Path $PSScriptRoot "Unity-Claude-Configuration.psm1") -Force
    Import-Module (Join-Path $PSScriptRoot "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1") -Force -DisableNameChecking
    
    # Fix: Use existing modules instead of non-existent Unity-Claude-Monitoring
    $SystemStatusPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
    $ParallelProcessingPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1"
    
    if (Test-Path $SystemStatusPath) {
        Import-Module $SystemStatusPath -Force -DisableNameChecking
    } else {
        Write-Warning "Unity-Claude-SystemStatus module not found, some features may be limited"
    }
    
    if (Test-Path $ParallelProcessingPath) {
        Import-Module $ParallelProcessingPath -Force -DisableNameChecking
    } else {
        Write-Warning "Unity-Claude-ParallelProcessing module not found, some features may be limited"
    }
    
    Write-Host "Modules loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load required modules: $_"
    Write-Host "Run Install-UniversalDashboard.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Load configuration
$config = Get-AutomationConfig -Environment $Environment
if (-not $config) {
    Write-Error "Failed to load configuration for environment: $Environment"
    exit 1
}

# Override port if configured
if ($config.dashboard -and $config.dashboard.port) {
    $Port = $config.dashboard.port
}

# Configure paths
$logsPath = Join-Path (Get-Location) "Logs"
$storagePath = Join-Path (Get-Location) "Storage\JSON"
$statusPath = Join-Path $storagePath "system_status.json"

Write-Host "Dashboard port: $Port" -ForegroundColor Gray
Write-Host "Refresh interval: $RefreshInterval seconds" -ForegroundColor Gray

# Define dashboard endpoints
$StatusEndpoint = New-UDEndpoint -Schedule (New-UDEndpointSchedule -Every $RefreshInterval -Second) -Endpoint {
    # Update system status
    if (Test-Path $statusPath) {
        $cache:SystemStatus = Get-Content $statusPath -Raw | ConvertFrom-Json
    }
    
    # Update Unity status
    $cache:UnityStatus = @{
        Running = (Get-Process -Name "Unity" -ErrorAction SilentlyContinue) -ne $null
        EditorLogSize = if (Test-Path "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log") {
            (Get-Item "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log").Length / 1MB
        } else { 0 }
    }
    
    # Update Claude CLI status
    $cache:ClaudeStatus = @{
        ProcessCount = (Get-Process -Name "node" -ErrorAction SilentlyContinue | 
            Where-Object { $_.MainWindowTitle -match "Claude" }).Count
        LastResponseTime = if ($cache:SystemStatus) { $cache:SystemStatus.LastResponseTime } else { "N/A" }
    }
    
    # Update memory usage
    $cache:MemoryUsage = @{
        Available = [Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024, 2)
        Total = [Math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1024, 2)
        UsedPercent = [Math]::Round((1 - ((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 
            (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize)) * 100, 2)
    }
}

# Create dashboard pages
$Pages = @(
    # Real-Time Overview
    New-UDPage -Name "Real-Time" -Icon chart_line -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Unity-Claude Real-Time System Monitor" -Content {
                    New-UDParagraph -Text "Live system status and performance metrics"
                    New-UDParagraph -Text "Environment: $Environment | Last Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                }
            }
        }
        
        # Live Status Cards
        New-UDRow {
            # Unity Status
            New-UDColumn -Size 3 {
                New-UDCard -Title "Unity Editor" -RefreshInterval $RefreshInterval -Endpoint {
                    $unityRunning = if ($cache:UnityStatus.Running) { "RUNNING" } else { "STOPPED" }
                    $bgColor = if ($cache:UnityStatus.Running) { "#4CAF50" } else { "#F44336" }
                    
                    New-UDHtml -Markup "<div style='background-color: $bgColor; color: white; padding: 10px; text-align: center;'>
                        <h2>$unityRunning</h2>
                        <p>Log Size: $([Math]::Round($cache:UnityStatus.EditorLogSize, 2)) MB</p>
                    </div>"
                }
            }
            
            # Claude CLI Status
            New-UDColumn -Size 3 {
                New-UDCard -Title "Claude CLI" -RefreshInterval $RefreshInterval -Endpoint {
                    $processCount = if ($cache:ClaudeStatus) { $cache:ClaudeStatus.ProcessCount } else { 0 }
                    $bgColor = if ($processCount -gt 0) { "#2196F3" } else { "#607D8B" }
                    
                    New-UDHtml -Markup "<div style='background-color: $bgColor; color: white; padding: 10px; text-align: center;'>
                        <h2>$processCount Process(es)</h2>
                        <p>Last Response: $($cache:ClaudeStatus.LastResponseTime)</p>
                    </div>"
                }
            }
            
            # Memory Usage
            New-UDColumn -Size 3 {
                New-UDCard -Title "Memory Usage" -RefreshInterval $RefreshInterval -Endpoint {
                    $usedPercent = if ($cache:MemoryUsage) { $cache:MemoryUsage.UsedPercent } else { 0 }
                    $bgColor = if ($usedPercent -lt 70) { "#4CAF50" } 
                              elseif ($usedPercent -lt 85) { "#FF9800" } 
                              else { "#F44336" }
                    
                    New-UDHtml -Markup "<div style='background-color: $bgColor; color: white; padding: 10px; text-align: center;'>
                        <h2>$usedPercent%</h2>
                        <p>$($cache:MemoryUsage.Available) / $($cache:MemoryUsage.Total) MB</p>
                    </div>"
                }
            }
            
            # Autonomous Status
            New-UDColumn -Size 3 {
                New-UDCard -Title "Autonomous Agent" -RefreshInterval $RefreshInterval -Endpoint {
                    $enabled = if ($config.autonomous_operation.enabled) { "ENABLED" } else { "DISABLED" }
                    $bgColor = if ($config.autonomous_operation.enabled) { "#9C27B0" } else { "#607D8B" }
                    
                    $rounds = if ($cache:SystemStatus) { $cache:SystemStatus.ConversationRound } else { 0 }
                    $maxRounds = $config.autonomous_operation.max_conversation_rounds
                    
                    New-UDHtml -Markup "<div style='background-color: $bgColor; color: white; padding: 10px; text-align: center;'>
                        <h2>$enabled</h2>
                        <p>Round: $rounds / $maxRounds</p>
                    </div>"
                }
            }
        }
        
        # Real-Time Charts
        New-UDRow {
            # Memory Usage Chart
            New-UDColumn -Size 6 {
                New-UDChart -Title "Memory Usage (Real-Time)" -Type Line -RefreshInterval $RefreshInterval -AutoRefresh -Endpoint {
                    # Store historical data
                    if (-not $cache:MemoryHistory) {
                        $cache:MemoryHistory = [System.Collections.ArrayList]::new()
                    }
                    
                    # Add current data point
                    if ($cache:MemoryUsage) {
                        $dataPoint = @{
                            Time = (Get-Date).ToString("HH:mm:ss")
                            Used = $cache:MemoryUsage.UsedPercent
                        }
                        $null = $cache:MemoryHistory.Add($dataPoint)
                        
                        # Keep only last 20 points
                        if ($cache:MemoryHistory.Count -gt 20) {
                            $cache:MemoryHistory.RemoveAt(0)
                        }
                    }
                    
                    $cache:MemoryHistory | Out-UDChartData -DataProperty "Used" -LabelProperty "Time" -BackgroundColor "#2196F3" -BorderColor "#1976D2"
                }
            }
            
            # Error Rate Chart
            New-UDColumn -Size 6 {
                New-UDChart -Title "Error Rate (Last Hour)" -Type Bar -RefreshInterval $RefreshInterval -AutoRefresh -Endpoint {
                    # Read recent errors from logs
                    $errorLog = Join-Path $logsPath "automation_errors.log"
                    $errors = @()
                    
                    if (Test-Path $errorLog) {
                        $cutoffTime = (Get-Date).AddHours(-1)
                        $recentErrors = Get-Content $errorLog -Tail 100 | Where-Object {
                            if ($_ -match '\[([\d-]+\s[\d:\.]+)\]') {
                                $timestamp = [DateTime]::Parse($matches[1])
                                $timestamp -gt $cutoffTime
                            }
                        }
                        
                        # Group by 10-minute intervals
                        $grouped = $recentErrors | Group-Object {
                            if ($_ -match '\[([\d-]+\s[\d:\.]+)\]') {
                                $timestamp = [DateTime]::Parse($matches[1])
                                $timestamp.ToString("HH:mm")
                            }
                        }
                        
                        $errors = $grouped | ForEach-Object {
                            @{
                                Time = $_.Name
                                Count = $_.Count
                            }
                        }
                    }
                    
                    if ($errors.Count -eq 0) {
                        $errors = @(@{ Time = "No Errors"; Count = 0 })
                    }
                    
                    $errors | Out-UDChartData -DataProperty "Count" -LabelProperty "Time" -BackgroundColor "#F44336" -BorderColor "#D32F2F"
                }
            }
        }
        
        # System Events Table
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Recent System Events" -Content {
                    New-UDTable -RefreshInterval $RefreshInterval -AutoRefresh -Endpoint {
                        $events = @()
                        
                        # Read recent events from various sources
                        $eventLog = Join-Path $logsPath "system_events.log"
                        if (Test-Path $eventLog) {
                            $recentEvents = Get-Content $eventLog -Tail 10 | ForEach-Object {
                                if ($_ -match '\[([\d-]+\s[\d:\.]+)\]\s+\[(\w+)\]\s+(.+)') {
                                    @{
                                        Timestamp = $matches[1]
                                        Level = $matches[2]
                                        Message = $matches[3]
                                    }
                                }
                            }
                            $events += $recentEvents
                        }
                        
                        # Add Unity compilation events
                        if ($cache:UnityStatus -and $cache:UnityStatus.Running) {
                            $events += @{
                                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                                Level = "INFO"
                                Message = "Unity Editor is running"
                            }
                        }
                        
                        # Sort by timestamp descending
                        $events | Sort-Object Timestamp -Descending | Select-Object -First 10 | Out-UDTableData -Property @("Timestamp", "Level", "Message")
                    }
                }
            }
        }
    },
    
    # Configuration Page
    New-UDPage -Name "Configuration" -Icon cog -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "System Configuration" -Content {
                    New-UDParagraph -Text "Current environment: $Environment"
                    New-UDParagraph -Text "Configuration loaded from: autonomous_config.json"
                }
            }
        }
        
        # Configuration Summary
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Configuration Summary" -Content {
                    $summary = Get-ConfigurationSummary -Environment $Environment
                    
                    if ($summary) {
                        New-UDList -Content {
                            New-UDListItem -Label "Environment" -SubTitle $summary.Environment
                            New-UDListItem -Label "Total Settings" -SubTitle $summary.Statistics.TotalSettings
                            New-UDListItem -Label "Enabled Features" -SubTitle ($summary.Statistics.EnabledFeatures -join ", ")
                            New-UDListItem -Label "Disabled Features" -SubTitle ($summary.Statistics.DisabledFeatures -join ", ")
                        }
                        
                        New-UDHeading -Size 5 -Text "Critical Settings"
                        New-UDList -Content {
                            foreach ($key in $summary.Statistics.CriticalSettings.Keys) {
                                New-UDListItem -Label $key -SubTitle $summary.Statistics.CriticalSettings[$key]
                            }
                        }
                    } else {
                        New-UDParagraph -Text "Failed to load configuration summary"
                    }
                }
            }
        }
        
        # Configuration Validation
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Configuration Validation" -Content {
                    $validation = Test-AutomationConfig -Environment $Environment
                    
                    if ($validation.Valid) {
                        New-UDAlert -Severity success -Text "Configuration is valid"
                    } else {
                        New-UDAlert -Severity error -Text "Configuration has errors"
                    }
                    
                    New-UDTable -Data $validation.Results -Columns @(
                        New-UDTableColumn -Property Section -Title "Section"
                        New-UDTableColumn -Property Valid -Title "Valid" -Render {
                            if ($Body.Valid) {
                                New-UDIcon -Icon check_circle -Color green
                            } else {
                                New-UDIcon -Icon error -Color red
                            }
                        }
                        New-UDTableColumn -Property Message -Title "Message"
                    )
                }
            }
        }
    },
    
    # Performance Page
    New-UDPage -Name "Performance" -Icon tachometer_alt -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Performance Metrics" -Content {
                    New-UDParagraph -Text "Real-time performance monitoring and analysis"
                }
            }
        }
        
        # Performance Gauges
        New-UDRow {
            # CPU Usage
            New-UDColumn -Size 4 {
                New-UDCard -Title "CPU Usage" -Content {
                    New-UDGauge -RefreshInterval $RefreshInterval -AutoRefresh -Endpoint {
                        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
                        [Math]::Round($cpu, 2)
                    } -MinValue 0 -MaxValue 100 -NeedleColor "#2196F3"
                }
            }
            
            # Disk I/O
            New-UDColumn -Size 4 {
                New-UDCard -Title "Disk Activity (%)" -Content {
                    New-UDGauge -RefreshInterval $RefreshInterval -AutoRefresh -Endpoint {
                        $disk = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time').CounterSamples.CookedValue
                        [Math]::Round($disk, 2)
                    } -MinValue 0 -MaxValue 100 -NeedleColor "#FF9800"
                }
            }
            
            # Network Usage
            New-UDColumn -Size 4 {
                New-UDCard -Title "Network (KB/s)" -Content {
                    New-UDGauge -RefreshInterval $RefreshInterval -AutoRefresh -Endpoint {
                        $network = Get-Counter '\Network Interface(*)\Bytes Total/sec' | 
                            Select-Object -ExpandProperty CounterSamples | 
                            Where-Object { $_.InstanceName -notmatch "isatap|teredo" } | 
                            Measure-Object -Property CookedValue -Sum
                        [Math]::Round($network.Sum / 1024, 2)
                    } -MinValue 0 -MaxValue 1000 -NeedleColor "#4CAF50"
                }
            }
        }
        
        # Process Monitoring
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Top Processes by Memory" -Content {
                    New-UDTable -RefreshInterval ($RefreshInterval * 2) -AutoRefresh -Endpoint {
                        Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object {
                            @{
                                Name = $_.ProcessName
                                PID = $_.Id
                                Memory = [Math]::Round($_.WorkingSet64 / 1MB, 2)
                                CPU = [Math]::Round($_.CPU, 2)
                            }
                        } | Out-UDTableData -Property @("Name", "PID", "Memory", "CPU")
                    }
                }
            }
        }
    }
)

# Create the dashboard
$Dashboard = New-UDDashboard -Title "Unity-Claude Real-Time Dashboard" -Pages $Pages -EndpointInitialization $StatusEndpoint

# Start the dashboard
try {
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
    exit 1
} finally {
    Stop-UDDashboard -Port $Port -ErrorAction SilentlyContinue
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5tBg5mgt2v7OEdlgUv9eYpxt
# a5GgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUn0ppqHYZ94VLmcMOEEXtta5dHEAwDQYJKoZIhvcNAQEBBQAEggEAo9dD
# JFda3p/Hk6pn+2KceYhSzk/5p4xR/2j/7frmS70AzC4aoMYR894DY4tnMryTPHOU
# 3wmn4ZNtQySCmkeMp6n9rXOwLdHehgeRiRUhsXri7z+73sJ4Q3mTXD88Vb0Hcnws
# r80y4/4+ClALrlsbeyxitt4ODZw3kidi4c46fQZyR4/k4Y5sN7CKJ6Ywu4RD5DRv
# nM7NG/yGEunmow8zbHG3BdF4fLjSc1e28fxVYMRBfnAl+wv6WusUr5pJDzD46vF6
# Tv5zEKaAoz2AgP70VVLAjOPad2l3gWUPq29W/GtrasmOhtcgBn3ZSIGXG/GXpRps
# 80QuDe6jCt5u4kzrIA==
# SIG # End signature block


