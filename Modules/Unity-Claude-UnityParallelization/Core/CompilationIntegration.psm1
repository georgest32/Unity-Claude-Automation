#Requires -Version 5.1
<#
.SYNOPSIS
    Unity compilation process integration for UnityParallelization module.

.DESCRIPTION
    Provides Unity compilation job execution and monitoring using batch mode
    with runspace pools and hanging prevention.

.NOTES
    Part of Unity-Claude-UnityParallelization refactored architecture
    Originally from Unity-Claude-UnityParallelization.psm1 (lines 980-1096)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\ParallelizationCore.psm1" -Force
Import-Module "$PSScriptRoot\ProjectConfiguration.psm1" -Force

#region Unity Compilation Process Integration

function Start-UnityCompilationJob {
    <#
    .SYNOPSIS
    Starts a Unity compilation job in batch mode
    .DESCRIPTION
    Executes Unity compilation in batch mode using runspace pools with hanging prevention
    .PARAMETER Monitor
    Unity monitor object
    .PARAMETER ProjectName
    Name of the Unity project to compile
    .PARAMETER CompilationMethod
    Unity method to execute for compilation
    .PARAMETER TimeoutMinutes
    Timeout for compilation job in minutes
    .EXAMPLE
    Start-UnityCompilationJob -Monitor $monitor -ProjectName "MyGame" -CompilationMethod "CompileProject"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [string]$CompilationMethod = "AssetDatabase.Refresh",
        [int]$TimeoutMinutes = 5
    )
    
    Write-UnityParallelLog -Message "Starting Unity compilation job for project '$ProjectName'..." -Level "INFO"
    
    try {
        # Get project configuration
        $projectConfig = Get-UnityProjectConfiguration -ProjectName $ProjectName
        
        # Create Unity compilation script (research-validated batch mode pattern)
        $compilationScript = {
            param($ProjectPath, $LogPath, $Method, $TimeoutMinutes)
            
            try {
                # Unity batch mode command (research pattern from queries)
                $unityPath = "C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe"
                if (-not (Test-Path $unityPath)) {
                    # Try to find Unity executable
                    $unityPath = Get-ChildItem "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" | Select-Object -First 1 -ExpandProperty FullName
                }
                
                if (-not $unityPath) {
                    throw "Unity executable not found"
                }
                
                $arguments = @(
                    "-quit"
                    "-batchmode"
                    "-projectPath", "`"$ProjectPath`""
                    "-logFile", "`"$LogPath`""
                    "-executeMethod", $Method
                )
                
                # Start Unity process with timeout (Learning #98: hanging prevention)
                $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processStartInfo.FileName = $unityPath
                $processStartInfo.Arguments = $arguments -join " "
                $processStartInfo.UseShellExecute = $false
                $processStartInfo.RedirectStandardOutput = $true
                $processStartInfo.RedirectStandardError = $true
                
                $process = [System.Diagnostics.Process]::Start($processStartInfo)
                $startTime = Get-Date
                
                # Wait for completion with timeout
                $completed = $process.WaitForExit($TimeoutMinutes * 60 * 1000) # Convert to milliseconds
                
                if ($completed) {
                    $exitCode = $process.ExitCode
                    $output = $process.StandardOutput.ReadToEnd()
                    $error = $process.StandardError.ReadToEnd()
                    
                    return @{
                        Success = $exitCode -eq 0
                        ExitCode = $exitCode
                        Output = $output
                        Error = $error
                        Duration = (Get-Date) - $startTime
                    }
                } else {
                    # Process timed out, kill it
                    try { $process.Kill() } catch { }
                    throw "Unity compilation timed out after $TimeoutMinutes minutes"
                }
                
            } catch {
                throw "Unity compilation error: $($_.Exception.Message)"
            }
        }
        
        # Submit compilation job to runspace pool
        $job = Submit-RunspaceJob -PoolManager $Monitor.RunspacePool -ScriptBlock $compilationScript -Parameters @{
            ProjectPath = $projectConfig.Path
            LogPath = $projectConfig.LogPath
            Method = $CompilationMethod
            TimeoutMinutes = $TimeoutMinutes
        } -JobName "UnityCompilation-$ProjectName" -TimeoutSeconds ($TimeoutMinutes * 60 + 60)
        
        # Track compilation job
        $Monitor.CompilationJobs += $job
        
        Write-UnityParallelLog -Message "Unity compilation job started for '$ProjectName' (JobId: $($job.JobId))" -Level "INFO"
        
        return $job
        
    } catch {
        Write-UnityParallelLog -Message "Failed to start Unity compilation job for '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Find-UnityExecutablePath {
    <#
    .SYNOPSIS
    Finds the Unity executable path on the system
    .DESCRIPTION
    Searches common Unity installation locations to find the Unity executable
    .PARAMETER PreferredVersion
    Preferred Unity version to use
    .EXAMPLE
    $unityPath = Find-UnityExecutablePath -PreferredVersion "2021.1.14f1"
    #>
    [CmdletBinding()]
    param(
        [string]$PreferredVersion = "2021.1.14f1"
    )
    
    Write-UnityParallelLog -Message "Searching for Unity executable..." -Level "DEBUG"
    
    # Check common Unity installation paths
    $searchPaths = @(
        "C:\Program Files\Unity\Hub\Editor\$PreferredVersion\Editor\Unity.exe",
        "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe",
        "C:\Program Files (x86)\Unity\Editor\Unity.exe",
        "C:\Program Files\Unity\Editor\Unity.exe"
    )
    
    foreach ($path in $searchPaths) {
        if ($path -contains '*') {
            $foundPaths = Get-ChildItem $path -ErrorAction SilentlyContinue
            if ($foundPaths) {
                $unityPath = $foundPaths | Select-Object -First 1 -ExpandProperty FullName
                Write-UnityParallelLog -Message "Found Unity executable: $unityPath" -Level "DEBUG"
                return $unityPath
            }
        } else {
            if (Test-Path $path) {
                Write-UnityParallelLog -Message "Found Unity executable: $path" -Level "DEBUG"
                return $path
            }
        }
    }
    
    Write-UnityParallelLog -Message "Unity executable not found in standard locations" -Level "WARNING"
    return $null
}

