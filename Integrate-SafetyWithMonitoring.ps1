# Integration script for Safety Framework with Monitoring System
# Phase 3 Week 3: Connects safety framework to existing monitoring infrastructure

param(
    [switch]$TestMode,
    [switch]$Verbose
)

Write-Host "=== Integrating Safety Framework with Monitoring System ===" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Import required modules
try {
    Import-Module './Modules/Unity-Claude-Safety/Unity-Claude-Safety.psm1' -Force -DisableNameChecking
    Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking
    Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning-Analytics.psm1' -Force -DisableNameChecking
    Write-Host "[OK] Modules loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load modules: $_"
    exit 1
}

# Configuration
$script:IntegrationConfig = @{
    MonitoringPath = "./Logs/monitoring"
    SafetyLogPath = "./Logs/safety_framework.log"
    MetricsPath = "./Storage/JSON"
    AlertThreshold = 0.5  # Alert if confidence drops below this
    AutoApplyThreshold = 0.7  # Auto-apply fixes above this confidence
    CriticalFileThreshold = 0.9  # Higher threshold for critical files
    MaxFixesPerSession = 10
    NotificationWebhook = ""  # Optional webhook for alerts
}

function Initialize-SafetyMonitoringIntegration {
    <#
    .SYNOPSIS
    Initializes the integration between safety framework and monitoring system
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nInitializing Safety-Monitoring Integration..." -ForegroundColor Cyan
    
    try {
        # Create necessary directories
        @($script:IntegrationConfig.MonitoringPath, 
          (Split-Path $script:IntegrationConfig.SafetyLogPath),
          $script:IntegrationConfig.MetricsPath) | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-Verbose "Created directory: $_"
            }
        }
        
        # Initialize safety framework with monitoring-aware config
        $safetyConfig = @{
            ConfidenceThreshold = $script:IntegrationConfig.AutoApplyThreshold
            CriticalFileThreshold = $script:IntegrationConfig.CriticalFileThreshold
            MaxChangesPerRun = $script:IntegrationConfig.MaxFixesPerSession
            LogPath = $script:IntegrationConfig.SafetyLogPath
        }
        
        Set-SafetyConfiguration @safetyConfig
        
        Write-Host "[OK] Integration initialized" -ForegroundColor Green
        Write-Host "  - Auto-apply threshold: $($script:IntegrationConfig.AutoApplyThreshold)" -ForegroundColor Gray
        Write-Host "  - Critical file threshold: $($script:IntegrationConfig.CriticalFileThreshold)" -ForegroundColor Gray
        Write-Host "  - Max fixes per session: $($script:IntegrationConfig.MaxFixesPerSession)" -ForegroundColor Gray
        
        return $true
        
    } catch {
        Write-Error "Initialization failed: $_"
        return $false
    }
}

