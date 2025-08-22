# Unity-Claude Safety Framework Module
# Phase 3 Week 3: Safety framework for automated fix application
# Provides confidence thresholds, dry-run capabilities, and critical file protection

# Module configuration
$script:SafetyConfig = @{
    ConfidenceThreshold = 0.7          # Minimum confidence for auto-apply
    DryRunMode = $false                 # Global dry-run flag
    CriticalPaths = @(                  # Protected paths that require higher confidence
        "*\ProjectSettings\*",
        "*\Packages\manifest.json",
        "*\.git\*",
        "*\Library\*",
        "*\UserSettings\*"
    )
    CriticalFileThreshold = 0.9        # Higher threshold for critical files
    MaxChangesPerRun = 10               # Maximum fixes to apply in one run
    BackupEnabled = $true               # Create backups before changes
    BackupPath = ".\Backups\Safety"    # Backup storage location
    LogPath = ".\Logs\safety_framework.log"
}

# Initialize module
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ModuleRoot = $modulePath

function Initialize-SafetyFramework {
    <#
    .SYNOPSIS
    Initializes the safety framework with configuration
    
    .DESCRIPTION
    Sets up the safety framework with thresholds, paths, and monitoring integration
    
    .PARAMETER ConfigPath
    Optional path to custom configuration file
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigPath = ""
    )
    
    try {
        # Create necessary directories
        if ($script:SafetyConfig.BackupEnabled) {
            if (-not (Test-Path $script:SafetyConfig.BackupPath)) {
                New-Item -ItemType Directory -Path $script:SafetyConfig.BackupPath -Force | Out-Null
                Write-Verbose "Created backup directory: $($script:SafetyConfig.BackupPath)"
            }
        }
        
        # Create log directory
        $logDir = Split-Path -Parent $script:SafetyConfig.LogPath
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Load custom configuration if provided
        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            $customConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            foreach ($key in $customConfig.PSObject.Properties.Name) {
                if ($script:SafetyConfig.ContainsKey($key)) {
                    $script:SafetyConfig[$key] = $customConfig.$key
                    Write-Verbose "Updated config: $key = $($customConfig.$key)"
                }
            }
        }
        
        # Log initialization
        Add-SafetyLog -Message "Safety Framework initialized" -Level "INFO"
        Add-SafetyLog -Message "Confidence threshold: $($script:SafetyConfig.ConfidenceThreshold)" -Level "INFO"
        Add-SafetyLog -Message "Dry-run mode: $($script:SafetyConfig.DryRunMode)" -Level "INFO"
        
        return $true
        
    } catch {
        Write-Error "Failed to initialize safety framework: $_"
        return $false
    }
}

