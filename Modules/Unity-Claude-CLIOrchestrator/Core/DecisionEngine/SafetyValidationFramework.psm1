# SafetyValidationFramework.psm1
# Comprehensive safety validation for DecisionEngine
# Part of Unity-Claude-CLIOrchestrator refactored architecture
# Date: 2025-08-25

#region Safety Validation Framework

# Comprehensive safety validation
function Test-SafetyValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult
    )
    
    Write-DecisionLog "Starting safety validation" "DEBUG"
    $startTime = Get-Date
    
    try {
        $safetyChecks = @()
        $overallSafe = $true
        
        # Get configuration
        $decisionConfig = Get-DecisionEngineConfiguration
        
        # Check 1: Overall confidence threshold
        $confidence = $AnalysisResult.ConfidenceAnalysis.OverallConfidence
        $minConfidence = $decisionConfig.SafetyThresholds.MinimumConfidence
        
        if ($confidence -lt $minConfidence) {
            $safetyChecks += @{
                Check = "ConfidenceThreshold"
                Result = "FAIL"
                Message = "Overall confidence ($confidence) below threshold ($minConfidence)"
                Impact = "High"
            }
            $overallSafe = $false
        } else {
            $safetyChecks += @{
                Check = "ConfidenceThreshold"
                Result = "PASS"
                Message = "Confidence level acceptable ($confidence >= $minConfidence)"
                Impact = "None"
            }
        }
        
        # Check 2: File path validation (if file operations detected)
        if ($AnalysisResult.Entities -and $AnalysisResult.Entities.FilePaths) {
            foreach ($filePath in $AnalysisResult.Entities.FilePaths) {
                # Handle both string and object formats for file paths
                $pathValue = if ($filePath -is [string]) { $filePath } else { $filePath.Value }
                $pathCheck = Test-SafeFilePath -FilePath $pathValue
                if (-not $pathCheck.IsSafe) {
                    $safetyChecks += @{
                        Check = "FilePathSafety"
                        Result = "FAIL"
                        Message = "Unsafe file path detected: $($pathCheck.Reason)"
                        Impact = "High"
                        FilePath = $pathValue
                    }
                    $overallSafe = $false
                } else {
                    $safetyChecks += @{
                        Check = "FilePathSafety"
                        Result = "PASS"
                        Message = "File path validated: $pathValue"
                        Impact = "None"
                        FilePath = $pathValue
                    }
                }
            }
        }
        
        # Check 3: Command validation (if PowerShell commands detected)
        if ($AnalysisResult.Entities -and $AnalysisResult.Entities.PowerShellCommands) {
            foreach ($command in $AnalysisResult.Entities.PowerShellCommands) {
                $cmdCheck = Test-SafeCommand -Command $command.Value
                if (-not $cmdCheck.IsSafe) {
                    $safetyChecks += @{
                        Check = "CommandSafety"
                        Result = "FAIL"
                        Message = "Unsafe command detected: $($cmdCheck.Reason)"
                        Impact = "High"
                        Command = $command.Value
                    }
                    $overallSafe = $false
                } else {
                    $safetyChecks += @{
                        Check = "CommandSafety"
                        Result = "PASS"
                        Message = "Command validated: $($command.Value)"
                        Impact = "None"
                        Command = $command.Value
                    }
                }
            }
        }
        
        # Check 4: Action queue capacity
        $queueCapacity = Test-ActionQueueCapacity
        if (-not $queueCapacity.HasCapacity) {
            $safetyChecks += @{
                Check = "QueueCapacity"
                Result = "FAIL"
                Message = "Action queue at capacity - cannot queue additional actions"
                Impact = "Medium"
            }
            $overallSafe = $false
        } else {
            $safetyChecks += @{
                Check = "QueueCapacity"
                Result = "PASS"
                Message = "Queue capacity available ($($queueCapacity.AvailableSlots) slots)"
                Impact = "None"
            }
        }
        
        $validationTime = ((Get-Date) - $startTime).TotalMilliseconds
        $targetTime = $decisionConfig.PerformanceTargets.ValidationTimeMs
        
        if ($validationTime -gt $targetTime) {
            Write-DecisionLog "Safety validation exceeded target time (${validationTime}ms > ${targetTime}ms)" "WARN"
        }
        
        $result = @{
            IsSafe = $overallSafe
            Reason = if ($overallSafe) { "All safety checks passed" } else { "One or more safety checks failed" }
            Checks = $safetyChecks
            ValidationTimeMs = $validationTime
            ChecksPassed = ($safetyChecks | Where-Object { $_.Result -eq "PASS" }).Count
            ChecksFailed = ($safetyChecks | Where-Object { $_.Result -eq "FAIL" }).Count
        }
        
        Write-DecisionLog "Safety validation completed: $($result.ChecksPassed) passed, $($result.ChecksFailed) failed (${validationTime}ms)" $(if ($overallSafe) { "SUCCESS" } else { "WARN" })
        
        return $result
        
    } catch {
        Write-DecisionLog "Safety validation error: $($_.Exception.Message)" "ERROR"
        return @{
            IsSafe = $false
            Reason = "Safety validation error: $($_.Exception.Message)"
            ValidationTimeMs = ((Get-Date) - $startTime).TotalMilliseconds
            Error = $_.Exception.ToString()
        }
    }
}