function Watch-SafetyMetrics {
    <#
    .SYNOPSIS
    Monitors safety metrics and triggers alerts based on thresholds
    #>
    [CmdletBinding()]
    param(
        [int]$CheckIntervalSeconds = 30,
        [int]$MaxIterations = 0  # 0 = infinite
    )
    
    Write-Host "`nStarting Safety Metrics Monitoring..." -ForegroundColor Cyan
    Write-Host "Check interval: $CheckIntervalSeconds seconds" -ForegroundColor Gray
    
    $iteration = 0
    $alertCount = 0
    
    while ($true) {
        $iteration++
        
        try {
            # Get recent metrics
            $recentMetrics = Get-MetricsFromJSON -StoragePath $script:IntegrationConfig.MetricsPath -TimeRange "Last24Hours"
            
            if ($recentMetrics.Count -gt 0) {
                # Calculate current performance
                $avgConfidence = ($recentMetrics | Measure-Object -Property ConfidenceScore -Average).Average
                $successRate = ($recentMetrics | Where-Object { $_.Success }).Count / $recentMetrics.Count
                
                Write-Host "`n[Iteration $iteration] $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor White
                Write-Host "  Metrics: $($recentMetrics.Count) | Avg Confidence: $([Math]::Round($avgConfidence, 3)) | Success Rate: $([Math]::Round($successRate * 100, 1))%" -ForegroundColor Gray
                
                # Check for alerts
                if ($avgConfidence -lt $script:IntegrationConfig.AlertThreshold) {
                    $alertCount++
                    Write-Warning "ALERT: Average confidence ($([Math]::Round($avgConfidence, 3))) below threshold ($($script:IntegrationConfig.AlertThreshold))"
                    
                    # Log alert
                    Add-SafetyLog -Message "ALERT: Low confidence detected - $avgConfidence" -Level "WARNING"
                    
                    # Send notification if configured
                    if ($script:IntegrationConfig.NotificationWebhook) {
                        Send-SafetyAlert -Message "Low confidence: $avgConfidence" -Severity "Warning"
                    }
                }
                
                # Check pattern effectiveness
                $patterns = Get-AllPatternsSuccessRates -TimeRange "Last24Hours"
                $lowPerformers = $patterns | Where-Object { $_.SuccessRate -lt 0.5 }
                
                if ($lowPerformers.Count -gt 0) {
                    Write-Warning "Low performing patterns detected: $($lowPerformers.Count)"
                    $lowPerformers | ForEach-Object {
                        Write-Host "    - $($_.PatternID): $([Math]::Round($_.SuccessRate * 100, 1))% success" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "`n[Iteration $iteration] No recent metrics found" -ForegroundColor Gray
            }
            
        } catch {
            Write-Error "Monitoring error: $_"
        }
        
        # Check exit conditions
        if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) {
            Write-Host "`nMax iterations reached. Stopping monitor." -ForegroundColor Yellow
            break
        }
        
        # Wait for next check
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
    
    Write-Host "`nMonitoring Summary:" -ForegroundColor Cyan
    Write-Host "  Total iterations: $iteration" -ForegroundColor Gray
    Write-Host "  Alerts triggered: $alertCount" -ForegroundColor $(if ($alertCount -gt 0) { "Yellow" } else { "Gray" })
}

function Invoke-MonitoredFixApplication {
    <#
    .SYNOPSIS
    Applies fixes with integrated monitoring and safety checks
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Fixes,
        
        [switch]$DryRun,
        [switch]$ForceApply
    )
    
    Write-Host "`nStarting Monitored Fix Application..." -ForegroundColor Cyan
    Write-Host "Fixes to process: $($Fixes.Count)" -ForegroundColor Gray
    
    $results = @{
        TotalFixes = $Fixes.Count
        Applied = 0
        Skipped = 0
        Failed = 0
        Metrics = @()
    }
    
    # Pre-flight checks
    Write-Host "`nPerforming pre-flight safety checks..." -ForegroundColor Yellow
    
    foreach ($fix in $Fixes) {
        $startTime = Get-Date
        
        # Perform safety check
        $safetyCheck = Test-FixSafety -FilePath $fix.FilePath -Confidence $fix.Confidence -FixContent $fix.FixContent
        
        # Create metric entry
        $metric = @{
            MetricID = "FIX_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Maximum 9999)"
            PatternID = if ($fix.PatternID) { $fix.PatternID } else { "MANUAL" }
            ConfidenceScore = $fix.Confidence
            Success = $false
            ExecutionTimeMs = 0
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if ($DryRun) {
            Write-Host "`n[DRY RUN] $($fix.FilePath)" -ForegroundColor Cyan
            Write-Host "  Would Apply: $($safetyCheck.IsSafe)" -ForegroundColor $(if ($safetyCheck.IsSafe) { "Green" } else { "Red" })
            Write-Host "  Confidence: $($fix.Confidence)" -ForegroundColor Gray
            Write-Host "  Critical: $($safetyCheck.IsCriticalFile)" -ForegroundColor Gray
            $results.Skipped++
        } elseif ($safetyCheck.IsSafe -or $ForceApply) {
            try {
                Write-Host "`n[APPLYING] $($fix.FilePath)" -ForegroundColor Green
                
                # Create backup if needed
                if ($safetyCheck.RequiresBackup) {
                    $backup = Invoke-SafetyBackup -FilePath $fix.FilePath -BackupReason "Monitored fix application"
                    Write-Host "  Backup: $backup" -ForegroundColor Gray
                }
                
                # Apply the fix (placeholder - actual implementation depends on fix structure)
                if ($fix.ApplyMethod) {
                    & $fix.ApplyMethod
                } else {
                    # Default implementation
                    Set-Content -Path $fix.FilePath -Value $fix.FixContent -Force
                }
                
                $metric.Success = $true
                $results.Applied++
                
                Write-Host "  [SUCCESS] Fix applied" -ForegroundColor Green
                
            } catch {
                $metric.Success = $false
                $metric.ErrorMessage = $_.Exception.Message
                $results.Failed++
                
                Write-Host "  [FAILED] $_" -ForegroundColor Red
            }
        } else {
            Write-Host "`n[SKIPPING] $($fix.FilePath)" -ForegroundColor Yellow
            Write-Host "  Reason: $($safetyCheck.Reason)" -ForegroundColor Gray
            
            if ($safetyCheck.Recommendations.Count -gt 0) {
                Write-Host "  Recommendations:" -ForegroundColor Cyan
                $safetyCheck.Recommendations | ForEach-Object {
                    Write-Host "    - $_" -ForegroundColor Cyan
                }
            }
            
            $results.Skipped++
        }
        
        # Calculate execution time
        $metric.ExecutionTimeMs = ((Get-Date) - $startTime).TotalMilliseconds
        
        # Save metric
        Save-MetricToJSON -Metric $metric -StoragePath $script:IntegrationConfig.MetricsPath
        $results.Metrics += $metric
        
        # Log to safety framework
        $logMessage = "Fix processed: $($fix.FilePath) - Success: $($metric.Success), Time: $($metric.ExecutionTimeMs)ms"
        Add-SafetyLog -Message $logMessage -Level $(if ($metric.Success) { "INFO" } else { "WARNING" })
    }
    
    # Post-application analysis
    Write-Host "`n=== APPLICATION SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Total: $($results.TotalFixes)" -ForegroundColor White
    Write-Host "Applied: $($results.Applied)" -ForegroundColor Green
    Write-Host "Skipped: $($results.Skipped)" -ForegroundColor Yellow
    Write-Host "Failed: $($results.Failed)" -ForegroundColor Red
    
    # Calculate and report metrics
    if ($results.Metrics.Count -gt 0) {
        $avgConfidence = ($results.Metrics | Measure-Object -Property ConfidenceScore -Average).Average
        $avgTime = ($results.Metrics | Measure-Object -Property ExecutionTimeMs -Average).Average
        $successRate = ($results.Metrics | Where-Object { $_.Success }).Count / $results.Metrics.Count
        
        Write-Host "`nPerformance Metrics:" -ForegroundColor Cyan
        Write-Host "  Avg Confidence: $([Math]::Round($avgConfidence, 3))" -ForegroundColor Gray
        Write-Host "  Avg Execution: $([Math]::Round($avgTime, 0))ms" -ForegroundColor Gray
        Write-Host "  Success Rate: $([Math]::Round($successRate * 100, 1))%" -ForegroundColor Gray
    }
    
    return $results
}

function Send-SafetyAlert {
    <#
    .SYNOPSIS
    Sends alerts to configured notification channels
    #>
    [CmdletBinding()]
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Critical")]
        [string]$Severity = "Info"
    )
    
    $alert = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Severity = $Severity
        Message = $Message
        Source = "Unity-Claude Safety Framework"
    }
    
    # Log locally
    $alertPath = Join-Path $script:IntegrationConfig.MonitoringPath "alerts_$(Get-Date -Format 'yyyyMMdd').json"
    $alert | ConvertTo-Json -Compress | Add-Content -Path $alertPath
    
    # Send to webhook if configured
    if ($script:IntegrationConfig.NotificationWebhook) {
        try {
            $body = $alert | ConvertTo-Json
            Invoke-RestMethod -Uri $script:IntegrationConfig.NotificationWebhook -Method Post -Body $body -ContentType "application/json"
            Write-Verbose "Alert sent to webhook"
        } catch {
            Write-Warning "Failed to send alert to webhook: $_"
        }
    }
    
    Write-Host "Alert: [$Severity] $Message" -ForegroundColor $(
        switch ($Severity) {
            "Info" { "Cyan" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Critical" { "Magenta" }
        }
    )
}

function Get-SafetyMonitoringStatus {
    <#
    .SYNOPSIS
    Returns current status of safety monitoring integration
    #>
    [CmdletBinding()]
    param()
    
    $status = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SafetyConfig = Get-SafetyConfiguration
        IntegrationConfig = $script:IntegrationConfig
        RecentMetrics = @{}
        PatternPerformance = @()
        Alerts = @()
    }
    
    # Get recent metrics
    $metrics = Get-MetricsFromJSON -StoragePath $script:IntegrationConfig.MetricsPath -TimeRange "Last24Hours"
    if ($metrics.Count -gt 0) {
        $status.RecentMetrics = @{
            Count = $metrics.Count
            AvgConfidence = [Math]::Round(($metrics | Measure-Object -Property ConfidenceScore -Average).Average, 3)
            SuccessRate = [Math]::Round((($metrics | Where-Object { $_.Success }).Count / $metrics.Count) * 100, 1)
        }
    }
    
    # Get pattern performance
    $patterns = Get-AllPatternsSuccessRates -TimeRange "Last24Hours"
    $status.PatternPerformance = $patterns | Select-Object -First 5
    
    # Get recent alerts
    $alertFile = Join-Path $script:IntegrationConfig.MonitoringPath "alerts_$(Get-Date -Format 'yyyyMMdd').json"
    if (Test-Path $alertFile) {
        $status.Alerts = Get-Content $alertFile | ForEach-Object { $_ | ConvertFrom-Json }
    }
    
    return $status
}