function Test-FixSafety {
    <#
    .SYNOPSIS
    Evaluates if a fix is safe to apply based on confidence and file criticality
    
    .PARAMETER FilePath
    Path to the file being modified
    
    .PARAMETER Confidence
    Confidence score of the fix (0.0 to 1.0)
    
    .PARAMETER FixContent
    The actual fix content to be applied
    
    .PARAMETER Force
    Override safety checks (requires explicit confirmation)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [ValidateRange(0.0, 1.0)]
        [double]$Confidence,
        
        [string]$FixContent = "",
        
        [switch]$Force
    )
    
    $result = [PSCustomObject]@{
        IsSafe = $false
        Reason = ""
        RequiredConfidence = $script:SafetyConfig.ConfidenceThreshold
        ActualConfidence = $Confidence
        IsCriticalFile = $false
        RequiresBackup = $false
        Recommendations = @()
    }
    
    try {
        # Check if file exists
        if (-not (Test-Path $FilePath)) {
            $result.Reason = "File does not exist"
            $result.Recommendations += "Verify file path before applying fix"
            return $result
        }
        
        # Check if file is in critical path
        $isCritical = $false
        foreach ($criticalPath in $script:SafetyConfig.CriticalPaths) {
            if ($FilePath -like $criticalPath) {
                $isCritical = $true
                $result.IsCriticalFile = $true
                $result.RequiredConfidence = $script:SafetyConfig.CriticalFileThreshold
                break
            }
        }
        
        # Evaluate confidence threshold
        if ($isCritical) {
            if ($Confidence -lt $script:SafetyConfig.CriticalFileThreshold) {
                $result.Reason = "Confidence too low for critical file"
                $result.Recommendations += "Manual review required for critical files"
                $result.Recommendations += "Increase confidence to $($script:SafetyConfig.CriticalFileThreshold) or higher"
            } else {
                $result.IsSafe = $true
                $result.RequiresBackup = $true
                $result.Reason = "Meets critical file threshold"
            }
        } else {
            if ($Confidence -lt $script:SafetyConfig.ConfidenceThreshold) {
                $result.Reason = "Confidence below threshold"
                $result.Recommendations += "Review fix manually"
                $result.Recommendations += "Consider adjusting threshold or improving pattern matching"
            } else {
                $result.IsSafe = $true
                $result.RequiresBackup = $script:SafetyConfig.BackupEnabled
                $result.Reason = "Meets safety threshold"
            }
        }
        
        # Check for dangerous patterns in fix content
        if ($FixContent) {
            $dangerousPatterns = @(
                "Remove-Item.*-Recurse.*-Force",
                "del.*\/f.*\/s",
                "Format-Volume",
                "Clear-Content.*-Force"
            )
            
            foreach ($pattern in $dangerousPatterns) {
                if ($FixContent -match $pattern) {
                    $result.IsSafe = $false
                    $result.Reason = "Dangerous operation detected"
                    $result.Recommendations += "Manual review required - potentially destructive operation"
                    break
                }
            }
        }
        
        # Force override
        if ($Force -and -not $result.IsSafe) {
            $result.IsSafe = $true
            $result.Reason = "Safety overridden by Force parameter"
            $result.RequiresBackup = $true
            Add-SafetyLog -Message "Safety check overridden for: $FilePath" -Level "WARNING"
        }
        
        # Log the safety check
        $logMessage = "Safety check for $FilePath - Safe: $($result.IsSafe), Confidence: $Confidence"
        Add-SafetyLog -Message $logMessage -Level $(if ($result.IsSafe) { "INFO" } else { "WARNING" })
        
        return $result
        
    } catch {
        Write-Error "Safety check failed: $_"
        $result.IsSafe = $false
        $result.Reason = "Safety check error: $_"
        return $result
    }
}

function Invoke-SafetyBackup {
    <#
    .SYNOPSIS
    Creates a backup of a file before modification
    
    .PARAMETER FilePath
    Path to the file to backup
    
    .PARAMETER BackupReason
    Optional reason for the backup
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [string]$BackupReason = "Pre-modification backup"
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Warning "Cannot backup non-existent file: $FilePath"
            return $null
        }
        
        # Create timestamped backup
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = Split-Path -Leaf $FilePath
        $backupName = "${timestamp}_${fileName}"
        $backupFullPath = Join-Path $script:SafetyConfig.BackupPath $backupName
        
        # Copy file to backup location
        Copy-Item -Path $FilePath -Destination $backupFullPath -Force
        
        # Create backup metadata
        $metadata = @{
            OriginalPath = $FilePath
            BackupPath = $backupFullPath
            Timestamp = $timestamp
            Reason = $BackupReason
            FileHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
        }
        
        $metadataPath = "${backupFullPath}.json"
        $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $metadataPath
        
        Add-SafetyLog -Message "Backup created: $backupFullPath" -Level "INFO"
        
        return $backupFullPath
        
    } catch {
        Write-Error "Backup failed: $_"
        Add-SafetyLog -Message "Backup failed for $FilePath : $_" -Level "ERROR"
        return $null
    }
}

