# Unity-Claude-Core.psm1
# Core orchestration module for Unity-Claude automation system

# Module-scoped variables
$script:AutomationContext = @{}
$script:LogDir = ''
$script:StartTime = $null

#region Initialization

function Initialize-AutomationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        
        [string]$UnityExe = 'C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe',
        [string]$LogDirectory = 'AutomationLogs',
        [int]$DefaultTimeout = 300
    )
    
    $script:AutomationContext = @{
        ProjectPath = $ProjectPath
        UnityExe = $UnityExe
        LogDir = Join-Path $ProjectPath $LogDirectory
        EditorLogPath = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'
        StartTime = Get-Date
        CycleIndex = 0
        FailedFixStreak = 0
        MaxFailedFixBeforeReview = 5
        AutoEditorDir = Join-Path $ProjectPath 'Assets\Editor\Automation'
        DefaultTimeout = $DefaultTimeout
    }
    
    $script:LogDir = $script:AutomationContext.LogDir
    $script:StartTime = $script:AutomationContext.StartTime
    
    # Ensure log directory exists
    New-Item -ItemType Directory -Force -Path $script:LogDir | Out-Null
    
    Write-Log "Automation context initialized for project: $ProjectPath" -Level 'INFO'
    
    return $script:AutomationContext
}

#endregion

#region Logging

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO','WARN','ERROR','OK','DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        'ERROR' { Write-Host $logLine -ForegroundColor Red }
        'WARN'  { Write-Host $logLine -ForegroundColor Yellow }
        'OK'    { Write-Host $logLine -ForegroundColor Green }
        'DEBUG' { Write-Host $logLine -ForegroundColor DarkGray }
        default { Write-Host $logLine }
    }
    
    # File output
    if ($script:LogDir) {
        try {
            $logFile = Join-Path $script:LogDir ("automation_{0}.log" -f (Get-Date -Format 'yyyyMMdd'))
            Add-Content -Path $logFile -Value $logLine -ErrorAction SilentlyContinue
        } catch {
            # Silently fail if we can't write to log
        }
    }
}

#endregion

#region Utility Functions

function Get-FileTailAsString {
    [CmdletBinding()]
    param(
        [string]$Path,
        [int]$Tail = 2000
    )
    
    if (-not $Path -or -not (Test-Path $Path)) { 
        return "" 
    }
    
    try {
        $lines = Get-Content -Path $Path -ErrorAction SilentlyContinue
        if ($null -eq $lines) { 
            return "" 
        }
        
        $count = $lines.Count
        if ($count -is [int] -and $count -gt 0) {
            $start = [Math]::Max(0, $count - $Tail)
            $slice = $lines[$start..($count-1)]
            return ($slice -join "`n")
        } else {
            return ($lines -join "`n")
        }
    } catch {
        Write-Log "Error reading file tail: $_" -Level 'ERROR'
        return ""
    }
}

#endregion

#region Unity Operations

function Test-UnityCompilation {
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds = 300
    )
    
    Write-Log "Starting Unity compilation test (timeout: ${TimeoutSeconds}s)" -Level 'INFO'
    
    $unityArgs = @(
        '-batchmode',
        '-quit',
        '-projectPath', $script:AutomationContext.ProjectPath,
        '-executeMethod', 'AutoRecompile.ForceCompileAndExit',
        '-logFile', '-'
    )
    
    $processInfo = @{
        FilePath = $script:AutomationContext.UnityExe
        ArgumentList = $unityArgs
        NoNewWindow = $true
        PassThru = $true
        RedirectStandardOutput = $true
        RedirectStandardError = $true
    }
    
    try {
        $process = Start-Process @processInfo
        $finished = $process.WaitForExit($TimeoutSeconds * 1000)
        
        if (-not $finished) {
            Write-Log "Unity compilation timed out after ${TimeoutSeconds}s" -Level 'WARN'
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            return @{
                Success = $false
                ExitCode = 124
                Reason = 'Timeout'
            }
        }
        
        $exitCode = $process.ExitCode
        Write-Log "Unity exited with code: $exitCode" -Level $(if ($exitCode -eq 0) { 'OK' } else { 'ERROR' })
        
        return @{
            Success = ($exitCode -eq 0)
            ExitCode = $exitCode
            Reason = if ($exitCode -eq 0) { 'Success' } else { 'CompilationError' }
        }
        
    } catch {
        Write-Log "Error during Unity compilation: $_" -Level 'ERROR'
        return @{
            Success = $false
            ExitCode = -1
            Reason = 'ProcessError'
        }
    }
}

