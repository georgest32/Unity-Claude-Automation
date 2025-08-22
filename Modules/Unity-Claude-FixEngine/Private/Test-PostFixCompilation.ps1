function Test-PostFixCompilation {
    <#
    .SYNOPSIS
    Verifies Unity compilation success after applying Claude's fix
    
    .DESCRIPTION
    Integrates with Unity compilation checking to verify that Claude's fix
    resolved the error and didn't introduce new compilation issues
    
    .PARAMETER FilePath
    Path to the file that was modified
    
    .PARAMETER OriginalError
    The original error message that was being fixed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [string]$OriginalError = ""
    )
    
    Write-FixEngineLog -Message "Verifying compilation after Claude fix application" -Level "INFO"
    
    $result = @{
        Success = $false
        ErrorsFound = @()
        OriginalErrorResolved = $false
        NewErrorsIntroduced = $false
        CompilationTime = 0
        Message = ""
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Step 1: Wait for Unity to process the file change
        Write-FixEngineLog -Message "Waiting for Unity to process file changes..." -Level "DEBUG"
        Start-Sleep -Seconds 3
        
        # Step 2: Trigger Unity compilation if possible
        $compilationTriggered = Invoke-UnityCompilation -FilePath $FilePath
        
        if ($compilationTriggered) {
            Write-FixEngineLog -Message "Unity compilation triggered successfully" -Level "DEBUG"
            
            # Wait for compilation to complete
            Wait-ForCompilationCompletion -TimeoutSeconds 30
        } else {
            Write-FixEngineLog -Message "Could not trigger Unity compilation automatically" -Level "WARN"
        }
        
        # Step 3: Check compilation results
        $compilationErrors = Get-CurrentCompilationErrors
        $result.ErrorsFound = $compilationErrors
        
        Write-FixEngineLog -Message "Found $($compilationErrors.Count) compilation errors after fix" -Level "DEBUG"
        
        # Step 4: Analyze results
        if ($compilationErrors.Count -eq 0) {
            $result.Success = $true
            $result.OriginalErrorResolved = $true
            $result.Message = "Compilation successful - no errors found"
            Write-FixEngineLog -Message "Compilation verification successful!" -Level "INFO"
        } else {
            # Check if original error was resolved
            $originalErrorStillExists = Test-OriginalErrorExists -Errors $compilationErrors -OriginalError $OriginalError
            $result.OriginalErrorResolved = -not $originalErrorStillExists
            
            # Check for new errors
            $result.NewErrorsIntroduced = Test-NewErrorsIntroduced -Errors $compilationErrors -FilePath $FilePath
            
            if ($result.OriginalErrorResolved -and -not $result.NewErrorsIntroduced) {
                $result.Success = $true
                $result.Message = "Original error resolved, remaining errors are unrelated"
                Write-FixEngineLog -Message "Original error resolved successfully" -Level "INFO"
            } else {
                $result.Success = $false
                $result.Message = "Compilation issues remain after fix application"
                Write-FixEngineLog -Message "Compilation verification failed: $($result.Message)" -Level "WARN"
            }
        }
        
    }
    catch {
        $result.Success = $false
        $result.Message = "Compilation verification failed: $_"
        Write-FixEngineLog -Message $result.Message -Level "ERROR"
    }
    finally {
        $stopwatch.Stop()
        $result.CompilationTime = $stopwatch.ElapsedMilliseconds
        Write-FixEngineLog -Message "Compilation verification completed in $($result.CompilationTime)ms" -Level "DEBUG"
    }
    
    return $result
}

function Invoke-UnityCompilation {
    <#
    .SYNOPSIS
    Triggers Unity compilation for the modified file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Method 1: Try to use existing rapid compilation script
        $rapidCompileScript = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Invoke-RapidUnityCompile.ps1"
        if (Test-Path $rapidCompileScript) {
            Write-FixEngineLog -Message "Using rapid Unity compilation script" -Level "DEBUG"
            & $rapidCompileScript
            return $true
        }
        
        # Method 2: Try to use force compilation script
        $forceCompileScript = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Force-UnityCompilation.ps1"
        if (Test-Path $forceCompileScript) {
            Write-FixEngineLog -Message "Using force Unity compilation script" -Level "DEBUG"
            & $forceCompileScript
            return $true
        }
        
        # Method 3: Touch the file to trigger Unity's file watcher
        Write-FixEngineLog -Message "Triggering compilation by touching file" -Level "DEBUG"
        (Get-Item $FilePath).LastWriteTime = Get-Date
        return $true
        
    }
    catch {
        Write-FixEngineLog -Message "Failed to trigger Unity compilation: $_" -Level "WARN"
        return $false
    }
}