function Test-UnityCompilationResult {
    <#
    .SYNOPSIS
    Tests Unity compilation job result for success
    .DESCRIPTION
    Analyzes Unity compilation job result to determine if compilation succeeded
    .PARAMETER JobResult
    Result from Unity compilation job
    .EXAMPLE
    $success = Test-UnityCompilationResult -JobResult $job
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$JobResult
    )
    
    try {
        # Check if job completed successfully
        if (-not $JobResult) {
            return @{
                Success = $false
                Reason = "No job result available"
            }
        }
        
        # Check exit code
        if ($JobResult.ExitCode -ne 0) {
            return @{
                Success = $false
                Reason = "Unity exited with code: $($JobResult.ExitCode)"
                ExitCode = $JobResult.ExitCode
            }
        }
        
        # Check for compilation errors in output
        if ($JobResult.Output -match "Compilation failed") {
            return @{
                Success = $false
                Reason = "Compilation errors detected in output"
                Output = $JobResult.Output
            }
        }
        
        # Check error stream
        if ($JobResult.Error -and $JobResult.Error.Length -gt 0) {
            return @{
                Success = $false
                Reason = "Errors detected in error stream"
                Error = $JobResult.Error
            }
        }
        
        return @{
            Success = $true
            Reason = "Compilation completed successfully"
            Duration = $JobResult.Duration
        }
        
    } catch {
        Write-UnityParallelLog -Message "Failed to test compilation result: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Reason = "Error testing result: $($_.Exception.Message)"
        }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Start-UnityCompilationJob',
    'Find-UnityExecutablePath',
    'Test-UnityCompilationResult'
)

#endregion

# REFACTORING MARKER: This module was refactored from Unity-Claude-UnityParallelization.psm1 on 2025-08-25
# Original file size: 2084 lines
# This component: Unity compilation process integration (lines 980-1096, ~117 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCADfbsrcuf2hW0B
# 0tEm/Qw+/0p2vUJ60+Jni0KnM8ihIKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF6YoKIAK0S/Lw3/mLRkPLAX
# og6bDF36K6jWeAJRlExkMA0GCSqGSIb3DQEBAQUABIIBAJZQtRjd0N7Bu2tg7DOn
# ytdGbrcBn9tOUTGsyox13E3PBHb4OIIG09ArV1dX+X/7MIStyQdo0Kyy/3rJwWMq
# psR72u4E19sXFFKJsMk8LzMY5sCUIy1SUDB1CzQ95YQalEk5/Dx4BnAFE/l7JngB
# uRdhhOKyBgc7XuPUNXo7dQw1oQYNXuwb1erejNSa2uuJ9fHAhjz9WhOfbgK6s9mJ
# 59DpFaCufvBXADzVrRe/ZrQMOwNt8QOAX9MwYQAStinl9kCGah5QJfNC/lrcrYEU
# eid3RdkRqJhTkMfuWCOhkwMsrAw5MApTyCORVxHuKjwmOCLpW9YWA2Hr7JmTWFEx
# afs=
# SIG # End signature block
