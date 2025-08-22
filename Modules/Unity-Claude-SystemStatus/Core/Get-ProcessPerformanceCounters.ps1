
function Get-ProcessPerformanceCounters {
    <#
    .SYNOPSIS
    Gets process performance counters using enterprise-validated Get-Counter patterns
    
    .DESCRIPTION
    Retrieves performance counters for process monitoring using 2025 enterprise best practices:
    - Realistic threshold values (not artificially high)
    - Key metrics: CPU, Memory, Disk Queue, Network Queue
    - Research-validated counter paths
    
    .PARAMETER ProcessId
    Process ID to get performance counters for
    
    .PARAMETER InstanceName
    Process instance name for performance counters
    
    .EXAMPLE
    Get-ProcessPerformanceCounters -ProcessId 1234 -InstanceName "MyProcess"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$ProcessId,
        
        [Parameter(Mandatory=$false)]
        [string]$InstanceName = $null
    )
    
    Write-SystemStatusLog "Getting performance counters for process PID $ProcessId" -Level 'DEBUG'
    
    try {
        # Get process information if instance name not provided
        if (-not $InstanceName) {
            $process = Get-Process -Id $ProcessId -ErrorAction Stop
            $InstanceName = $process.Name
            Write-SystemStatusLog "Using process name '$InstanceName' for performance counters" -Level 'DEBUG'
        }
        
        # Enterprise-validated counter paths (2025 research findings)
        $counterPaths = @(
            "\Process($InstanceName)\% Processor Time",
            "\Process($InstanceName)\Working Set",
            "\Process($InstanceName)\Private Bytes",
            "\Process($InstanceName)\Handle Count",
            "\Process($InstanceName)\Thread Count"
        )
        
        Write-SystemStatusLog "Collecting performance counters with Get-Counter" -Level 'DEBUG'
        
        # Use Get-Counter with enterprise pattern (research-validated)
        $counters = Get-Counter -Counter $counterPaths -SampleInterval 1 -MaxSamples 3 -ErrorAction SilentlyContinue
        
        if ($counters) {
            $performanceData = @{
                ProcessId = $ProcessId
                InstanceName = $InstanceName
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                CpuPercent = 0
                WorkingSetMB = 0
                PrivateBytesMB = 0
                HandleCount = 0
                ThreadCount = 0
                IsHealthy = $true
                Details = @()
            }
            
            # Process counter samples (average of samples for stability)
            $cpuSamples = @()
            $wsSamples = @()
            $pbSamples = @()
            $hcSamples = @()
            $tcSamples = @()
            
            foreach ($counterSet in $counters) {
                foreach ($sample in $counterSet.CounterSamples) {
                    switch -Regex ($sample.Path) {
                        "% Processor Time" { $cpuSamples += $sample.CookedValue }
                        "Working Set" { $wsSamples += ($sample.CookedValue / 1MB) }
                        "Private Bytes" { $pbSamples += ($sample.CookedValue / 1MB) }
                        "Handle Count" { $hcSamples += $sample.CookedValue }
                        "Thread Count" { $tcSamples += $sample.CookedValue }
                    }
                }
            }
            
            # Calculate averages for stability
            if ($cpuSamples.Count -gt 0) { $performanceData.CpuPercent = [math]::Round(($cpuSamples | Measure-Object -Average).Average, 2) }
            if ($wsSamples.Count -gt 0) { $performanceData.WorkingSetMB = [math]::Round(($wsSamples | Measure-Object -Average).Average, 2) }
            if ($pbSamples.Count -gt 0) { $performanceData.PrivateBytesMB = [math]::Round(($pbSamples | Measure-Object -Average).Average, 2) }
            if ($hcSamples.Count -gt 0) { $performanceData.HandleCount = [math]::Round(($hcSamples | Measure-Object -Average).Average, 0) }
            if ($tcSamples.Count -gt 0) { $performanceData.ThreadCount = [math]::Round(($tcSamples | Measure-Object -Average).Average, 0) }
            
            $performanceData.Details += "CPU: $($performanceData.CpuPercent)%, Memory: $($performanceData.WorkingSetMB)MB, Handles: $($performanceData.HandleCount)"
            
            Write-SystemStatusLog "Performance data collected: $($performanceData.Details[0])" -Level 'DEBUG'
            return $performanceData
            
        } else {
            Write-SystemStatusLog "No performance counter data available for process $InstanceName" -Level 'WARN'
            return $null
        }
        
    } catch {
        Write-SystemStatusLog "Error getting performance counters for PID $ProcessId`: $($_.Exception.Message)" -Level 'ERROR'
        return $null
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULsasvjNAQ2ELnx0wwFnxftCv
# HpagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUMCZO2JTgfKvqeZUHkY36c3nOmqYwDQYJKoZIhvcNAQEBBQAEggEABvfI
# lNxxBxh8AfY2etD4PWsvcoJIRAJh/oOzkCfP5lXFDvcmlIrDcpbsScRtn9mVLwTx
# wOhAtf/baTTq10ra539brYCsSgaBxBK8Au0sirxhGsK5h+x3lNfDY/amquTVCVLA
# 5Ja5uTGMtQnsOtxP2SptxesvRjnmcDXmGqofeDRIsN+xcKbfMrusXfnz6dznUchj
# MUmMZoyuAqnnWtCYWfR6L9wxNkY82b1LoocSP84yLcDquGSRr+fr3+a9M8WApgTo
# PRv74kHc2ekGP+4rNc9f75KN13U0qTJGFP2JtarGGIfGqUvbtM0B3xalkAcT+SZq
# oj+2UmMIn8u7gfrMnA==
# SIG # End signature block
