#Requires -Version 5.1
<#
.SYNOPSIS
    Unity build operations for SafeCommandExecution module.

.DESCRIPTION
    Provides Unity player build, asset import, and custom method execution
    functionality with safety validation.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 715-1214 and 1215-1295)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force
Import-Module "$PSScriptRoot\ValidationEngine.psm1" -Force

#region Unity Player Build Operations

function Invoke-UnityPlayerBuild {
    <#
    .SYNOPSIS
    Builds Unity player for specified target platform.
    
    .DESCRIPTION
    Executes Unity build pipeline with proper validation and error handling.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 300
    )
    
    Write-SafeLog "Starting Unity player build operation" -Level Info
    
    # Validate required arguments
    if (-not $Command.Arguments.BuildTarget) {
        throw "BuildTarget is required for Unity player build"
    }
    
    # Map and validate build target
    $buildTargetMap = @{
        'Windows' = 'StandaloneWindows64'
        'StandaloneWindows64' = 'StandaloneWindows64'
        'Android' = 'Android'
        'iOS' = 'iOS'
        'WebGL' = 'WebGL'
        'Linux' = 'StandaloneLinux64'
        'StandaloneLinux64' = 'StandaloneLinux64'
    }
    
    $buildTarget = $buildTargetMap[$Command.Arguments.BuildTarget]
    if (-not $buildTarget) {
        throw "Invalid build target: $($Command.Arguments.BuildTarget). Valid targets: $($buildTargetMap.Keys -join ', ')"
    }
    
    Write-SafeLog "Validated build target: $buildTarget" -Level Debug
    
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
    
    # Set output path
    $outputPath = $Command.Arguments.OutputPath
    if (-not $outputPath) {
        $outputPath = Join-Path $projectPath "Builds\$buildTarget"
        Write-SafeLog "Using default output path: $outputPath" -Level Debug
    }
    
    # Generate Unity build script
    $buildScript = New-UnityBuildScript -BuildTarget $buildTarget -ProjectPath $projectPath -OutputPath $outputPath
    $scriptPath = Join-Path $env:TEMP "UnityBuildScript_$(Get-Date -Format 'yyyyMMdd_HHmmss').cs"
    
    try {
        # Write build script to temp file
        Set-Content -Path $scriptPath -Value $buildScript -Encoding UTF8
        Write-SafeLog "Generated Unity build script: $scriptPath" -Level Debug
        
        # Find Unity executable
        $unityPath = Find-UnityExecutable
        if (-not $unityPath) {
            throw "Unity executable not found"
        }
        
        # Prepare Unity command arguments
        $unityArgs = @(
            '-batchmode',
            '-quit',
            '-projectPath', "`"$projectPath`"",
            '-buildTarget', $buildTarget,
            '-executeMethod', 'UnityClaudeAutomation.BuildPlayer.BuildPlayerStandalone',
            '-logFile', "$env:TEMP\Unity_Build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        )
        
        # Add custom arguments if provided
        if ($Command.Arguments.CustomArgs) {
            $unityArgs += $Command.Arguments.CustomArgs
        }
        
        Write-SafeLog "Executing Unity build with arguments: $($unityArgs -join ' ')" -Level Info
        
        # Execute Unity build
        $startTime = Get-Date
        $processInfo = Start-Process -FilePath $unityPath `
                                    -ArgumentList $unityArgs `
                                    -NoNewWindow `
                                    -PassThru `
                                    -RedirectStandardOutput "$env:TEMP\unity_build_output.txt" `
                                    -RedirectStandardError "$env:TEMP\unity_build_error.txt"
        
        $completed = $processInfo.WaitForExit($TimeoutSeconds * 1000)
        $duration = (Get-Date) - $startTime
        
        if (-not $completed) {
            $processInfo.Kill()
            throw "Unity build timed out after $TimeoutSeconds seconds"
        }
        
        # Read build output and errors
        $output = Get-Content "$env:TEMP\unity_build_output.txt" -ErrorAction SilentlyContinue
        $errors = Get-Content "$env:TEMP\unity_build_error.txt" -ErrorAction SilentlyContinue
        $logPath = $unityArgs | Where-Object { $_ -like '*.log' } | Select-Object -First 1
        
        # Validate build result
        $buildResult = Test-UnityBuildResult -LogPath $logPath -OutputPath $outputPath -ProcessExitCode $processInfo.ExitCode
        $buildResult.Duration = $duration.TotalSeconds
        
        Write-SafeLog "Unity build completed. Status: $($buildResult.Status), Duration: $($buildResult.Duration)s" -Level Info
        
        if ($errors) {
            Write-SafeLog "Unity build had errors: $($errors -join '; ')" -Level Warning
        }
        
        return @{
            Success = ($buildResult.Status -eq 'Success')
            Output = $output
            Error = if ($errors) { $errors -join '; ' } else { $null }
            BuildResult = $buildResult
        }
    }
    finally {
        # Cleanup temp build script
        if (Test-Path $scriptPath) {
            Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-UnityBuildScript {
    <#
    .SYNOPSIS
    Generates Unity build automation script.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$BuildTarget,
        
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-SafeLog "Generating Unity build script for target: $BuildTarget" -Level Debug
    
    # Generate C# build script for Unity
    $buildScript = @"
using UnityEngine;
using UnityEditor;
using UnityEditor.Build.Reporting;
using System.IO;

namespace UnityClaudeAutomation
{
    public class BuildPlayer
    {
        public static void BuildPlayerStandalone()
        {
            Debug.Log("[UnityClaudeAutomation] Starting build process...");
            
            try
            {
                var buildPlayerOptions = new BuildPlayerOptions();
                buildPlayerOptions.scenes = GetEnabledScenes();
                buildPlayerOptions.locationPathName = @"$OutputPath";
                buildPlayerOptions.target = BuildTarget.$BuildTarget;
                buildPlayerOptions.options = BuildOptions.None;
                
                Debug.Log(`$"[UnityClaudeAutomation] Building for target: {buildPlayerOptions.target}");
                Debug.Log(`$"[UnityClaudeAutomation] Output path: {buildPlayerOptions.locationPathName}");
                Debug.Log(`$"[UnityClaudeAutomation] Scenes: {string.Join(", ", buildPlayerOptions.scenes)}");
                
                var report = BuildPipeline.BuildPlayer(buildPlayerOptions);
                
                if (report.result == BuildResult.Succeeded)
                {
                    Debug.Log(`$"[UnityClaudeAutomation] Build succeeded: {report.summary.outputPath}");
                    Debug.Log(`$"[UnityClaudeAutomation] Build size: {report.summary.totalSize} bytes");
                    Debug.Log(`$"[UnityClaudeAutomation] Build time: {report.summary.totalTime}");
                }
                else
                {
                    Debug.LogError(`$"[UnityClaudeAutomation] Build failed with result: {report.result}");
                    foreach (var step in report.steps)
                    {
                        if (step.messages.Length > 0)
                        {
                            foreach (var message in step.messages)
                            {
                                Debug.LogError(`$"[UnityClaudeAutomation] Build error: {message.content}");
                            }
                        }
                    }
                    EditorApplication.Exit(1);
                }
            }
            catch (System.Exception ex)
            {
                Debug.LogError(`$"[UnityClaudeAutomation] Build exception: {ex.Message}");
                EditorApplication.Exit(1);
            }
        }
        
        private static string[] GetEnabledScenes()
        {
            var scenes = new string[EditorBuildSettings.scenes.Length];
            for (int i = 0; i < scenes.Length; i++)
            {
                scenes[i] = EditorBuildSettings.scenes[i].path;
            }
            return scenes;
        }
    }
}
"@
    
    return $buildScript
}

function Test-UnityBuildResult {
    <#
    .SYNOPSIS
    Validates Unity build result by analyzing logs and output.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [int]$ProcessExitCode
    )
    
    Write-SafeLog "Validating Unity build result. Exit code: $ProcessExitCode" -Level Debug
    
    $buildResult = @{
        Status = 'Unknown'
        ErrorMessage = $null
        OutputFiles = @()
        BuildSize = 0
        Duration = 0
    }
    
    # Check process exit code first
    if ($ProcessExitCode -ne 0) {
        $buildResult.Status = 'Failed'
        $buildResult.ErrorMessage = "Unity process exited with code: $ProcessExitCode"
        Write-SafeLog "Build failed - Unity exit code: $ProcessExitCode" -Level Warning
    }
    
    # Parse Unity log if available
    if ($LogPath -and (Test-Path $LogPath)) {
        Write-SafeLog "Parsing Unity build log: $LogPath" -Level Debug
        
        $logContent = Get-Content $LogPath -ErrorAction SilentlyContinue
        
        # Look for success indicators
        $successPatterns = @(
            'Build succeeded',
            'Exiting batchmode successfully',
            '\[UnityClaudeAutomation\] Build succeeded'
        )
        
        $errorPatterns = @(
            'Build failed',
            'error CS',
            'BuildPlayerWindow+BuildMethodException',
            '\[UnityClaudeAutomation\] Build failed'
        )
        
        foreach ($line in $logContent) {
            foreach ($pattern in $successPatterns) {
                if ($line -match $pattern) {
                    $buildResult.Status = 'Success'
                    Write-SafeLog "Build success detected in log: $line" -Level Debug
                }
            }
            
            foreach ($pattern in $errorPatterns) {
                if ($line -match $pattern) {
                    $buildResult.Status = 'Failed'
                    $buildResult.ErrorMessage = $line
                    Write-SafeLog "Build error detected in log: $line" -Level Warning
                }
            }
        }
    }
    
    # Validate output files exist
    if ($OutputPath -and (Test-Path $OutputPath)) {
        $outputFiles = Get-ChildItem $OutputPath -Recurse -File
        $buildResult.OutputFiles = $outputFiles.FullName
        $buildResult.BuildSize = ($outputFiles | Measure-Object -Property Length -Sum).Sum
        
        Write-SafeLog "Build output validated. Files: $($outputFiles.Count), Size: $($buildResult.BuildSize) bytes" -Level Debug
        
        if ($outputFiles.Count -gt 0 -and $buildResult.Status -eq 'Unknown') {
            $buildResult.Status = 'Success'
        }
    }
    elseif ($OutputPath) {
        Write-SafeLog "Build output path not found: $OutputPath" -Level Warning
        if ($buildResult.Status -ne 'Failed') {
            $buildResult.Status = 'Failed'
            $buildResult.ErrorMessage = "Build output not found at: $OutputPath"
        }
    }
    
    # Default to success if no errors detected
    if ($buildResult.Status -eq 'Unknown') {
        $buildResult.Status = 'Success'
    }
    
    Write-SafeLog "Build result validation complete. Status: $($buildResult.Status)" -Level Info
    return $buildResult
}

#endregion

#region Unity Asset Import Operations

function Invoke-UnityAssetImport {
    <#
    .SYNOPSIS
    Imports Unity packages into project.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 300
    )
    
    Write-SafeLog "Starting Unity asset import operation" -Level Info
    
    # Validate required arguments
    if (-not $Command.Arguments.PackagePath) {
        throw "PackagePath is required for Unity asset import"
    }
    
    $packagePath = $Command.Arguments.PackagePath
    if (-not (Test-Path $packagePath)) {
        throw "Package not found: $packagePath"
    }
    
    Write-SafeLog "Importing Unity package: $packagePath" -Level Debug
    
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
    
    # Generate Unity asset import script
    $importScript = New-UnityAssetImportScript -PackagePath $packagePath
    $scriptPath = Join-Path $env:TEMP "UnityAssetImportScript_$(Get-Date -Format 'yyyyMMdd_HHmmss').cs"
    
    try {
        # Write import script to temp file
        Set-Content -Path $scriptPath -Value $importScript -Encoding UTF8
        Write-SafeLog "Generated Unity asset import script: $scriptPath" -Level Debug
        
        # Find Unity executable
        $unityPath = Find-UnityExecutable
        if (-not $unityPath) {
            throw "Unity executable not found"
        }
        
        # Prepare Unity command arguments
        $unityArgs = @(
            '-batchmode',
            '-quit',
            '-projectPath', "`"$projectPath`"",
            '-executeMethod', 'UnityClaudeAutomation.AssetImporter.ImportPackage',
            '-packagePath', "`"$packagePath`"",
            '-logFile', "$env:TEMP\Unity_AssetImport_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        )
        
        Write-SafeLog "Executing Unity asset import with arguments: $($unityArgs -join ' ')" -Level Info
        
        # Execute Unity asset import
        $startTime = Get-Date
        $processInfo = Start-Process -FilePath $unityPath `
                                    -ArgumentList $unityArgs `
                                    -NoNewWindow `
                                    -PassThru `
                                    -RedirectStandardOutput "$env:TEMP\unity_import_output.txt" `
                                    -RedirectStandardError "$env:TEMP\unity_import_error.txt"
        
        $completed = $processInfo.WaitForExit($TimeoutSeconds * 1000)
        $duration = (Get-Date) - $startTime
        
        if (-not $completed) {
            $processInfo.Kill()
            throw "Unity asset import timed out after $TimeoutSeconds seconds"
        }
        
        # Read import output and errors
        $output = Get-Content "$env:TEMP\unity_import_output.txt" -ErrorAction SilentlyContinue
        $errors = Get-Content "$env:TEMP\unity_import_error.txt" -ErrorAction SilentlyContinue
        
        Write-SafeLog "Unity asset import completed in $($duration.TotalSeconds)s" -Level Info
        
        if ($errors) {
            Write-SafeLog "Unity asset import had errors: $($errors -join '; ')" -Level Warning
        }
        
        return @{
            Success = ($processInfo.ExitCode -eq 0)
            Output = $output
            Error = if ($errors) { $errors -join '; ' } else { $null }
            Duration = $duration.TotalSeconds
        }
    }
    finally {
        # Cleanup temp import script
        if (Test-Path $scriptPath) {
            Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-UnityAssetImportScript {
    <#
    .SYNOPSIS
    Generates Unity asset import automation script.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$PackagePath
    )
    
    Write-SafeLog "Generating Unity asset import script for package: $PackagePath" -Level Debug
    
    # Generate C# asset import script for Unity
    $importScript = @"
using UnityEngine;
using UnityEditor;
using System;

namespace UnityClaudeAutomation
{
    public class AssetImporter
    {
        public static void ImportPackage()
        {
            Debug.Log("[UnityClaudeAutomation] Starting asset import process...");
            
            try
            {
                string[] args = Environment.GetCommandLineArgs();
                string packagePath = null;
                
                for (int i = 0; i < args.Length; i++)
                {
                    if (args[i] == "-packagePath" && i + 1 < args.Length)
                    {
                        packagePath = args[i + 1];
                        break;
                    }
                }
                
                if (string.IsNullOrEmpty(packagePath))
                {
                    Debug.LogError("[UnityClaudeAutomation] Package path not provided");
                    EditorApplication.Exit(1);
                    return;
                }
                
                Debug.Log(`$"[UnityClaudeAutomation] Importing package: {packagePath}");
                
                AssetDatabase.StartAssetEditing();
                
                try
                {
                    AssetDatabase.ImportPackage(packagePath, false);
                    AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
                    
                    Debug.Log("[UnityClaudeAutomation] Asset import completed successfully");
                }
                finally
                {
                    AssetDatabase.StopAssetEditing();
                }
            }
            catch (Exception ex)
            {
                Debug.LogError(`$"[UnityClaudeAutomation] Asset import exception: {ex.Message}");
                EditorApplication.Exit(1);
            }
        }
    }
}
"@
    
    return $importScript
}

#endregion

#region Unity Custom Method Execution

function Invoke-UnityCustomMethod {
    <#
    .SYNOPSIS
    Executes custom Unity methods for automation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Executing Unity custom method: $($Command.Arguments.MethodName)" -Level Info
    
    if (-not $Command.Arguments.MethodName) {
        throw "MethodName is required for Unity custom method execution"
    }
    
    # Placeholder for custom method execution
    # In real implementation, this would execute Unity custom methods
    
    return @{
        Success = $true
        Output = "Custom method execution placeholder"
        Error = $null
        Duration = 0
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-UnityPlayerBuild',
    'New-UnityBuildScript',
    'Test-UnityBuildResult',
    'Invoke-UnityAssetImport',
    'New-UnityAssetImportScript',
    'Invoke-UnityCustomMethod'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Unity build operations (lines 715-1295, ~500 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDD9kzfZ87jwOs5
# 4O8bkA983zBKt9Vo4yMtdR14VxGYB6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMPMx4Jk+bfGjzb5REp7RtoT
# bkWBstz7ev6TYTHsFOKGMA0GCSqGSIb3DQEBAQUABIIBAHK/u3npIzsYxpznaNJt
# Dm4MNsZPmDvaTyjoIJDCgHZapPts1f5oaAVuV2ktHR/NzPB2W0/4DU4r/yCSvtpS
# Fime+frZMzkepWF4nmjEfLTiQVJkwPGHrzmJXBET0tlzWW11BR+d+N+r6n4Wo3rU
# imib1PvACbg1Wyl6Y7kNQSrxky5/SeltjkyF+xy8fnBVrvLbhNydt81THUXPzQZy
# mwHNHrbmDjumvUw+Pu6SSeog5BEFfDHNUeBQytRcTQOXTs/STlkmTT4QPAcKIg57
# bh5OVMkcVdhuq2WckQsbVtUB/enTrukVdhqGwKT9soQf/zZit1hnexEUth3avR3k
# m5w=
# SIG # End signature block
