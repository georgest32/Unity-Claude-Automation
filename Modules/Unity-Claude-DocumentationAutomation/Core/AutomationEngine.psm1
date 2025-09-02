#region Module Header
<#
.SYNOPSIS
    Documentation Automation Engine Core Component
    
.DESCRIPTION
    Core automation engine for starting, stopping, and managing documentation automation
    workflows with status monitoring and synchronization testing.
    
.VERSION
    2.0.0
    
.AUTHOR
    Unity-Claude-Automation
#>
#endregion

#region Core Automation Functions

function Start-DocumentationAutomation {
    <#
    .SYNOPSIS
        Starts the automated documentation update system
    .DESCRIPTION
        Initializes documentation automation with configured triggers and monitoring
    .PARAMETER IntervalMinutes
        Minutes between trigger checks (default: 15)
    .PARAMETER EnableGitHubPR
        Enable automatic PR creation for doc updates
    .EXAMPLE
        Start-DocumentationAutomation -IntervalMinutes 30 -EnableGitHubPR
    #>
    [CmdletBinding()]
    param(
        [int]$IntervalMinutes = 15,
        [switch]$EnableGitHubPR,
        [switch]$PassThru
    )
    
    try {
        if ($script:DocumentationAutomationConfig.IsRunning) {
            Write-Warning "Documentation automation is already running"
            return
        }
        
        Write-Host "Starting documentation automation system..." -ForegroundColor Cyan
        
        # Initialize backup location
        if (-not (Test-Path $script:DocumentationAutomationConfig.BackupLocation)) {
            New-Item -Path $script:DocumentationAutomationConfig.BackupLocation -ItemType Directory -Force | Out-Null
        }
        
        # Start trigger monitoring
        $triggerScript = {
            param($IntervalMinutes, $EnableGitHubPR)
            
            while ($true) {
                try {
                    # Check all registered triggers
                    $triggers = Get-DocumentationTriggers
                    foreach ($trigger in $triggers) {
                        if (Test-TriggerConditions -TriggerName $trigger.Name) {
                            Write-Host "Trigger activated: $($trigger.Name)" -ForegroundColor Yellow
                            Invoke-DocumentationUpdate -TriggerName $trigger.Name -EnableGitHubPR:$EnableGitHubPR
                        }
                    }
                } catch {
                    Write-Warning "Error in trigger monitoring: $_"
                }
                
                Start-Sleep -Seconds ($IntervalMinutes * 60)
            }
        }
        
        $job = Start-Job -ScriptBlock $triggerScript -ArgumentList $IntervalMinutes, $EnableGitHubPR
        $script:TriggerJobs['MainLoop'] = $job
        
        $script:DocumentationAutomationConfig.IsRunning = $true
        $script:DocumentationAutomationConfig.TriggerInterval = $IntervalMinutes
        $script:DocumentationAutomationConfig.LastRunTime = Get-Date
        
        Write-Host "Documentation automation started successfully" -ForegroundColor Green
        Write-Host "  Interval: $IntervalMinutes minutes" -ForegroundColor Gray
        Write-Host "  GitHub PR: $EnableGitHubPR" -ForegroundColor Gray
        Write-Host "  Job ID: $($job.Id)" -ForegroundColor Gray
        
        if ($PassThru) {
            return @{
                Status = 'Running'
                JobId = $job.Id
                Interval = $IntervalMinutes
                GitHubPR = $EnableGitHubPR.IsPresent
            }
        }
        
    } catch {
        Write-Error "Failed to start documentation automation: $_"
        throw
    }
}

function Stop-DocumentationAutomation {
    <#
    .SYNOPSIS
        Stops the documentation automation system
    .DESCRIPTION
        Gracefully shuts down all automation jobs and saves state
    .EXAMPLE
        Stop-DocumentationAutomation
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not $script:DocumentationAutomationConfig.IsRunning) {
            Write-Warning "Documentation automation is not running"
            return
        }
        
        Write-Host "Stopping documentation automation..." -ForegroundColor Yellow
        
        # Stop all trigger jobs
        foreach ($jobEntry in $script:TriggerJobs.GetEnumerator()) {
            $job = $jobEntry.Value
            if ($job.State -eq 'Running') {
                Stop-Job -Job $job -PassThru | Remove-Job
                Write-Verbose "Stopped job: $($jobEntry.Key)"
            }
        }
        
        $script:TriggerJobs.Clear()
        $script:DocumentationAutomationConfig.IsRunning = $false
        
        Write-Host "Documentation automation stopped successfully" -ForegroundColor Green
        
    } catch {
        Write-Error "Error stopping documentation automation: $_"
        throw
    }
}