# File path safety validation
function Test-SafeFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Handle empty or null paths
        if ([string]::IsNullOrWhiteSpace($FilePath)) {
            return @{
                IsSafe = $true
                Reason = "Empty path - no safety concerns"
                Confidence = 1.0
                SafetyLevel = "High"
            }
        }
        
        # Get configuration
        $decisionConfig = Get-DecisionEngineConfiguration
        
        # Normalize path
        $normalizedPath = [System.IO.Path]::GetFullPath($FilePath)
        
        # Check blocked paths
        foreach ($blockedPath in $decisionConfig.SafetyThresholds.BlockedPaths) {
            if ($normalizedPath.StartsWith($blockedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                return @{
                    IsSafe = $false
                    Reason = "Path in blocked directory: $blockedPath"
                    NormalizedPath = $normalizedPath
                }
            }
        }
        
        # Check file extension
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
        if ($extension -and -not ($decisionConfig.SafetyThresholds.AllowedFileExtensions -contains $extension)) {
            return @{
                IsSafe = $false
                Reason = "File extension not allowed: $extension"
                NormalizedPath = $normalizedPath
            }
        }
        
        # Check file size if file exists
        if (Test-Path $normalizedPath) {
            $fileSize = (Get-Item $normalizedPath).Length
            if ($fileSize -gt $decisionConfig.SafetyThresholds.MaxFileSize) {
                return @{
                    IsSafe = $false
                    Reason = "File too large: $fileSize bytes (max: $($decisionConfig.SafetyThresholds.MaxFileSize))"
                    NormalizedPath = $normalizedPath
                }
            }
        }
        
        return @{
            IsSafe = $true
            Reason = "File path validated successfully"
            NormalizedPath = $normalizedPath
        }
        
    } catch {
        return @{
            IsSafe = $false
            Reason = "Path validation error: $($_.Exception.Message)"
            NormalizedPath = $FilePath
        }
    }
}

# Command safety validation
function Test-SafeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    # List of potentially dangerous commands/patterns
    $dangerousPatterns = @(
        'rm\s+-rf\s*/',
        'del\s+/s\s+/q',
        'Remove-Item\s+.*-Recurse.*-Force',
        'Format-Volume',
        'Restart-Computer',
        'Stop-Computer',
        'Clear-Host',
        'Clear-Content.*\*',
        'net\s+user.*password',
        'reg\s+delete',
        'schtasks.*delete',
        'wmic.*delete'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Command -match $pattern) {
            return @{
                IsSafe = $false
                Reason = "Command matches dangerous pattern: $pattern"
                Command = $Command
            }
        }
    }
    
    # Additional checks for script execution
    if ($Command -match '\.ps1|\.bat|\.cmd|\.exe') {
        # Allow test scripts (with or without full paths)
        if ($Command -match 'Test-.*\.ps1|.*Test.*\.ps1') {
            return @{
                IsSafe = $true
                Reason = "Test script execution allowed"
                Command = $Command
            }
        }
        # Allow scripts in project directory
        elseif ($Command -match 'C:\\UnityProjects\\Sound-and-Shoal\\Unity-Claude-Automation') {
            return @{
                IsSafe = $true
                Reason = "Project directory script execution allowed"
                Command = $Command
            }
        }
        else {
            return @{
                IsSafe = $false
                Reason = "Script execution outside allowed scope"
                Command = $Command
            }
        }
    }
    
    return @{
        IsSafe = $true
        Reason = "Command validated successfully"
        Command = $Command
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-SafetyValidation',
    'Test-SafeFilePath',
    'Test-SafeCommand'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDMWO8kopoxMZ6E
# HeSzmWZffkjPmZQn7ftdoskD52AKEKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDcSuHD8b+tSHTJlYY6KKkLO
# h1iXcvnU6kufn4uFXwx5MA0GCSqGSIb3DQEBAQUABIIBAJJm4QnwbDFybp9TPBtu
# Wqt3fjGMKQfFGnP4jPWT106pi9Tanni+REbbRbmJHmOwgqcMeeCNkUHIun0LCO5J
# lCi1ClLdY0tqsBgdJVERdE9hQ/5grXFomyri9Au0LWid1pk8Eybj8Wz2AepsnQMH
# +s0ljbwSR5ci/2Ol7jExzoiUU60EQEhGu4qJ+KDj64I1LOUZhyOth0JYeLYZEBPg
# z/CytrHxclsz6MsSNl0w6PAHWfv1FwmEQNszq20d7EdJBx8QXxKLjINjIBvAVYKt
# CzlNrgXD0xZV5+p9jumSYHEcuTY4RWez8NABAO8IWGdzJw7mRH9vqtA63s0fdKmW
# kKA=
# SIG # End signature block