function Export-UnityConsole {
    [CmdletBinding()]
    param(
        [string]$OutputPath,
        [int]$TimeoutSeconds = 90
    )
    
    Write-Log "Exporting Unity console to: $OutputPath" -Level 'INFO'
    
    $tempScriptPath = Join-Path $script:AutomationContext.ProjectPath 'Assets\Editor\__AutomationTemp__\ExportConsole.cs'
    $tempScriptDir = Split-Path $tempScriptPath -Parent
    
    # Ensure temp directory exists
    New-Item -ItemType Directory -Force -Path $tempScriptDir | Out-Null
    
    # Create export script
    $exportScript = @'
using UnityEditor;
using UnityEngine;
using System.IO;
using System.Reflection;

public static class ExportConsole {
    [MenuItem("Automation/Export Console")]
    public static void Export() {
        string outputPath = @"<OUTPUT_PATH>";
        
        var logEntriesType = System.Type.GetType("UnityEditor.LogEntries,UnityEditor");
        if (logEntriesType == null) {
            Debug.LogError("Could not find LogEntries type");
            EditorApplication.Exit(1);
            return;
        }
        
        var getCountMethod = logEntriesType.GetMethod("GetCount", BindingFlags.Static | BindingFlags.Public);
        var getEntryMethod = logEntriesType.GetMethod("GetEntryInternal", BindingFlags.Static | BindingFlags.Public);
        
        if (getCountMethod == null || getEntryMethod == null) {
            Debug.LogError("Could not find LogEntries methods");
            EditorApplication.Exit(1);
            return;
        }
        
        int count = (int)getCountMethod.Invoke(null, new object[0]);
        
        using (StreamWriter writer = new StreamWriter(outputPath, false)) {
            for (int i = 0; i < count; i++) {
                var entry = System.Activator.CreateInstance(
                    System.Type.GetType("UnityEditor.LogEntry,UnityEditor")
                );
                getEntryMethod.Invoke(null, new object[] { i, entry });
                
                var messageField = entry.GetType().GetField("message", BindingFlags.Instance | BindingFlags.Public);
                if (messageField != null) {
                    string message = (string)messageField.GetValue(entry);
                    writer.WriteLine(message);
                }
            }
        }
        
        Debug.Log($"Console exported to: {outputPath}");
        EditorApplication.Exit(0);
    }
}
'@.Replace('<OUTPUT_PATH>', $OutputPath.Replace('\', '\\'))
    
    Set-Content -Path $tempScriptPath -Value $exportScript
    
    $unityArgs = @(
        '-batchmode',
        '-quit',
        '-projectPath', $script:AutomationContext.ProjectPath,
        '-executeMethod', 'ExportConsole.Export',
        '-logFile', '-'
    )
    
    try {
        $process = Start-Process -FilePath $script:AutomationContext.UnityExe `
                                -ArgumentList $unityArgs `
                                -NoNewWindow `
                                -PassThru
        
        $finished = $process.WaitForExit($TimeoutSeconds * 1000)
        
        if (-not $finished) {
            Write-Log "Console export timed out" -Level 'WARN'
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        
        # Cleanup temp script
        Remove-Item -Path $tempScriptPath -Force -ErrorAction SilentlyContinue
        
        return (Test-Path $OutputPath)
        
    } catch {
        Write-Log "Error exporting console: $_" -Level 'ERROR'
        return $false
    }
}

function Install-AutoRecompileScript {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    $autoEditorDir = $script:AutomationContext.AutoEditorDir
    $autoEditorFile = Join-Path $autoEditorDir 'AutoRecompile.cs'
    
    if ((Test-Path $autoEditorFile) -and -not $Force) {
        Write-Log "AutoRecompile.cs already installed" -Level 'DEBUG'
        return $true
    }
    
    Write-Log "Installing AutoRecompile.cs to: $autoEditorFile" -Level 'INFO'
    
    # Create directory if needed
    New-Item -ItemType Directory -Force -Path $autoEditorDir | Out-Null
    
    # AutoRecompile script content (simplified version)
    $autoRecompileContent = @'
using UnityEditor;
using UnityEditor.Compilation;
using UnityEngine;
using System;

[InitializeOnLoad]
public static class AutoRecompile {
    private const string SESSION_KEY = "AutoRecompile_Active";
    private const string START_TIME_KEY = "AutoRecompile_StartTime";
    private const int TIMEOUT_SECONDS = 300;
    
    static AutoRecompile() {
        if (SessionState.GetBool(SESSION_KEY, false)) {
            EditorApplication.update += CheckCompilationStatus;
        }
    }
    
    [MenuItem("Automation/Force Compile and Exit")]
    public static void ForceCompileAndExit() {
        Debug.Log("[AutoRecompile] Starting forced compilation");
        SessionState.SetBool(SESSION_KEY, true);
        SessionState.SetString(START_TIME_KEY, DateTime.Now.Ticks.ToString());
        
        // Force recompilation
        CompilationPipeline.RequestScriptCompilation();
        
        // Start monitoring
        EditorApplication.update += CheckCompilationStatus;
    }
    
    private static void CheckCompilationStatus() {
        if (!SessionState.GetBool(SESSION_KEY, false)) {
            EditorApplication.update -= CheckCompilationStatus;
            return;
        }
        
        // Check timeout
        if (long.TryParse(SessionState.GetString(START_TIME_KEY, "0"), out long startTicks)) {
            var elapsed = TimeSpan.FromTicks(DateTime.Now.Ticks - startTicks);
            if (elapsed.TotalSeconds > TIMEOUT_SECONDS) {
                Debug.LogError($"[AutoRecompile] Compilation timeout after {TIMEOUT_SECONDS} seconds");
                Cleanup();
                EditorApplication.Exit(124);
                return;
            }
        }
        
        if (!EditorApplication.isCompiling && !CompilationPipeline.isCompiling) {
            Debug.Log("[AutoRecompile] Compilation completed successfully");
            Cleanup();
            EditorApplication.Exit(0);
        }
    }
    
    private static void Cleanup() {
        SessionState.EraseBool(SESSION_KEY);
        SessionState.EraseString(START_TIME_KEY);
        EditorApplication.update -= CheckCompilationStatus;
    }
}
'@
    
    try {
        Set-Content -Path $autoEditorFile -Value $autoRecompileContent
        Write-Log "AutoRecompile.cs installed successfully" -Level 'OK'
        return $true
    } catch {
        Write-Log "Failed to install AutoRecompile.cs: $_" -Level 'ERROR'
        return $false
    }
}

function Test-EditorSuccess {
    [CmdletBinding()]
    param(
        [string]$ConsolePath,
        [string]$EditorLogPath
    )
    
    $hasErrors = $false
    $errorPatterns = @(
        'error CS\d+',
        'NullReferenceException',
        'ArgumentException',
        'IndexOutOfRangeException',
        'InvalidOperationException',
        'NotImplementedException'
    )
    
    # Check console dump
    if (Test-Path $ConsolePath) {
        $consoleContent = Get-Content -Path $ConsolePath -ErrorAction SilentlyContinue
        foreach ($pattern in $errorPatterns) {
            if ($consoleContent -match $pattern) {
                $hasErrors = $true
                Write-Log "Found error pattern in console: $pattern" -Level 'WARN'
                break
            }
        }
    }
    
    # Check Editor log
    if (-not $hasErrors -and (Test-Path $EditorLogPath)) {
        $editorTail = Get-FileTailAsString -Path $EditorLogPath -Tail 500
        foreach ($pattern in $errorPatterns) {
            if ($editorTail -match $pattern) {
                $hasErrors = $true
                Write-Log "Found error pattern in Editor log: $pattern" -Level 'WARN'
                break
            }
        }
    }
    
    return (-not $hasErrors)
}

#endregion

#region Main Automation

function Start-UnityAutomation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        
        [switch]$Loop,
        [switch]$RunOnce,
        
        [ValidateSet('Continue','Fix','Explain','Triage','Plan','Review','Debugging','Custom')]
        [string]$PromptType = 'Continue',
        
        [string]$AdditionalInstructions,
        [string]$Model = 'sonnet-3.5',
        [string]$ClaudeExe = 'claude',
        [int]$MaxCycles = 100
    )
    
    # Initialize context
    $context = Initialize-AutomationContext -ProjectPath $ProjectPath
    
    # Install AutoRecompile script
    if (-not (Install-AutoRecompileScript)) {
        Write-Log "Failed to install AutoRecompile script" -Level 'ERROR'
        return
    }
    
    $continueAutomation = $true
    $cycleCount = 0
    
    while ($continueAutomation -and $cycleCount -lt $MaxCycles) {
        $cycleCount++
        Write-Log "=== Starting automation cycle $cycleCount ===" -Level 'INFO'
        
        # Test compilation
        $compilationResult = Test-UnityCompilation
        
        if ($compilationResult.Success) {
            Write-Log "Unity compilation succeeded!" -Level 'OK'
            
            if ($RunOnce) {
                $continueAutomation = $false
                break
            }
        } else {
            Write-Log "Unity compilation failed: $($compilationResult.Reason)" -Level 'ERROR'
            
            # Export console for analysis
            $consolePath = Join-Path $context.ProjectPath 'ConsoleLogs.txt'
            $exported = Export-UnityConsole -OutputPath $consolePath
            
            if ($exported) {
                Write-Log "Console exported for analysis" -Level 'INFO'
                # Here we would call the IPC module to communicate with Claude
                # For now, this is a placeholder
                Write-Log "Claude integration would happen here" -Level 'DEBUG'
            }
        }
        
        if (-not $Loop) {
            $continueAutomation = $false
        }
        
        # Add delay between cycles
        if ($continueAutomation) {
            Start-Sleep -Seconds 5
        }
    }
    
    Write-Log "=== Automation completed after $cycleCount cycles ===" -Level 'INFO'
}

function Get-CurrentPromptType {
    [CmdletBinding()]
    param(
        [int]$FailedStreak,
        [int]$MaxBeforeReview = 5
    )
    
    if ($FailedStreak -ge $MaxBeforeReview) {
        return 'Review'
    } elseif ($FailedStreak -ge 3) {
        return 'Debugging'
    } else {
        return 'Continue'
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Start-UnityAutomation',
    'Test-UnityCompilation',
    'Export-UnityConsole',
    'Install-AutoRecompileScript',
    'Write-Log',
    'Get-FileTailAsString',
    'Test-EditorSuccess',
    'Get-CurrentPromptType',
    'Initialize-AutomationContext'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkpOmi5ZpFwUlMkS6eECKxPj/
# kHmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUhUy9HhvLLiK7g9DgOd2Q7cNm7AgwDQYJKoZIhvcNAQEBBQAEggEAAWHa
# i5qQPoyn+lLsyuPB5EDigbvIOVj4cO0buvOfl9ZvM2IBeeryjPv7zMcUwl1Qz2k0
# BxDLdHqjzqXMK2PsglIp3B4BwSRVJYMSH6ml7EwCrQ84nFM1LBOD+ADxAF3YvQZO
# F2zHpy9si1Vx65k1oUsbb6tVLrly2Dk32uFjyiwwl+MzXgSGFW+j+CC0jUVBfOkB
# wBkMcQsskvhReTiezaQyXWFLxEv9uyFWdGP+2lI47Ttt5c44zNamviTR/d1jdHvL
# 1OWNCCxbkm6wBG5tHk3Ue1zqQbxx+OHEcPAWSuXvbaB7LueJuy65+sxycI3DUTMj
# CiGoSX7ZIj3nM2JSYQ==
# SIG # End signature block