# Main execution
if (-not $TestMode) {
    # Initialize integration
    if (Initialize-SafetyMonitoringIntegration) {
        Write-Host "`n=== SAFETY-MONITORING INTEGRATION ACTIVE ===" -ForegroundColor Green
        
        # Show current status
        $status = Get-SafetyMonitoringStatus
        Write-Host "`nCurrent Status:" -ForegroundColor Cyan
        Write-Host "  Safety Threshold: $($status.SafetyConfig.ConfidenceThreshold)" -ForegroundColor Gray
        Write-Host "  Dry Run Mode: $($status.SafetyConfig.DryRunMode)" -ForegroundColor Gray
        Write-Host "  Recent Metrics: $($status.RecentMetrics.Count)" -ForegroundColor Gray
        
        if ($status.RecentMetrics.Count -gt 0) {
            Write-Host "  Performance: $($status.RecentMetrics.SuccessRate)% success, $($status.RecentMetrics.AvgConfidence) avg confidence" -ForegroundColor Gray
        }
        
        Write-Host "`nIntegration ready for use!" -ForegroundColor Green
        Write-Host "Use Watch-SafetyMetrics to start monitoring" -ForegroundColor Cyan
        Write-Host "Use Invoke-MonitoredFixApplication to apply fixes with monitoring" -ForegroundColor Cyan
    }
} else {
    # Test mode - run sample monitoring
    Write-Host "`n=== RUNNING IN TEST MODE ===" -ForegroundColor Yellow
    
    Initialize-SafetyMonitoringIntegration
    
    # Create test fixes
    $testFixes = @(
        @{
            FilePath = "C:\test\high_confidence.cs"
            FixContent = "// High confidence fix"
            Confidence = 0.9
            PatternID = "TEST_HIGH"
        },
        @{
            FilePath = "C:\test\low_confidence.cs"
            FixContent = "// Low confidence fix"
            Confidence = 0.4
            PatternID = "TEST_LOW"
        }
    )
    
    # Test monitored application
    Write-Host "`nTesting monitored fix application..." -ForegroundColor Cyan
    $results = Invoke-MonitoredFixApplication -Fixes $testFixes -DryRun
    
    # Test alert
    Write-Host "`nTesting alert system..." -ForegroundColor Cyan
    Send-SafetyAlert -Message "Test alert from integration" -Severity "Info"
    
    # Show status
    Write-Host "`nFinal Status:" -ForegroundColor Cyan
    Get-SafetyMonitoringStatus | ConvertTo-Json -Depth 3 | Write-Host
}