function Invoke-DryRun {
    <#
    .SYNOPSIS
    Performs a dry-run of fixes without applying them
    
    .PARAMETER Fixes
    Array of fix objects to preview
    
    .PARAMETER OutputFormat
    Format for dry-run output (Console, JSON, HTML)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Fixes,
        
        [ValidateSet("Console", "JSON", "HTML")]
        [string]$OutputFormat = "Console"
    )
    
    $dryRunResults = @()
    
    foreach ($fix in $Fixes) {
        # Validate fix object structure
        if (-not ($fix.FilePath -and $fix.FixContent -and $fix.Confidence)) {
            Write-Warning "Invalid fix object structure"
            continue
        }
        
        # Test safety
        $safetyCheck = Test-FixSafety -FilePath $fix.FilePath -Confidence $fix.Confidence -FixContent $fix.FixContent
        
        # Create preview
        $preview = [PSCustomObject]@{
            FilePath = $fix.FilePath
            FixDescription = if ($fix.Description) { $fix.Description } else { "No description" }
            Confidence = $fix.Confidence
            WouldApply = $safetyCheck.IsSafe
            SafetyReason = $safetyCheck.Reason
            RequiresBackup = $safetyCheck.RequiresBackup
            IsCriticalFile = $safetyCheck.IsCriticalFile
            Recommendations = $safetyCheck.Recommendations
            FixPreview = if ($fix.FixContent.Length -gt 200) { 
                $fix.FixContent.Substring(0, 200) + "..." 
            } else { 
                $fix.FixContent 
            }
        }
        
        $dryRunResults += $preview
    }
    
    # Output results based on format
    switch ($OutputFormat) {
        "Console" {
            Write-Host "`n=== DRY RUN RESULTS ===" -ForegroundColor Yellow
            Write-Host "Total fixes evaluated: $($dryRunResults.Count)" -ForegroundColor Cyan
            Write-Host "Would apply: $(@($dryRunResults | Where-Object { $_.WouldApply }).Count)" -ForegroundColor Green
            Write-Host "Would skip: $(@($dryRunResults | Where-Object { -not $_.WouldApply }).Count)" -ForegroundColor Red
            Write-Host ""
            
            foreach ($result in $dryRunResults) {
                $color = if ($result.WouldApply) { "Green" } else { "Red" }
                $status = if ($result.WouldApply) { 'APPLY' } else { 'SKIP' }
                Write-Host "[$status] $($result.FilePath)" -ForegroundColor $color
                Write-Host "  Confidence: $($result.Confidence) | Critical: $($result.IsCriticalFile)" -ForegroundColor Gray
                Write-Host "  Reason: $($result.SafetyReason)" -ForegroundColor Gray
                if ($result.Recommendations.Count -gt 0) {
                    Write-Host "  Recommendations:" -ForegroundColor Yellow
                    $result.Recommendations | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
                }
                Write-Host ""
            }
        }
        
        "JSON" {
            $dryRunResults | ConvertTo-Json -Depth 10
        }
        
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Dry Run Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .apply { background-color: #d4edda; }
        .skip { background-color: #f8d7da; }
        .critical { font-weight: bold; color: #721c24; }
    </style>
</head>
<body>
    <h2>Dry Run Results</h2>
    <p>Total: $($dryRunResults.Count) | Would Apply: $(($dryRunResults | Where-Object { $_.WouldApply }).Count)</p>
    <table>
        <tr>
            <th>File</th>
            <th>Confidence</th>
            <th>Would Apply</th>
            <th>Reason</th>
            <th>Critical</th>
        </tr>
"@
            foreach ($result in $dryRunResults) {
                $rowClass = if ($result.WouldApply) { "apply" } else { "skip" }
                $criticalClass = if ($result.IsCriticalFile) { "critical" } else { "" }
                $html += @"
        <tr class='$rowClass'>
            <td>$($result.FilePath)</td>
            <td>$($result.Confidence)</td>
            <td>$($result.WouldApply)</td>
            <td>$($result.SafetyReason)</td>
            <td class='$criticalClass'>$($result.IsCriticalFile)</td>
        </tr>
"@
            }
            $html += @"
    </table>
</body>
</html>
"@
            $htmlPath = Join-Path (Split-Path $script:SafetyConfig.LogPath) "dryrun_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
            $html | Set-Content -Path $htmlPath
            Write-Host "HTML report saved to: $htmlPath" -ForegroundColor Green
            return $htmlPath
        }
    }
    
    Add-SafetyLog -Message "Dry run completed: $($dryRunResults.Count) fixes evaluated" -Level "INFO"
    
    return @($dryRunResults)
}

function Set-SafetyConfiguration {
    <#
    .SYNOPSIS
    Updates safety framework configuration
    
    .PARAMETER ConfidenceThreshold
    New confidence threshold for auto-apply
    
    .PARAMETER DryRunMode
    Enable/disable global dry-run mode
    
    .PARAMETER MaxChangesPerRun
    Maximum number of changes to apply in one run
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(0.0, 1.0)]
        [double]$ConfidenceThreshold,
        
        [bool]$DryRunMode,
        
        [ValidateRange(1, 100)]
        [int]$MaxChangesPerRun,
        
        [bool]$BackupEnabled
    )
    
    if ($PSBoundParameters.ContainsKey('ConfidenceThreshold')) {
        $script:SafetyConfig.ConfidenceThreshold = $ConfidenceThreshold
        Write-Verbose "Updated confidence threshold: $ConfidenceThreshold"
    }
    
    if ($PSBoundParameters.ContainsKey('DryRunMode')) {
        $script:SafetyConfig.DryRunMode = $DryRunMode
        Write-Verbose "Updated dry-run mode: $DryRunMode"
    }
    
    if ($PSBoundParameters.ContainsKey('MaxChangesPerRun')) {
        Write-Verbose "DEBUG: Setting MaxChangesPerRun from $($script:SafetyConfig.MaxChangesPerRun) to $MaxChangesPerRun"
        $script:SafetyConfig.MaxChangesPerRun = $MaxChangesPerRun
        Write-Verbose "DEBUG: MaxChangesPerRun set to $($script:SafetyConfig.MaxChangesPerRun)"
        Write-Verbose "Updated max changes per run: $MaxChangesPerRun"
    }
    
    if ($PSBoundParameters.ContainsKey('BackupEnabled')) {
        $script:SafetyConfig.BackupEnabled = $BackupEnabled
        Write-Verbose "Updated backup enabled: $BackupEnabled"
    }
    
    Add-SafetyLog -Message "Configuration updated" -Level "INFO"
    
    return $script:SafetyConfig
}

