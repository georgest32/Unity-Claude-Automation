#Requires -Version 5.1
<#
.SYNOPSIS
    Unity project validation and compilation operations for SafeCommandExecution module.

.DESCRIPTION
    Provides Unity project structure validation and script compilation
    verification functionality.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 1317-1595)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force
Import-Module "$PSScriptRoot\ValidationEngine.psm1" -Force

#region Unity Project Validation

function Invoke-UnityProjectValidation {
    <#
    .SYNOPSIS
    Validates Unity project structure and configuration.
    
    .DESCRIPTION
    Performs comprehensive validation of Unity project including
    folder structure, assets, and project settings.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity project validation" -Level Info
    
    # Set default project path if not provided
    $projectPath = $Command.Arguments.ProjectPath
    if (-not $projectPath) {
        $projectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering"
        Write-SafeLog "Using default project path: $projectPath" -Level Debug
    }
    
    # Validate project path exists and is safe
    if (-not (Test-PathSafety -Path $projectPath)) {
        throw "Project path is not safe or accessible: $projectPath"
    }
    
    $validation = @{
        ProjectPath = $projectPath
        IsValid = $true
        Issues = @()
        Warnings = @()
        Assets = @{
            Count = 0
            Size = 0
            Types = @{}
        }
        Scripts = @{
            Count = 0
            Size = 0
            CompilationErrors = @()
        }
    }
    
    Write-SafeLog "Validating Unity project at: $projectPath" -Level Debug
    
    try {
        # Check basic project structure
        $requiredFolders = @('Assets', 'ProjectSettings')
        foreach ($folder in $requiredFolders) {
            $folderPath = Join-Path $projectPath $folder
            if (-not (Test-Path $folderPath)) {
                $validation.IsValid = $false
                $validation.Issues += "Missing required folder: $folder"
                Write-SafeLog "Project validation issue: Missing folder $folder" -Level Warning
            }
        }
        
        # Analyze assets if Assets folder exists
        $assetsPath = Join-Path $projectPath "Assets"
        if (Test-Path $assetsPath) {
            $assetFiles = Get-ChildItem $assetsPath -Recurse -File -ErrorAction SilentlyContinue
            $validation.Assets.Count = $assetFiles.Count
            $validation.Assets.Size = ($assetFiles | Measure-Object -Property Length -Sum).Sum
            
            # Group by file extension
            $typeGroups = $assetFiles | Group-Object Extension
            foreach ($group in $typeGroups) {
                $validation.Assets.Types[$group.Name] = $group.Count
            }
            
            Write-SafeLog "Project assets analysis: $($validation.Assets.Count) files, $($validation.Assets.Size) bytes" -Level Debug
            
            # Analyze C# scripts specifically
            $scriptFiles = $assetFiles | Where-Object { $_.Extension -eq '.cs' }
            $validation.Scripts.Count = $scriptFiles.Count
            $validation.Scripts.Size = ($scriptFiles | Measure-Object -Property Length -Sum).Sum
            
            Write-SafeLog "Project scripts analysis: $($validation.Scripts.Count) files, $($validation.Scripts.Size) bytes" -Level Debug
        }
        
        # Check ProjectSettings files
        $projectSettingsPath = Join-Path $projectPath "ProjectSettings"
        if (Test-Path $projectSettingsPath) {
            $requiredSettings = @('ProjectSettings.asset', 'TagManager.asset', 'InputManager.asset')
            foreach ($setting in $requiredSettings) {
                $settingPath = Join-Path $projectSettingsPath $setting
                if (-not (Test-Path $settingPath)) {
                    $validation.Warnings += "Missing project setting: $setting"
                    Write-SafeLog "Project validation warning: Missing setting $setting" -Level Warning
                }
            }
        }
        
        Write-SafeLog "Unity project validation completed. Valid: $($validation.IsValid), Issues: $($validation.Issues.Count)" -Level Info
        
        return @{
            Success = $true
            Output = $validation
            Error = $null
            Validation = $validation
        }
    }
    catch {
        Write-SafeLog "Unity project validation failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            Validation = @{
                ProjectPath = $projectPath
                IsValid = $false
                Issues = @("Validation failed: $($_.ToString())")
            }
        }
    }
}

#endregion

#region Unity Script Compilation