function Wait-ForCompilationCompletion {
    <#
    .SYNOPSIS
    Waits for Unity compilation to complete
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$TimeoutSeconds = 30
    )
    
    Write-FixEngineLog -Message "Waiting for Unity compilation to complete (timeout: ${TimeoutSeconds}s)" -Level "DEBUG"
    
    $startTime = Get-Date
    $isCompiling = $true
    
    while ($isCompiling -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
        Start-Sleep -Seconds 1
        
        # Check if Unity is still compiling by looking for compilation indicators
        $isCompiling = Test-UnityCompilationInProgress
        
        if (-not $isCompiling) {
            Write-FixEngineLog -Message "Unity compilation completed" -Level "DEBUG"
            return $true
        }
    }
    
    if ($isCompiling) {
        Write-FixEngineLog -Message "Unity compilation timeout after ${TimeoutSeconds}s" -Level "WARN"
        return $false
    }
    
    return $true
}

function Test-UnityCompilationInProgress {
    <#
    .SYNOPSIS
    Checks if Unity is currently compiling
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Method 1: Check Unity Editor log for compilation messages
        $unityLogPath = "$env:LOCALAPPDATA\Unity\Editor\Editor.log"
        if (Test-Path $unityLogPath) {
            $recentLog = Get-Content -Path $unityLogPath -Tail 10 -ErrorAction SilentlyContinue
            
            # Look for compilation start/end indicators
            $compilingIndicators = @(
                "Compiling scripts",
                "Script compilation",
                "Assembly compilation"
            )
            
            $compilationFinishIndicators = @(
                "Compilation finished",
                "Finished compile",
                "Scripts have finished compiling"
            )
            
            foreach ($line in $recentLog) {
                foreach ($finishIndicator in $compilationFinishIndicators) {
                    if ($line -match $finishIndicator) {
                        return $false  # Compilation finished
                    }
                }
                
                foreach ($compilingIndicator in $compilingIndicators) {
                    if ($line -match $compilingIndicator) {
                        return $true  # Currently compiling
                    }
                }
            }
        }
        
        # Method 2: Check for Unity process activity (basic heuristic)
        $unityProcesses = Get-Process -Name "Unity" -ErrorAction SilentlyContinue
        if ($unityProcesses) {
            foreach ($process in $unityProcesses) {
                # Very basic CPU usage check
                if ($process.CPU -gt 1) {
                    return $true  # Unity appears active
                }
            }
        }
        
        # Default to not compiling if we can't determine
        return $false
    }
    catch {
        Write-FixEngineLog -Message "Failed to check Unity compilation status: $_" -Level "WARN"
        return $false
    }
}

function Get-CurrentCompilationErrors {
    <#
    .SYNOPSIS
    Gets current Unity compilation errors
    #>
    [CmdletBinding()]
    param()
    
    $errors = @()
    
    try {
        # Method 1: Try to use existing error export
        $currentErrorsFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\current_errors.json"
        if (Test-Path $currentErrorsFile) {
            $errorData = Get-Content -Path $currentErrorsFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($errorData -and $errorData.errors) {
                $errors = $errorData.errors
                Write-FixEngineLog -Message "Retrieved $($errors.Count) errors from current_errors.json" -Level "DEBUG"
                return $errors
            }
        }
        
        # Method 2: Parse Unity Editor log
        $unityLogPath = "$env:LOCALAPPDATA\Unity\Editor\Editor.log"
        if (Test-Path $unityLogPath) {
            $logContent = Get-Content -Path $unityLogPath -Tail 200 -ErrorAction SilentlyContinue
            
            foreach ($line in $logContent) {
                # Parse compilation error pattern: File(line,col): error CS####: message
                if ($line -match '^(.+?)\((\d+),(\d+)\):\s*error\s+(CS\d+):\s*(.+)$') {
                    $errors += @{
                        FilePath = $matches[1]
                        LineNumber = [int]$matches[2]
                        ColumnNumber = [int]$matches[3]
                        ErrorCode = $matches[4]
                        Message = $matches[5]
                        FullMessage = $line
                    }
                }
            }
        }
        
        # Method 3: Try to trigger error export
        if ($errors.Count -eq 0) {
            $exportScript = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Export-Tools\Export-ErrorsForClaude-Fixed.ps1"
            if (Test-Path $exportScript) {
                Write-FixEngineLog -Message "Triggering error export to get current errors" -Level "DEBUG"
                & $exportScript | Out-Null
                
                # Try reading the exported errors again
                if (Test-Path $currentErrorsFile) {
                    $errorData = Get-Content -Path $currentErrorsFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($errorData -and $errorData.errors) {
                        $errors = $errorData.errors
                    }
                }
            }
        }
        
        Write-FixEngineLog -Message "Retrieved $($errors.Count) current compilation errors" -Level "DEBUG"
        
    }
    catch {
        Write-FixEngineLog -Message "Failed to get current compilation errors: $_" -Level "WARN"
    }
    
    return $errors
}