function Test-DocumentationSync {
    <#
    .SYNOPSIS
        Tests documentation synchronization status
    .DESCRIPTION
        Checks if documentation is synchronized with current code state
    .PARAMETER Path
        Path to check for sync status
    .EXAMPLE
        Test-DocumentationSync -Path ".\docs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string[]]$FileTypes = @('*.ps1', '*.psm1', '*.cs'),
        [switch]$Detailed
    )
    
    try {
        $results = @{
            InSync = $true
            OutOfSyncFiles = @()
            MissingDocs = @()
            OrphanedDocs = @()
            LastSync = $null
            Details = @{}
        }
        
        if (-not (Test-Path $Path)) {
            throw "Path not found: $Path"
        }
        
        Write-Verbose "Checking sync status for: $Path"
        
        # Get all source files
        $sourceFiles = Get-ChildItem -Path $Path -Include $FileTypes -Recurse -File
        
        foreach ($file in $sourceFiles) {
            $relativePath = $file.FullName.Substring($Path.Length)
            $docPath = Join-Path (Join-Path $Path "docs") "$($file.BaseName).md"
            
            if (-not (Test-Path $docPath)) {
                $results.MissingDocs += $relativePath
                $results.InSync = $false
                continue
            }
            
            # Check modification times
            $sourceTime = $file.LastWriteTime
            $docTime = (Get-Item $docPath).LastWriteTime
            
            if ($sourceTime -gt $docTime) {
                $results.OutOfSyncFiles += @{
                    File = $relativePath
                    SourceTime = $sourceTime
                    DocTime = $docTime
                    AgeDays = ([DateTime]::Now - $docTime).Days
                }
                $results.InSync = $false
            }
        }
        
        if ($Detailed) {
            $results.Details = @{
                TotalSourceFiles = $sourceFiles.Count
                TotalMissing = $results.MissingDocs.Count
                TotalOutOfSync = $results.OutOfSyncFiles.Count
                SyncPercentage = if ($sourceFiles.Count -gt 0) { 
                    [math]::Round((1 - (($results.MissingDocs.Count + $results.OutOfSyncFiles.Count) / $sourceFiles.Count)) * 100, 2) 
                } else { 100 }
            }
        }
        
        return $results
        
    } catch {
        Write-Error "Error testing documentation sync: $_"
        throw
    }
}

function Get-DocumentationStatus {
    <#
    .SYNOPSIS
        Gets current documentation automation status
    .DESCRIPTION
        Returns comprehensive status of the documentation automation system
    .EXAMPLE
        Get-DocumentationStatus
    #>
    [CmdletBinding()]
    param()
    
    try {
        $status = @{
            IsRunning = $script:DocumentationAutomationConfig.IsRunning
            LastRunTime = $script:DocumentationAutomationConfig.LastRunTime
            TriggerInterval = $script:DocumentationAutomationConfig.TriggerInterval
            ActiveJobs = @()
            ActiveTriggers = $script:DocumentationAutomationConfig.ActiveTriggers.Count
            ReviewQueueLength = $script:DocumentationAutomationConfig.ReviewQueue.Count
            PRHistoryCount = $script:DocumentationAutomationConfig.PRHistory.Count
        }
        
        # Get job status
        foreach ($jobEntry in $script:TriggerJobs.GetEnumerator()) {
            $job = $jobEntry.Value
            $status.ActiveJobs += @{
                Name = $jobEntry.Key
                Id = $job.Id
                State = $job.State
                HasMoreData = $job.HasMoreData
            }
        }
        
        return $status
        
    } catch {
        Write-Error "Error getting documentation status: $_"
        throw
    }
}

#endregion

Export-ModuleMember -Function @(
    'Start-DocumentationAutomation',
    'Stop-DocumentationAutomation', 
    'Test-DocumentationSync',
    'Get-DocumentationStatus'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjeyzyp+u77TUk
# 4yTlyHmqY67BeqX3Crab2AnFZ74B66CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPpSVIoEJJ13WGHECgUTVRF8
# 3qUomxmmHkmgSOpdnQG5MA0GCSqGSIb3DQEBAQUABIIBAI7nF7R4F09BKUal2Jsg
# J4dMZcBKAw62VJVdFKwJdrejFpoHRjZ0tCf5zcraF5LDEBS4YZvDMSJ8sjazWliT
# NppbYjCix17UKTjOcUug+Yn7CjalMFf6NhqQX/Iz/eJKuBIRAgoRnTVh1Uigk88S
# g0oUpX0NgLuttBAJaKGLx+HcXtuaDg/Sgojrg20U73BbEPsNTO9uHa+HZA3uWA9m
# GX+BGkP3wFInzo8sYXxguNyAhgDXNo2JCAia4FyP9kZm8RFvFslk0rF6c8Fi52o4
# lnmTNO1AhD571GIPUsX+x9zMwzzTN7KunC5GTBM2UA+Ol6E4prvGBRMDcvXsUcXB
# akg=
# SIG # End signature block