function Get-SafetyConfiguration {
    <#
    .SYNOPSIS
    Returns current safety framework configuration
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "DEBUG: Get-SafetyConfiguration returning MaxChangesPerRun = $($script:SafetyConfig.MaxChangesPerRun)"
    return $script:SafetyConfig
}

function Test-CriticalFile {
    <#
    .SYNOPSIS
    Checks if a file is in a critical path
    
    .PARAMETER FilePath
    Path to check
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    foreach ($criticalPath in $script:SafetyConfig.CriticalPaths) {
        if ($FilePath -like $criticalPath) {
            return $true
        }
    }
    
    return $false
}

function Add-SafetyLog {
    <#
    .SYNOPSIS
    Adds an entry to the safety framework log
    
    .PARAMETER Message
    Log message
    
    .PARAMETER Level
    Log level (INFO, WARNING, ERROR)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $script:SafetyConfig.LogPath -Value $logEntry -Force
    } catch {
        Write-Warning "Failed to write to log: $_"
    }
}

function Invoke-SafeFixApplication {
    <#
    .SYNOPSIS
    Applies fixes with full safety checks and monitoring integration
    
    .PARAMETER Fixes
    Array of fixes to apply
    
    .PARAMETER DryRun
    Perform dry-run only
    
    .PARAMETER SkipBackup
    Skip backup creation (not recommended)
    
    .PARAMETER MonitoringCallback
    Script block to call for monitoring integration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Fixes,
        
        [switch]$DryRun,
        
        [switch]$SkipBackup,
        
        [scriptblock]$MonitoringCallback
    )
    
    $results = @{
        Total = $Fixes.Count
        Applied = 0
        Skipped = 0
        Failed = 0
        Backups = @()
        Details = @()
    }
    
    # Check global dry-run mode
    if ($script:SafetyConfig.DryRunMode -or $DryRun) {
        Write-Host "Running in DRY-RUN mode" -ForegroundColor Yellow
        $dryRunResult = Invoke-DryRun -Fixes $Fixes -OutputFormat "Console"
        Write-Verbose "DEBUG: DryRun result type: $($dryRunResult.GetType().Name), IsArray: $($dryRunResult -is [array])"
        # Multiple defensive approaches for array return
        if ($dryRunResult -is [array]) {
            return ,$dryRunResult  # Unary comma for arrays
        } else {
            return ,@($dryRunResult)  # Force array wrap then unary comma
        }
    }
    
    # Apply fixes with safety checks
    $appliedCount = 0
    foreach ($fix in $Fixes) {
        # Check max changes limit
        if ($appliedCount -ge $script:SafetyConfig.MaxChangesPerRun) {
            Write-Warning "Reached maximum changes per run limit ($($script:SafetyConfig.MaxChangesPerRun))"
            $results.Skipped += ($Fixes.Count - $appliedCount)
            break
        }
        
        # Safety check
        $safetyCheck = Test-FixSafety -FilePath $fix.FilePath -Confidence $fix.Confidence -FixContent $fix.FixContent
        
        $fixResult = [PSCustomObject]@{
            FilePath = $fix.FilePath
            Applied = $false
            Reason = ""
            BackupPath = $null
            Error = $null
        }
        
        if ($safetyCheck.IsSafe) {
            try {
                # Create backup if required
                if ($safetyCheck.RequiresBackup -and -not $SkipBackup) {
                    $backupPath = Invoke-SafetyBackup -FilePath $fix.FilePath -BackupReason "Auto-fix application"
                    $fixResult.BackupPath = $backupPath
                    $results.Backups += $backupPath
                }
                
                # Apply the fix (implementation depends on fix type)
                # This is a placeholder - actual implementation would depend on your fix structure
                if ($fix.ApplyMethod) {
                    & $fix.ApplyMethod
                } else {
                    # Default: assume fix content should replace file content
                    Set-Content -Path $fix.FilePath -Value $fix.FixContent -Force
                }
                
                $fixResult.Applied = $true
                $fixResult.Reason = "Fix applied successfully"
                $results.Applied++
                $appliedCount++
                
                # Call monitoring callback if provided
                if ($MonitoringCallback) {
                    & $MonitoringCallback -FixResult $fixResult
                }
                
                Add-SafetyLog -Message "Fix applied: $($fix.FilePath)" -Level "INFO"
                
            } catch {
                $fixResult.Applied = $false
                $fixResult.Reason = "Application failed"
                $fixResult.Error = $_.Exception.Message
                $results.Failed++
                
                Add-SafetyLog -Message "Fix failed: $($fix.FilePath) - $_" -Level "ERROR"
            }
        } else {
            $fixResult.Applied = $false
            $fixResult.Reason = $safetyCheck.Reason
            $results.Skipped++
            
            Add-SafetyLog -Message "Fix skipped: $($fix.FilePath) - $($safetyCheck.Reason)" -Level "WARNING"
        }
        
        $results.Details += $fixResult
    }
    
    # Summary
    Write-Host "`n=== SAFETY FRAMEWORK RESULTS ===" -ForegroundColor Cyan
    Write-Host "Total fixes: $($results.Total)" -ForegroundColor White
    Write-Host "Applied: $($results.Applied)" -ForegroundColor Green
    Write-Host "Skipped: $($results.Skipped)" -ForegroundColor Yellow
    Write-Host "Failed: $($results.Failed)" -ForegroundColor Red
    Write-Host "Backups created: $($results.Backups.Count)" -ForegroundColor Blue
    
    return $results
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-SafetyFramework',
    'Test-FixSafety',
    'Invoke-SafetyBackup',
    'Invoke-DryRun',
    'Set-SafetyConfiguration',
    'Get-SafetyConfiguration',
    'Test-CriticalFile',
    'Add-SafetyLog',
    'Invoke-SafeFixApplication'
)

# Initialize on module load
Initialize-SafetyFramework

Write-Host "Unity-Claude-Safety module loaded - Phase 3 Week 3 Safety Framework" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqI4fS5lJ7WzFDZppQFzliJgL
# QL+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8uet0f9gYb56n63v9SDat0vkthswDQYJKoZIhvcNAQEBBQAEggEAEX/f
# kbv736HEEcJc5whQcmXEflzRhNIre8aC8vOe124Qm/sTzEvrmGeyX1p2DEKiVf2K
# BCxws5uo24Q8i8bFIaEfANJc/30OH1BRLlQaFitFZ21EfYOk07jccVS7NSeOq0CI
# 8rH9g8AcEtjY+Ky408LPwjS7ty62Odg9vJtpdkP4oOwWkcu05t4Wgit27o+L2eZH
# EtHtKpkPsNAY6+OXjge18iUgNR28kl97ZteF0W6f9VV6fC9kO2ay+bgg8kwB/drR
# jqsrK+Oswka6qdPyv1E6lWYaernbR/ikuWF8OMXRBj2+9wVb95RGt9Y4gXgaI+er
# vQ/EM+Y4aySmzkU0iw==
# SIG # End signature block