function Test-OriginalErrorExists {
    <#
    .SYNOPSIS
    Checks if the original error still exists in current errors
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Errors,
        
        [Parameter()]
        [string]$OriginalError
    )
    
    if (-not $OriginalError) {
        return $false
    }
    
    try {
        # Extract error code from original error
        $originalErrorCode = ""
        if ($OriginalError -match '(CS\d+)') {
            $originalErrorCode = $matches[1]
        }
        
        # Look for similar error code in current errors
        foreach ($error in $Errors) {
            if ($error.ErrorCode -eq $originalErrorCode) {
                # Additional similarity check
                $originalWords = $OriginalError -split '\s+' | Where-Object { $_.Length -gt 3 }
                $currentWords = $error.Message -split '\s+' | Where-Object { $_.Length -gt 3 }
                
                $matchingWords = 0
                foreach ($word in $originalWords) {
                    if ($currentWords -contains $word) {
                        $matchingWords++
                    }
                }
                
                $similarity = if ($originalWords.Count -gt 0) { $matchingWords / $originalWords.Count } else { 0 }
                
                if ($similarity -gt 0.5) {
                    Write-FixEngineLog -Message "Original error appears to still exist (similarity: $similarity)" -Level "DEBUG"
                    return $true
                }
            }
        }
        
        Write-FixEngineLog -Message "Original error does not appear in current errors" -Level "DEBUG"
        return $false
    }
    catch {
        Write-FixEngineLog -Message "Failed to check original error existence: $_" -Level "WARN"
        return $false
    }
}

function Test-NewErrorsIntroduced {
    <#
    .SYNOPSIS
    Checks if new errors were introduced in the modified file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Errors,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $fileName = Split-Path $FilePath -Leaf
        $newErrorsInFile = 0
        
        foreach ($error in $Errors) {
            $errorFileName = Split-Path $error.FilePath -Leaf -ErrorAction SilentlyContinue
            if ($errorFileName -eq $fileName) {
                $newErrorsInFile++
            }
        }
        
        if ($newErrorsInFile -gt 0) {
            Write-FixEngineLog -Message "Found $newErrorsInFile new errors in modified file" -Level "WARN"
            return $true
        }
        
        Write-FixEngineLog -Message "No new errors introduced in modified file" -Level "DEBUG"
        return $false
    }
    catch {
        Write-FixEngineLog -Message "Failed to check for new errors: $_" -Level "WARN"
        return $false
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWJwCmXaRVEAVg2tGHhiVcJWc
# dxGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU9BX09s6RPtxOuSLOaz0XcSmLVcUwDQYJKoZIhvcNAQEBBQAEggEAXxzw
# Va9qPsn3iK3HX4nmiXram7E27JZ1cGADcdchpTZ9vmmDnyv8xqrB7ehi13rSWIYD
# UOGYTnZYv8YNMkmuquvEr+U11ZvKqy2y3rnYTa9x/3QcWB16ch6jQm4/TJkDP1w5
# kLeTExjxd9ZH3rgxV6ZsJ6+/HpQAQ2foqnXfH2PHxJXDygpjPI2jzIT4gMdI5GCI
# Onu7FwJHmgTE3kckRRZcdGJSoZXObrvTeh/pWcdN3KEaSVIAtC+t6HbCgNemCKLY
# Smzw5VEhtzpWTqyQOPy4GcSdpoMSoJ86tX0t4qfeJsVc05qNIpI8wsQrAs9uQKom
# rZsqOdjX0HlFYzGs/w==
# SIG # End signature block