function Invoke-UnityScriptCompilation {
    <#
    .SYNOPSIS
    Verifies Unity script compilation status.
    
    .DESCRIPTION
    Executes Unity in batch mode to check for script compilation errors
    and returns detailed compilation results.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity script compilation verification" -Level Info
    
    # Set default project path if not provided
    $projectPath = $Command.Arguments.ProjectPath
    if (-not $projectPath) {
        $projectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering"
        Write-SafeLog "Using default project path: $projectPath" -Level Debug
    }
    
    # Validate project path exists and is safe
    if (-not (Test-PathSafety -Path $projectPath)) {
        throw "Project path is not safe or accessible: $projectPath"
    }
    
    # Find Unity executable
    $unityPath = Find-UnityExecutable
    if (-not $unityPath) {
        throw "Unity executable not found"
    }
    
    # Prepare Unity command arguments for compilation check
    $unityArgs = @(
        '-batchmode',
        '-quit',
        '-projectPath', "`"$projectPath`"",
        '-executeMethod', 'UnityEditor.EditorApplication.Exit',
        '-logFile', "$env:TEMP\Unity_Compilation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    )
    
    Write-SafeLog "Executing Unity script compilation check with arguments: $($unityArgs -join ' ')" -Level Info
    
    try {
        # Execute Unity for compilation check
        $startTime = Get-Date
        $processInfo = Start-Process -FilePath $unityPath `
                                    -ArgumentList $unityArgs `
                                    -NoNewWindow `
                                    -PassThru `
                                    -RedirectStandardOutput "$env:TEMP\unity_compile_output.txt" `
                                    -RedirectStandardError "$env:TEMP\unity_compile_error.txt"
        
        $completed = $processInfo.WaitForExit($TimeoutSeconds * 1000)
        $duration = (Get-Date) - $startTime
        
        if (-not $completed) {
            $processInfo.Kill()
            throw "Unity script compilation check timed out after $TimeoutSeconds seconds"
        }
        
        # Read compilation output and errors
        $output = Get-Content "$env:TEMP\unity_compile_output.txt" -ErrorAction SilentlyContinue
        $errors = Get-Content "$env:TEMP\unity_compile_error.txt" -ErrorAction SilentlyContinue
        $logPath = $unityArgs | Where-Object { $_ -like '*.log' } | Select-Object -First 1
        
        # Analyze compilation result
        $compilationResult = Test-UnityCompilationResult -LogPath $logPath -ProcessExitCode $processInfo.ExitCode
        $compilationResult.Duration = $duration.TotalSeconds
        
        Write-SafeLog "Unity script compilation check completed. Status: $($compilationResult.Status), Duration: $($duration.TotalSeconds)s" -Level Info
        
        if ($errors) {
            Write-SafeLog "Unity compilation check had errors: $($errors -join '; ')" -Level Warning
        }
        
        return @{
            Success = ($compilationResult.Status -eq 'Success')
            Output = $output
            Error = if ($errors) { $errors -join '; ' } else { $null }
            CompilationResult = $compilationResult
        }
    }
    catch {
        Write-SafeLog "Unity script compilation check failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            CompilationResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
                Duration = 0
                Errors = @()
                Warnings = @()
            }
        }
    }
}

function Test-UnityCompilationResult {
    <#
    .SYNOPSIS
    Analyzes Unity compilation log for errors and warnings.
    
    .DESCRIPTION
    Parses Unity log file to extract compilation errors, warnings,
    and determine overall compilation status.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [int]$ProcessExitCode
    )
    
    Write-SafeLog "Validating Unity compilation result. Exit code: $ProcessExitCode" -Level Debug
    
    $compilationResult = @{
        Status = 'Unknown'
        ErrorMessage = $null
        Errors = @()
        Warnings = @()
        Duration = 0
    }
    
    # Check process exit code first
    if ($ProcessExitCode -ne 0) {
        $compilationResult.Status = 'Failed'
        $compilationResult.ErrorMessage = "Unity process exited with code: $ProcessExitCode"
        Write-SafeLog "Compilation failed - Unity exit code: $ProcessExitCode" -Level Warning
    }
    
    # Parse Unity log if available
    if ($LogPath -and (Test-Path $LogPath)) {
        Write-SafeLog "Parsing Unity compilation log: $LogPath" -Level Debug
        
        $logContent = Get-Content $LogPath -ErrorAction SilentlyContinue
        
        foreach ($line in $logContent) {
            # Look for compilation errors
            if ($line -match 'error CS\d+:') {
                $compilationResult.Errors += $line
                $compilationResult.Status = 'Failed'
                Write-SafeLog "Compilation error detected: $line" -Level Warning
            }
            
            # Look for compilation warnings
            if ($line -match 'warning CS\d+:') {
                $compilationResult.Warnings += $line
                Write-SafeLog "Compilation warning detected: $line" -Level Debug
            }
            
            # Look for successful compilation
            if ($line -match 'Compilation succeeded') {
                if ($compilationResult.Status -ne 'Failed') {
                    $compilationResult.Status = 'Success'
                    Write-SafeLog "Compilation success detected: $line" -Level Debug
                }
            }
        }
    }
    
    # Default to success if no errors detected and exit code is 0
    if ($compilationResult.Status -eq 'Unknown' -and $ProcessExitCode -eq 0) {
        $compilationResult.Status = 'Success'
    }
    
    Write-SafeLog "Compilation result validation complete. Status: $($compilationResult.Status), Errors: $($compilationResult.Errors.Count), Warnings: $($compilationResult.Warnings.Count)" -Level Info
    return $compilationResult
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-UnityProjectValidation',
    'Invoke-UnityScriptCompilation',
    'Test-UnityCompilationResult'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Unity project validation and compilation (lines 1317-1595, ~384 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAUAXX1EnZeMlqf
# 0Iv4lRRnpXCh1St6elX6DwKDdsIjhaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGDh+LbnTYqI8JjSyvrTgLjH
# hQNK7/0IZNw+/eTkkkpnMA0GCSqGSIb3DQEBAQUABIIBACZp7wiQGN7GUc0nbm0d
# ESov9DQZEDhHl1hd1BeFglDZsCnP/BZo3IqQJjRt94yBd7TZs2gsvpuGWzaOuAYu
# oRShoZgKXwa4tZztznV/D7U1qSxoo0C2EM/Qygib5lTSFDOuXpnLG8vg+EWP0OiO
# D5pG4IWt85pN/um8KudyGwTxqnsGGf8PWcPa632yxsWLjTyKtOXQbVjEu0SekwxJ
# jOJdpQQ56/O0OGwliWRBgu8gi5vTQd1r7Tvqc2Wasxdg6YhWdCE3D8BHNqVjH68P
# Lapm1DNJKI8eFWrcb8EnmEHZbvRNKan8azOOORBWYva6aDFm9cayGspVeO4G1ZOb
# 93s=
# SIG # End signature block