# Export functions for use in other scripts
Export-ModuleMember -Function @(
    'Initialize-SafetyMonitoringIntegration',
    'Watch-SafetyMetrics',
    'Invoke-MonitoredFixApplication',
    'Send-SafetyAlert',
    'Get-SafetyMonitoringStatus'
) -ErrorAction SilentlyContinue
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAR35XqRrT3oy9zFpm3ZA+iNg
# MGKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSiWoJOr7o90vjQhPKAygXBB24FswDQYJKoZIhvcNAQEBBQAEggEALe9J
# EyApvfxUsxnGKIzGzntRtqwz4o2pEXPcyFrw8mLh/rYFl4+aw9DJMaBKYg+ScDa+
# TN0wXw2Mf56KVNyteirxcSINUFVU5SxQSkgB0pSM+NJyH+ydSrvj3LcAS9/cCzSU
# Xt76oLnr57aQoI4nt9ial+OjBTjMS3aZKon3fMYksbTVhaPgA5i6YgyBnK+zygrb
# AqQi4OSRKWGMKfjj+GGMv0rYHs+9zxXGamZfA1HVHso/Rg/MeOjeaRuWuBECkdVR
# 83hduKOQLEXbwTG4xFFLnedK4HMKzx3BiyKheSSXTIzaEMRtm//ucRFWu1x5m8Wx
# uEHvHNnK80pipyQImg==
# SIG # End signature block
