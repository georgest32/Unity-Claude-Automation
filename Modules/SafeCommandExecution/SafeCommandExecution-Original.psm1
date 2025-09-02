# Safe Command Execution Module
# Phase 1 Day 3-4 Security Framework Implementation
# Provides constrained runspace execution for Unity automation
# Date: 2025-08-18
# 
# NOTE: This is the MONOLITHIC version (2860 lines) - kept for backward compatibility
# Version 2.0.0+ uses the refactored modular architecture in SafeCommandExecution-Refactored.psm1
# To use refactored version, update manifest RootModule to 'SafeCommandExecution-Refactored.psm1'
#
# DEBUG: Module load tracking
if ($env:SAFECOMMAND_DEBUG) {
    Write-Host "[DEBUG] Loading SafeCommandExecution.psm1 (MONOLITHIC VERSION)" -ForegroundColor Yellow
    Write-Host "[DEBUG] For refactored version, use SafeCommandExecution-Refactored.psm1" -ForegroundColor Yellow
}

#region Module Configuration

# Script-level configuration
$script:SafeCommandConfig = @{
    MaxExecutionTime = 300  # Maximum seconds for command execution
    AllowedPaths = @()      # Project boundaries
    BlockedCommands = @(    # Dangerous commands to block
        'Invoke-Expression',
        'iex',
        'Invoke-Command',
        'Add-Type',
        'New-Object System.Diagnostics.Process',
        'Start-Process cmd',
        'Start-Process powershell'
    )
}

# Thread-safe logging
$script:LogMutex = New-Object System.Threading.Mutex($false, "UnityClaudeAutomation")

#endregion

#region Logging Infrastructure

function Write-SafeLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug', 'Security')]
        [string]$Level = 'Info'
    )
    
    $logFile = Join-Path $PSScriptRoot "..\..\unity_claude_automation.log"
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [SafeCommand] [$Level] $Message"
    
    try {
        $acquired = $script:LogMutex.WaitOne(1000)
        if ($acquired) {
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
        }
    }
    finally {
        if ($acquired) {
            $script:LogMutex.ReleaseMutex()
        }
    }
    
    # Also output to console based on level
    switch ($Level) {
        'Error' { Write-Error $Message }
        'Warning' { Write-Warning $Message }
        'Debug' { Write-Debug $Message }
        'Security' { Write-Host "[SECURITY] $Message" -ForegroundColor Magenta }
        default { Write-Verbose $Message }
    }
}

#endregion

#region Constrained Runspace Creation

function New-ConstrainedRunspace {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$AllowedCommands = @(
            'Get-Content', 'Set-Content', 'Add-Content',
            'Test-Path', 'Get-ChildItem', 'Join-Path',
            'Split-Path', 'Resolve-Path', 'Get-Item',
            'Get-Date', 'Measure-Command', 'Select-Object',
            'Where-Object', 'ForEach-Object', 'Sort-Object',
            'ConvertTo-Json', 'ConvertFrom-Json',
            'Write-Output', 'Write-Host', 'Out-String'
        ),
        
        [Parameter()]
        [hashtable]$Variables = @{},
        
        [Parameter()]
        [string[]]$Modules = @()
    )
    
    Write-SafeLog "Creating constrained runspace with $($AllowedCommands.Count) allowed commands" -Level Debug
    
    try {
        # Create initial session state
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
        $iss.LanguageMode = [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage
        
        # Add only allowed commands
        foreach ($cmd in $AllowedCommands) {
            $cmdlet = Get-Command $cmd -ErrorAction SilentlyContinue
            if ($cmdlet) {
                $entry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry(
                    $cmd, 
                    $cmdlet.ImplementingType,
                    $null
                )
                $iss.Commands.Add($entry)
                Write-SafeLog "Added allowed command: $cmd" -Level Debug
            }
        }
        
        # Add variables
        foreach ($var in $Variables.GetEnumerator()) {
            $entry = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry(
                $var.Key,
                $var.Value,
                $null
            )
            $iss.Variables.Add($entry)
            Write-SafeLog "Added variable: $($var.Key)" -Level Debug
        }
        
        # Create runspace
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
        $runspace.Open()
        
        Write-SafeLog "Constrained runspace created successfully" -Level Info
        return $runspace
    }
    catch {
        Write-SafeLog "Failed to create constrained runspace: $($_.Exception.Message)" -Level Error
        throw
    }
}

#endregion

#region Parameter Validation

function Test-CommandSafety {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command
    )
    
    Write-SafeLog "Validating command safety: $($Command.CommandType)" -Level Security
    
    # Check for blocked patterns - separate literal and regex patterns
    $literalPatterns = @(
        'Invoke-Expression',
        'iex',
        'Invoke-Command',
        '`',         # Backtick escape
        '[char]',    # Character code execution (literal)
        'Start-Process cmd',
        'Start-Process powershell'
    )
    
    $regexPatterns = @(
        '\$\(.+\)',  # Subexpression execution
        'Add-Type.*-TypeDefinition',
        'New-Object.*Process',
        '&\s*\{',    # Script block invocation
        '\|.*iex'    # Pipe to invoke-expression
    )
    
    # Robust argument processing for mixed types (arrays, hashtables, etc.)
    $commandString = ""
    
    if ($Command.Arguments -is [array]) {
        # Handle array arguments
        $commandString = $Command.Arguments -join ' '
        Write-SafeLog "Processing array arguments: $commandString" -Level Debug
    }
    elseif ($Command.Arguments -is [hashtable]) {
        # Handle hashtable arguments - extract meaningful values
        $argParts = @()
        foreach ($key in $Command.Arguments.Keys) {
            $value = $Command.Arguments[$key]
            if ($value -is [string]) {
                $argParts += $value
            }
            elseif ($value -is [array]) {
                $argParts += ($value -join ' ')
            }
            else {
                $argParts += $value.ToString()
            }
        }
        $commandString = $argParts -join ' '
        Write-SafeLog "Processing hashtable arguments: $commandString" -Level Debug
    }
    elseif ($Command.Arguments -is [string]) {
        # Handle single string argument
        $commandString = $Command.Arguments
        Write-SafeLog "Processing string argument: $commandString" -Level Debug
    }
    else {
        # Handle other types - convert to string safely
        $commandString = $Command.Arguments.ToString()
        Write-SafeLog "Processing other argument type: $($Command.Arguments.GetType().Name)" -Level Debug
    }
    
    # Add debug logging for the actual command string being processed
    Write-SafeLog "Processing command string for pattern detection: '$commandString'" -Level Debug
    
    # Check literal patterns first (exact string matching)
    foreach ($pattern in $literalPatterns) {
        if ($commandString.Contains($pattern)) {
            Write-SafeLog "BLOCKED: Dangerous literal pattern detected: $pattern in command: $commandString" -Level Security
            return @{
                IsSafe = $false
                Reason = "Dangerous pattern detected: $pattern"
            }
        }
    }
    
    # Check regex patterns (pattern matching)
    foreach ($pattern in $regexPatterns) {
        if ($commandString -match $pattern) {
            Write-SafeLog "BLOCKED: Dangerous regex pattern detected: $pattern in command: $commandString" -Level Security
            return @{
                IsSafe = $false
                Reason = "Dangerous pattern detected: $pattern"
            }
        }
    }
    
    # Validate command type
    $allowedTypes = @('Unity', 'Test', 'Build', 'PowerShell', 'Analysis')
    if ($Command.CommandType -notin $allowedTypes) {
        Write-SafeLog "BLOCKED: Unknown command type: $($Command.CommandType)" -Level Security
        return @{
            IsSafe = $false
            Reason = "Unknown command type: $($Command.CommandType)"
        }
    }
    
    # Check for path traversal
    if ($Command.Arguments -match '\.\.[\\/]') {
        Write-SafeLog "BLOCKED: Path traversal attempt detected" -Level Security
        return @{
            IsSafe = $false
            Reason = "Path traversal attempt detected"
        }
    }
    
    Write-SafeLog "Command validated as SAFE" -Level Security
    return @{
        IsSafe = $true
        Reason = "All safety checks passed"
    }
}

function Test-PathSafety {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter()]
        [string[]]$AllowedPaths = @(
            $PSScriptRoot, 
            $env:TEMP,
            "$env:LOCALAPPDATA\Unity\Editor",
            "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation",
            "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Testing",
            "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Testing\TestData"
        )
    )
    
    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
        
        foreach ($allowed in $AllowedPaths) {
            $allowedFull = [System.IO.Path]::GetFullPath($allowed)
            if ($fullPath.StartsWith($allowedFull)) {
                Write-SafeLog "Path validated within boundaries: $Path" -Level Debug
                return $true
            }
        }
        
        Write-SafeLog "BLOCKED: Path outside allowed boundaries: $Path" -Level Security
        return $false
    }
    catch {
        Write-SafeLog "Path validation failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Remove-DangerousCharacters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Input
    )
    
    # Remove or escape dangerous characters
    $cleaned = $Input -replace '[;&|`$]', ''
    $cleaned = $cleaned -replace '<', ''
    $cleaned = $cleaned -replace '>', ''
    $cleaned = $cleaned -replace '\$\(', ''
    $cleaned = $cleaned -replace '\)', ''
    
    if ($cleaned -ne $Input) {
        Write-SafeLog "Sanitized input: removed dangerous characters" -Level Security
    }
    
    return $cleaned
}

#endregion

#region Safe Command Execution

function Invoke-SafeCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 60,
        
        [Parameter()]
        [switch]$ValidateExecution,
        
        [Parameter()]
        [string[]]$AllowedPaths = @()
    )
    
    Write-SafeLog "Executing safe command: $($Command.CommandType) - $($Command.Operation)" -Level Info
    
    # Validate command safety
    $safety = Test-CommandSafety -Command $Command
    if (-not $safety.IsSafe) {
        Write-SafeLog "Command execution blocked: $($safety.Reason)" -Level Security
        return @{
            Success = $false
            Error = $safety.Reason
            Output = $null
        }
    }
    
    try {
        # Handle different command types
        switch ($Command.CommandType) {
            'Unity' {
                $result = Invoke-UnityCommand -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'Test' {
                $result = Invoke-TestCommand -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'PowerShell' {
                $result = Invoke-PowerShellCommand -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'Build' {
                $result = Invoke-BuildCommand -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'Analysis' {
                $result = Invoke-AnalysisCommand -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            default {
                throw "Unsupported command type: $($Command.CommandType)"
            }
        }
        
        Write-SafeLog "Command executed successfully" -Level Info
        return @{
            Success = $true
            Output = $result
            Error = $null
        }
    }
    catch {
        Write-SafeLog "Command execution failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
        }
    }
}

#endregion

#region Command Type Implementations

function Invoke-UnityCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 60
    )
    
    Write-SafeLog "Executing Unity command: $($Command.Operation)" -Level Debug
    
    # Find Unity executable
    $unityPath = Find-UnityExecutable
    if (-not $unityPath) {
        throw "Unity executable not found"
    }
    
    # Build safe arguments
    $safeArgs = @()
    
    if ($Command.Arguments -is [string]) {
        $safeArgs = $Command.Arguments -split ' ' | ForEach-Object {
            Remove-DangerousCharacters -Input $_
        }
    }
    else {
        $safeArgs = $Command.Arguments | ForEach-Object {
            Remove-DangerousCharacters -Input $_
        }
    }
    
    # Execute with timeout protection
    $processInfo = Start-Process -FilePath $unityPath `
                                -ArgumentList $safeArgs `
                                -NoNewWindow `
                                -PassThru `
                                -RedirectStandardOutput "$env:TEMP\unity_output.txt" `
                                -RedirectStandardError "$env:TEMP\unity_error.txt"
    
    $completed = $processInfo.WaitForExit($TimeoutSeconds * 1000)
    
    if (-not $completed) {
        $processInfo.Kill()
        throw "Unity command timed out after $TimeoutSeconds seconds"
    }
    
    # Read output
    $output = Get-Content "$env:TEMP\unity_output.txt" -ErrorAction SilentlyContinue
    $errors = Get-Content "$env:TEMP\unity_error.txt" -ErrorAction SilentlyContinue
    
    if ($errors) {
        Write-SafeLog "Unity command had errors: $errors" -Level Warning
    }
    
    return $output
}

function Invoke-TestCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 60
    )
    
    Write-SafeLog "Executing test command: $($Command.Operation)" -Level Debug
    
    # Create constrained runspace for test execution
    $runspace = New-ConstrainedRunspace -AllowedCommands @(
        'Invoke-Pester',
        'Get-Content',
        'Test-Path',
        'Write-Output'
    )
    
    try {
        $ps = [PowerShell]::Create()
        $ps.Runspace = $runspace
        
        # Add test execution script
        $script = {
            param($TestPath, $Configuration)
            
            if ($Configuration) {
                Invoke-Pester -Configuration $Configuration
            }
            else {
                Invoke-Pester -Path $TestPath -PassThru
            }
        }
        
        $ps.AddScript($script)
        $ps.AddParameter('TestPath', $Command.Arguments.TestPath)
        $ps.AddParameter('Configuration', $Command.Arguments.Configuration)
        
        # Execute with timeout
        $handle = $ps.BeginInvoke()
        $completed = $handle.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000)
        
        if ($completed) {
            $result = $ps.EndInvoke($handle)
            return $result
        }
        else {
            $ps.Stop()
            throw "Test execution timed out after $TimeoutSeconds seconds"
        }
    }
    finally {
        if ($ps) { $ps.Dispose() }
        if ($runspace) { $runspace.Close() }
    }
}

function Invoke-PowerShellCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 60
    )
    
    Write-SafeLog "Executing PowerShell command in constrained runspace" -Level Debug
    
    # Very limited command set for PowerShell execution
    $runspace = New-ConstrainedRunspace -AllowedCommands @(
        'Get-Content',
        'Set-Content',
        'Test-Path',
        'Get-ChildItem',
        'Select-Object',
        'Where-Object',
        'Write-Output'
    )
    
    try {
        $ps = [PowerShell]::Create()
        $ps.Runspace = $runspace
        
        # Sanitize script
        $script = Remove-DangerousCharacters -Input $Command.Arguments.Script
        $ps.AddScript($script)
        
        # Execute with timeout
        $handle = $ps.BeginInvoke()
        $completed = $handle.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000)
        
        if ($completed) {
            $result = $ps.EndInvoke($handle)
            
            if ($ps.Streams.Error.Count -gt 0) {
                $errors = $ps.Streams.Error | ForEach-Object { $_.ToString() }
                Write-SafeLog "PowerShell execution had errors: $($errors -join '; ')" -Level Warning
            }
            
            return $result
        }
        else {
            $ps.Stop()
            throw "PowerShell execution timed out after $TimeoutSeconds seconds"
        }
    }
    finally {
        if ($ps) { $ps.Dispose() }
        if ($runspace) { $runspace.Close() }
    }
}

function Invoke-BuildCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 300
    )
    
    Write-SafeLog "Executing build command: $($Command.Operation)" -Level Debug
    Write-SafeLog "Build command arguments: $($Command.Arguments | ConvertTo-Json -Compress)" -Level Debug
    
    try {
        # Validate build operation type
        $validOperations = @('BuildPlayer', 'ImportAsset', 'ExecuteMethod', 'ValidateProject', 'CompileScripts')
        if ($Command.Operation -notin $validOperations) {
            throw "Invalid build operation: $($Command.Operation). Valid operations: $($validOperations -join ', ')"
        }
        
        # Handle different build operations
        switch ($Command.Operation) {
            'BuildPlayer' {
                Write-SafeLog "Executing Unity player build operation" -Level Info
                return Invoke-UnityPlayerBuild -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'ImportAsset' {
                Write-SafeLog "Executing Unity asset import operation" -Level Info
                return Invoke-UnityAssetImport -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'ExecuteMethod' {
                Write-SafeLog "Executing Unity custom method operation" -Level Info
                return Invoke-UnityCustomMethod -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'ValidateProject' {
                Write-SafeLog "Executing Unity project validation operation" -Level Info
                return Invoke-UnityProjectValidation -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'CompileScripts' {
                Write-SafeLog "Executing Unity script compilation operation" -Level Info
                return Invoke-UnityScriptCompilation -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            default {
                throw "Unsupported build operation: $($Command.Operation)"
            }
        }
    }
    catch {
        Write-SafeLog "Build command execution failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            BuildResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
                Duration = 0
            }
        }
    }
}

function Invoke-AnalysisCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Executing analysis command: $($Command.Operation)" -Level Debug
    Write-SafeLog "Analysis command arguments: $($Command.Arguments | ConvertTo-Json -Compress)" -Level Debug
    
    try {
        # Validate analysis operation type
        $validOperations = @('LogAnalysis', 'ErrorPattern', 'Performance', 'TrendAnalysis', 'ReportGeneration', 'DataExport', 'MetricExtraction')
        if ($Command.Operation -notin $validOperations) {
            throw "Invalid analysis operation: $($Command.Operation). Valid operations: $($validOperations -join ', ')"
        }
        
        # Handle different analysis operations
        switch ($Command.Operation) {
            'LogAnalysis' {
                Write-SafeLog "Executing Unity log analysis operation" -Level Info
                return Invoke-UnityLogAnalysis -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'ErrorPattern' {
                Write-SafeLog "Executing Unity error pattern analysis operation" -Level Info
                return Invoke-UnityErrorPatternAnalysis -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'Performance' {
                Write-SafeLog "Executing Unity performance analysis operation" -Level Info
                return Invoke-UnityPerformanceAnalysis -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'TrendAnalysis' {
                Write-SafeLog "Executing Unity trend analysis operation" -Level Info
                return Invoke-UnityTrendAnalysis -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'ReportGeneration' {
                Write-SafeLog "Executing Unity report generation operation" -Level Info
                return Invoke-UnityReportGeneration -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'DataExport' {
                Write-SafeLog "Executing Unity data export operation" -Level Info
                return Export-UnityAnalysisData -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            'MetricExtraction' {
                Write-SafeLog "Executing Unity metric extraction operation" -Level Info
                return Get-UnityAnalyticsMetrics -Command $Command -TimeoutSeconds $TimeoutSeconds
            }
            
            default {
                throw "Unsupported analysis operation: $($Command.Operation)"
            }
        }
    }
    catch {
        Write-SafeLog "Analysis command execution failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            AnalysisResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
                Duration = 0
            }
        }
    }
}

#endregion

#region Unity Build Automation Functions

function Invoke-UnityPlayerBuild {
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

function Invoke-UnityAssetImport {
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

function Invoke-UnityCustomMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 300
    )
    
    Write-SafeLog "Starting Unity custom method execution" -Level Info
    
    # Validate required arguments
    if (-not $Command.Arguments.MethodName) {
        throw "MethodName is required for Unity custom method execution"
    }
    
    $methodName = $Command.Arguments.MethodName
    Write-SafeLog "Executing Unity custom method: $methodName" -Level Debug
    
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
    
    # Prepare Unity command arguments
    $unityArgs = @(
        '-batchmode',
        '-quit',
        '-projectPath', "`"$projectPath`"",
        '-executeMethod', $methodName,
        '-logFile', "$env:TEMP\Unity_CustomMethod_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    )
    
    # Add custom arguments if provided
    if ($Command.Arguments.CustomArgs) {
        $unityArgs += $Command.Arguments.CustomArgs
    }
    
    Write-SafeLog "Executing Unity custom method with arguments: $($unityArgs -join ' ')" -Level Info
    
    try {
        # Execute Unity custom method
        $startTime = Get-Date
        $processInfo = Start-Process -FilePath $unityPath `
                                    -ArgumentList $unityArgs `
                                    -NoNewWindow `
                                    -PassThru `
                                    -RedirectStandardOutput "$env:TEMP\unity_method_output.txt" `
                                    -RedirectStandardError "$env:TEMP\unity_method_error.txt"
        
        $completed = $processInfo.WaitForExit($TimeoutSeconds * 1000)
        $duration = (Get-Date) - $startTime
        
        if (-not $completed) {
            $processInfo.Kill()
            throw "Unity custom method execution timed out after $TimeoutSeconds seconds"
        }
        
        # Read method output and errors
        $output = Get-Content "$env:TEMP\unity_method_output.txt" -ErrorAction SilentlyContinue
        $errors = Get-Content "$env:TEMP\unity_method_error.txt" -ErrorAction SilentlyContinue
        
        Write-SafeLog "Unity custom method execution completed in $($duration.TotalSeconds)s" -Level Info
        
        if ($errors) {
            Write-SafeLog "Unity custom method had errors: $($errors -join '; ')" -Level Warning
        }
        
        return @{
            Success = ($processInfo.ExitCode -eq 0)
            Output = $output
            Error = if ($errors) { $errors -join '; ' } else { $null }
            Duration = $duration.TotalSeconds
            ExitCode = $processInfo.ExitCode
        }
    }
    catch {
        Write-SafeLog "Unity custom method execution failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            Duration = 0
            ExitCode = -1
        }
    }
}

function Invoke-UnityProjectValidation {
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

function Invoke-UnityScriptCompilation {
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

#region Unity Analysis Automation Functions

function Invoke-UnityLogAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity log analysis operation" -Level Info
    
    # Set default log path if not provided
    $logPath = $Command.Arguments.LogPath
    if (-not $logPath) {
        # Default Unity Editor.log location for Windows
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
        Write-SafeLog "Using default Unity log path: $logPath" -Level Debug
    }
    
    # Validate log path exists and is safe
    if (-not (Test-Path $logPath)) {
        throw "Unity log file not found: $logPath"
    }
    
    if (-not (Test-PathSafety -Path $logPath)) {
        throw "Log path is not safe or accessible: $logPath"
    }
    
    $analysis = @{
        LogPath = $logPath
        ParsedAt = Get-Date
        TotalLines = 0
        Errors = @()
        Warnings = @()
        Info = @()
        ErrorPatterns = @{}
        Summary = @{
            ErrorCount = 0
            WarningCount = 0
            InfoCount = 0
            CompilationErrors = 0
            RuntimeErrors = 0
        }
    }
    
    Write-SafeLog "Analyzing Unity log file: $logPath" -Level Debug
    
    try {
        # Read log file content
        $startTime = Get-Date
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        $analysis.TotalLines = $logContent.Count
        
        Write-SafeLog "Read $($analysis.TotalLines) lines from Unity log" -Level Debug
        
        # Define error patterns for Unity 2021.1.14f1
        $errorPatterns = @{
            'CompilationError' = 'error CS\d+:'
            'CompilationWarning' = 'warning CS\d+:'
            'RuntimeError' = 'Exception|Error:|ArgumentException|NullReferenceException'
            'AssetError' = 'Failed to import|Asset import failed'
            'BuildError' = 'Build failed|BuildPlayerWindow'
        }
        
        # Analyze each line
        foreach ($line in $logContent) {
            $lineAnalysis = @{
                Content = $line
                LineNumber = $logContent.IndexOf($line) + 1
                Timestamp = $null
                Severity = 'Info'
                Category = 'General'
                ErrorCode = $null
                FilePath = $null
            }
            
            # Extract file path and line number if present
            if ($line -match 'Assets/.*\.cs\((\d+),(\d+)\):') {
                $lineAnalysis.FilePath = ($line -split ':')[0]
            }
            
            # Check for compilation errors
            if ($line -match $errorPatterns.CompilationError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Compilation'
                $analysis.Errors += $lineAnalysis
                $analysis.Summary.CompilationErrors++
                
                # Extract error code
                if ($line -match 'error (CS\d+):') {
                    $lineAnalysis.ErrorCode = $matches[1]
                }
                
                Write-SafeLog "Compilation error detected: $($lineAnalysis.ErrorCode)" -Level Debug
            }
            # Check for compilation warnings
            elseif ($line -match $errorPatterns.CompilationWarning) {
                $lineAnalysis.Severity = 'Warning'
                $lineAnalysis.Category = 'Compilation'
                $analysis.Warnings += $lineAnalysis
                
                Write-SafeLog "Compilation warning detected" -Level Debug
            }
            # Check for runtime errors
            elseif ($line -match $errorPatterns.RuntimeError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Runtime'
                $analysis.Errors += $lineAnalysis
                $analysis.Summary.RuntimeErrors++
                
                Write-SafeLog "Runtime error detected" -Level Debug
            }
            # Check for asset errors
            elseif ($line -match $errorPatterns.AssetError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Asset'
                $analysis.Errors += $lineAnalysis
                
                Write-SafeLog "Asset error detected" -Level Debug
            }
            # Check for build errors
            elseif ($line -match $errorPatterns.BuildError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Build'
                $analysis.Errors += $lineAnalysis
                
                Write-SafeLog "Build error detected" -Level Debug
            }
            else {
                $analysis.Info += $lineAnalysis
            }
        }
        
        # Update summary counts
        $analysis.Summary.ErrorCount = $analysis.Errors.Count
        $analysis.Summary.WarningCount = $analysis.Warnings.Count
        $analysis.Summary.InfoCount = $analysis.Info.Count
        
        $duration = (Get-Date) - $startTime
        
        Write-SafeLog "Unity log analysis completed. Errors: $($analysis.Summary.ErrorCount), Warnings: $($analysis.Summary.WarningCount), Duration: $($duration.TotalSeconds)s" -Level Info
        
        return @{
            Success = $true
            Output = $analysis
            Error = $null
            AnalysisResult = $analysis
            Duration = $duration.TotalSeconds
        }
    }
    catch {
        Write-SafeLog "Unity log analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            AnalysisResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
                Duration = 0
            }
        }
    }
}

function Invoke-UnityErrorPatternAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity error pattern analysis" -Level Info
    
    # Get log path from command or use default
    $logPath = $Command.Arguments.LogPath
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    # Validate log path
    if (-not (Test-Path $logPath)) {
        throw "Unity log file not found: $logPath"
    }
    
    $patternAnalysis = @{
        LogPath = $logPath
        AnalyzedAt = Get-Date
        ErrorPatterns = @{}
        TrendAnalysis = @{}
        FrequencyAnalysis = @{}
        Recommendations = @()
    }
    
    Write-SafeLog "Analyzing error patterns in Unity log: $logPath" -Level Debug
    
    try {
        # Read log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        
        # Define specific Unity error patterns with solutions
        $knownPatterns = @{
            'CS0246' = @{
                Pattern = 'error CS0246:.*could not be found'
                Description = 'Type or namespace not found'
                Category = 'Missing Reference'
                Solution = 'Add missing using statement or assembly reference'
                Frequency = 0
            }
            'CS0103' = @{
                Pattern = 'error CS0103:.*does not exist'
                Description = 'Name does not exist in current context'
                Category = 'Scope Issue'
                Solution = 'Check variable declaration and scope'
                Frequency = 0
            }
            'CS1061' = @{
                Pattern = 'error CS1061:.*does not contain a definition'
                Description = 'Member not found on type'
                Category = 'API Issue'
                Solution = 'Check API documentation or add extension method'
                Frequency = 0
            }
            'CS0029' = @{
                Pattern = 'error CS0029:.*Cannot implicitly convert'
                Description = 'Type conversion error'
                Category = 'Type Mismatch'
                Solution = 'Add explicit cast or change variable type'
                Frequency = 0
            }
        }
        
        # Analyze patterns in log
        foreach ($line in $logContent) {
            foreach ($patternName in $knownPatterns.Keys) {
                $pattern = $knownPatterns[$patternName]
                if ($line -match $pattern.Pattern) {
                    $pattern.Frequency++
                    
                    Write-SafeLog "Found error pattern $patternName in log" -Level Debug
                }
            }
        }
        
        # Update pattern analysis
        $patternAnalysis.ErrorPatterns = $knownPatterns
        
        # Generate frequency analysis (PowerShell 5.1 compatible)
        $frequencyValues = @()
        foreach ($pattern in $knownPatterns.Values) {
            $frequencyValues += $pattern.Frequency
        }
        $totalErrors = ($frequencyValues | Measure-Object -Sum).Sum
        foreach ($patternName in $knownPatterns.Keys) {
            $frequency = $knownPatterns[$patternName].Frequency
            $percentage = if ($totalErrors -gt 0) { [math]::Round(($frequency / $totalErrors) * 100, 2) } else { 0 }
            
            $patternAnalysis.FrequencyAnalysis[$patternName] = @{
                Count = $frequency
                Percentage = $percentage
                Description = $knownPatterns[$patternName].Description
            }
        }
        
        # Generate recommendations based on most frequent errors
        $topErrors = $knownPatterns.GetEnumerator() | 
                    Where-Object { $_.Value.Frequency -gt 0 } |
                    Sort-Object { $_.Value.Frequency } -Descending |
                    Select-Object -First 3
        
        foreach ($error in $topErrors) {
            $patternAnalysis.Recommendations += @{
                ErrorType = $error.Key
                Priority = switch ($error.Value.Frequency) {
                    { $_ -ge 10 } { 'High' }
                    { $_ -ge 5 } { 'Medium' }
                    default { 'Low' }
                }
                Description = $error.Value.Description
                Solution = $error.Value.Solution
                Frequency = $error.Value.Frequency
            }
        }
        
        Write-SafeLog "Error pattern analysis completed. Found $totalErrors total errors across $($knownPatterns.Count) pattern types" -Level Info
        
        return @{
            Success = $true
            Output = $patternAnalysis
            Error = $null
            PatternAnalysis = $patternAnalysis
        }
    }
    catch {
        Write-SafeLog "Error pattern analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            PatternAnalysis = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

function Invoke-UnityPerformanceAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity performance analysis" -Level Info
    
    # Get analysis parameters
    $logPath = $Command.Arguments.LogPath
    $metricTypes = $Command.Arguments.MetricTypes
    if (-not $metricTypes) {
        $metricTypes = @('Compilation', 'Build', 'Test', 'Import')
    }
    
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    # Validate log path
    if (-not (Test-Path $logPath)) {
        throw "Unity log file not found: $logPath"
    }
    
    $performanceAnalysis = @{
        LogPath = $logPath
        AnalyzedAt = Get-Date
        MetricTypes = $metricTypes
        Metrics = @{}
        Benchmarks = @{}
        Trends = @{}
        Recommendations = @()
    }
    
    Write-SafeLog "Analyzing performance metrics in Unity log: $logPath" -Level Debug
    
    try {
        # Start timing analysis
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Read log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        
        # Define performance patterns to extract
        $performancePatterns = @{
            'CompilationTime' = @{
                StartPattern = 'Compilation started'
                EndPattern = 'Compilation (succeeded|failed)'
                Metrics = @()
            }
            'BuildTime' = @{
                StartPattern = 'Build started|Building Player'
                EndPattern = 'Build (completed|failed)'
                Metrics = @()
            }
            'ImportTime' = @{
                StartPattern = 'Importing'
                EndPattern = 'Import (completed|failed)'
                Metrics = @()
            }
            'TestTime' = @{
                StartPattern = 'Running tests'
                EndPattern = 'Test run (completed|failed)'
                Metrics = @()
            }
        }
        
        # Extract timing information from log
        $currentOperations = @{}
        
        foreach ($line in $logContent) {
            # Look for timing information in Unity logs
            foreach ($patternName in $performancePatterns.Keys) {
                $pattern = $performancePatterns[$patternName]
                
                # Check for start pattern
                if ($line -match $pattern.StartPattern) {
                    $currentOperations[$patternName] = @{
                        StartTime = Get-Date
                        StartLine = $line
                    }
                    Write-SafeLog "Performance tracking started for $patternName" -Level Debug
                }
                
                # Check for end pattern
                if ($line -match $pattern.EndPattern -and $currentOperations.ContainsKey($patternName)) {
                    $operation = $currentOperations[$patternName]
                    $endTime = Get-Date
                    $duration = ($endTime - $operation.StartTime).TotalMilliseconds
                    
                    $pattern.Metrics += @{
                        StartTime = $operation.StartTime
                        EndTime = $endTime
                        Duration = $duration
                        StartLine = $operation.StartLine
                        EndLine = $line
                    }
                    
                    $currentOperations.Remove($patternName)
                    Write-SafeLog "Performance tracking completed for $patternName Duration: ${duration}ms" -Level Debug
                }
            }
        }
        
        # Calculate performance statistics
        foreach ($patternName in $performancePatterns.Keys) {
            $metrics = $performancePatterns[$patternName].Metrics
            
            if ($metrics.Count -gt 0) {
                $durations = $metrics | ForEach-Object { $_.Duration }
                
                $performanceAnalysis.Metrics[$patternName] = @{
                    Count = $metrics.Count
                    AverageDuration = [math]::Round(($durations | Measure-Object -Average).Average, 2)
                    MinDuration = ($durations | Measure-Object -Minimum).Minimum
                    MaxDuration = ($durations | Measure-Object -Maximum).Maximum
                    TotalDuration = [math]::Round(($durations | Measure-Object -Sum).Sum, 2)
                    Metrics = $metrics
                }
                
                Write-SafeLog "Performance metrics for $patternName Count: $($metrics.Count), Avg: $($performanceAnalysis.Metrics[$patternName].AverageDuration)ms" -Level Debug
            }
        }
        
        # Generate performance benchmarks
        $performanceAnalysis.Benchmarks = @{
            FastCompilation = 5000    # Under 5 seconds
            AcceptableBuild = 30000   # Under 30 seconds
            FastImport = 2000         # Under 2 seconds
            QuickTest = 10000         # Under 10 seconds
        }
        
        # Generate recommendations based on performance
        foreach ($metricName in $performanceAnalysis.Metrics.Keys) {
            $metric = $performanceAnalysis.Metrics[$metricName]
            $benchmark = switch ($metricName) {
                'CompilationTime' { $performanceAnalysis.Benchmarks.FastCompilation }
                'BuildTime' { $performanceAnalysis.Benchmarks.AcceptableBuild }
                'ImportTime' { $performanceAnalysis.Benchmarks.FastImport }
                'TestTime' { $performanceAnalysis.Benchmarks.QuickTest }
                default { 10000 }
            }
            
            if ($metric.AverageDuration -gt $benchmark) {
                $performanceAnalysis.Recommendations += @{
                    MetricType = $metricName
                    Issue = "Average $metricName exceeds benchmark"
                    CurrentAverage = $metric.AverageDuration
                    Benchmark = $benchmark
                    Suggestion = "Consider optimizing $metricName process"
                    Priority = if ($metric.AverageDuration -gt ($benchmark * 2)) { 'High' } else { 'Medium' }
                }
            }
        }
        
        $stopwatch.Stop()
        
        Write-SafeLog "Unity performance analysis completed in $($stopwatch.ElapsedMilliseconds)ms" -Level Info
        
        return @{
            Success = $true
            Output = $performanceAnalysis
            Error = $null
            PerformanceAnalysis = $performanceAnalysis
            Duration = $stopwatch.ElapsedMilliseconds
        }
    }
    catch {
        Write-SafeLog "Unity performance analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            PerformanceAnalysis = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

function Invoke-UnityTrendAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity trend analysis" -Level Info
    
    # Get analysis parameters
    $logPath = $Command.Arguments.LogPath
    $timeRange = $Command.Arguments.TimeRange
    if (-not $timeRange) {
        $timeRange = 7  # Default to 7 days
    }
    
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    $trendAnalysis = @{
        LogPath = $logPath
        AnalyzedAt = Get-Date
        TimeRange = $timeRange
        ErrorTrends = @{}
        PerformanceTrends = @{}
        ActivityTrends = @{}
        Insights = @()
    }
    
    Write-SafeLog "Analyzing trends in Unity log over $timeRange days: $logPath" -Level Debug
    
    try {
        # This is a simplified trend analysis - in a real implementation,
        # you would analyze historical data across multiple log files
        
        # Read current log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        
        # Analyze error frequency over time (simulated for current log)
        $errorCounts = @{
            'CS0246' = 0
            'CS0103' = 0
            'CS1061' = 0
            'CS0029' = 0
        }
        
        $warningCounts = @{}
        $activityCounts = @{
            'Compilation' = 0
            'Build' = 0
            'Test' = 0
            'Import' = 0
        }
        
        # Count occurrences in current log (safe enumeration)
        foreach ($line in $logContent) {
            # Count errors (clone keys to avoid enumeration modification)
            foreach ($errorType in @($errorCounts.Keys)) {
                if ($line -match "error $errorType") {
                    $errorCounts[$errorType]++
                }
            }
            
            # Count activities
            if ($line -match 'Compilation') { $activityCounts.Compilation++ }
            if ($line -match 'Build') { $activityCounts.Build++ }
            if ($line -match 'Test') { $activityCounts.Test++ }
            if ($line -match 'Import') { $activityCounts.Import++ }
        }
        
        # Generate trend data (simplified)
        $trendAnalysis.ErrorTrends = @{
            CurrentPeriod = $errorCounts
            TrendDirection = 'Stable'  # Would be calculated from historical data
            ChangePercentage = 0       # Would be calculated from historical data
        }
        
        $trendAnalysis.ActivityTrends = @{
            CurrentPeriod = $activityCounts
            MostActiveType = ($activityCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
            TotalActivity = ($activityCounts.Values | Measure-Object -Sum).Sum
        }
        
        # Generate insights
        $topError = $errorCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
        if ($topError.Value -gt 0) {
            $trendAnalysis.Insights += "Most frequent error: $($topError.Key) ($($topError.Value) occurrences)"
        }
        
        $trendAnalysis.Insights += "Most active development area: $($trendAnalysis.ActivityTrends.MostActiveType)"
        
        if ($trendAnalysis.ActivityTrends.TotalActivity -gt 100) {
            $trendAnalysis.Insights += "High development activity detected"
        } elseif ($trendAnalysis.ActivityTrends.TotalActivity -lt 10) {
            $trendAnalysis.Insights += "Low development activity detected"
        }
        
        Write-SafeLog "Unity trend analysis completed. Total activity: $($trendAnalysis.ActivityTrends.TotalActivity)" -Level Info
        
        return @{
            Success = $true
            Output = $trendAnalysis
            Error = $null
            TrendAnalysis = $trendAnalysis
        }
    }
    catch {
        Write-SafeLog "Unity trend analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            TrendAnalysis = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

function Invoke-UnityReportGeneration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity report generation" -Level Info
    
    # Get report parameters
    $analysisData = $Command.Arguments.AnalysisData
    $outputFormat = $Command.Arguments.OutputFormat
    $outputPath = $Command.Arguments.OutputPath
    $reportTitle = $Command.Arguments.ReportTitle
    
    if (-not $outputFormat) {
        $outputFormat = 'Html'
    }
    
    if (-not $reportTitle) {
        $reportTitle = "Unity Analysis Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    
    if (-not $outputPath) {
        $outputPath = Join-Path $env:TEMP "UnityAnalysisReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    
    $reportGeneration = @{
        Title = $reportTitle
        GeneratedAt = Get-Date
        OutputFormat = $outputFormat
        OutputPath = $outputPath
        Sections = @()
        Success = $false
    }
    
    Write-SafeLog "Generating Unity report in $outputFormat format: $outputPath" -Level Debug
    
    try {
        # Prepare report data structure
        $reportData = @{
            Title = $reportTitle
            GeneratedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Summary = @{
                TotalErrors = 0
                TotalWarnings = 0
                AnalysisType = 'Comprehensive'
                Duration = '0ms'
            }
            Sections = @()
        }
        
        # Add analysis data to report if provided
        if ($analysisData) {
            if ($analysisData.AnalysisResult) {
                $result = $analysisData.AnalysisResult
                $reportData.Summary.TotalErrors = if ($result.Summary) { $result.Summary.ErrorCount } else { 0 }
                $reportData.Summary.TotalWarnings = if ($result.Summary) { $result.Summary.WarningCount } else { 0 }
            }
            
            # Add sections based on analysis data
            $reportData.Sections += @{
                Title = 'Analysis Summary'
                Content = $analysisData
                Type = 'Data'
            }
        }
        
        # Generate report based on format
        switch ($outputFormat.ToLower()) {
            'html' {
                $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>$($reportData.Title)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 15px; border-radius: 5px; }
        .summary { background-color: #e8f4fd; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .error { color: #d32f2f; }
        .warning { color: #f57c00; }
        .success { color: #388e3c; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .section { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>$($reportData.Title)</h1>
        <p>Generated: $($reportData.GeneratedAt)</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><span class="error">Errors: $($reportData.Summary.TotalErrors)</span> | 
           <span class="warning">Warnings: $($reportData.Summary.TotalWarnings)</span></p>
        <p>Analysis Type: $($reportData.Summary.AnalysisType)</p>
    </div>
    
    <div class="section">
        <h2>Analysis Details</h2>
        <p>Unity analysis completed successfully. Detailed analysis data available in JSON format.</p>
    </div>
</body>
</html>
"@
                
                Set-Content -Path "$outputPath.html" -Value $htmlContent -Encoding UTF8
                $reportGeneration.OutputPath = "$outputPath.html"
                Write-SafeLog "HTML report generated: $outputPath.html" -Level Debug
            }
            
            'json' {
                $jsonContent = $reportData | ConvertTo-Json -Depth 10
                Set-Content -Path "$outputPath.json" -Value $jsonContent -Encoding UTF8
                $reportGeneration.OutputPath = "$outputPath.json"
                Write-SafeLog "JSON report generated: $outputPath.json" -Level Debug
            }
            
            'csv' {
                # Convert analysis data to CSV format
                $csvData = @()
                if ($analysisData -and $analysisData.AnalysisResult -and $analysisData.AnalysisResult.Errors) {
                    foreach ($error in $analysisData.AnalysisResult.Errors) {
                        $csvData += [PSCustomObject]@{
                            Type = 'Error'
                            Category = $error.Category
                            Content = $error.Content
                            FilePath = $error.FilePath
                            ErrorCode = $error.ErrorCode
                        }
                    }
                }
                
                if ($csvData.Count -gt 0) {
                    $csvData | Export-Csv -Path "$outputPath.csv" -NoTypeInformation -Encoding UTF8
                } else {
                    # Create empty CSV with headers
                    "Type,Category,Content,FilePath,ErrorCode" | Set-Content -Path "$outputPath.csv" -Encoding UTF8
                }
                
                $reportGeneration.OutputPath = "$outputPath.csv"
                Write-SafeLog "CSV report generated: $outputPath.csv" -Level Debug
            }
            
            default {
                throw "Unsupported output format: $outputFormat"
            }
        }
        
        $reportGeneration.Success = $true
        
        Write-SafeLog "Unity report generation completed: $($reportGeneration.OutputPath)" -Level Info
        
        return @{
            Success = $true
            Output = $reportGeneration
            Error = $null
            ReportGeneration = $reportGeneration
        }
    }
    catch {
        Write-SafeLog "Unity report generation failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            ReportGeneration = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

function Export-UnityAnalysisData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity analysis data export" -Level Info
    
    # Get export parameters
    $analysisData = $Command.Arguments.AnalysisData
    $exportFormat = $Command.Arguments.ExportFormat
    $outputPath = $Command.Arguments.OutputPath
    
    if (-not $exportFormat) {
        $exportFormat = 'Json'
    }
    
    if (-not $outputPath) {
        $outputPath = Join-Path $env:TEMP "UnityAnalysisExport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    
    if (-not $analysisData) {
        throw "Analysis data is required for export operation"
    }
    
    $exportResult = @{
        ExportedAt = Get-Date
        SourceData = $analysisData
        ExportFormat = $exportFormat
        OutputPath = $outputPath
        Success = $false
        Statistics = @{
            RecordsExported = 0
            FileSizeBytes = 0
        }
    }
    
    Write-SafeLog "Exporting Unity analysis data in $exportFormat format: $outputPath" -Level Debug
    
    try {
        switch ($exportFormat.ToLower()) {
            'json' {
                $jsonContent = $analysisData | ConvertTo-Json -Depth 10 -Compress
                Set-Content -Path "$outputPath.json" -Value $jsonContent -Encoding UTF8
                $exportResult.OutputPath = "$outputPath.json"
                $exportResult.Statistics.FileSizeBytes = (Get-Item "$outputPath.json").Length
            }
            
            'xml' {
                # Convert to XML format
                $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<UnityAnalysis>
    <ExportedAt>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</ExportedAt>
    <Data>$($analysisData | ConvertTo-Json -Depth 5)</Data>
</UnityAnalysis>
"@
                Set-Content -Path "$outputPath.xml" -Value $xmlContent -Encoding UTF8
                $exportResult.OutputPath = "$outputPath.xml"
                $exportResult.Statistics.FileSizeBytes = (Get-Item "$outputPath.xml").Length
            }
            
            'csv' {
                # Flatten data for CSV export
                $csvData = @()
                
                # Export error data if available
                if ($analysisData.AnalysisResult -and $analysisData.AnalysisResult.Errors) {
                    foreach ($error in $analysisData.AnalysisResult.Errors) {
                        $csvData += [PSCustomObject]@{
                            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                            Type = 'Error'
                            Category = $error.Category
                            Severity = $error.Severity
                            Content = $error.Content
                            FilePath = $error.FilePath
                            LineNumber = $error.LineNumber
                            ErrorCode = $error.ErrorCode
                        }
                    }
                }
                
                # Export warning data if available
                if ($analysisData.AnalysisResult -and $analysisData.AnalysisResult.Warnings) {
                    foreach ($warning in $analysisData.AnalysisResult.Warnings) {
                        $csvData += [PSCustomObject]@{
                            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                            Type = 'Warning'
                            Category = $warning.Category
                            Severity = $warning.Severity
                            Content = $warning.Content
                            FilePath = $warning.FilePath
                            LineNumber = $warning.LineNumber
                            ErrorCode = $warning.ErrorCode
                        }
                    }
                }
                
                if ($csvData.Count -gt 0) {
                    $csvData | Export-Csv -Path "$outputPath.csv" -NoTypeInformation -Encoding UTF8
                    $exportResult.Statistics.RecordsExported = $csvData.Count
                } else {
                    # Create empty CSV with headers
                    "Timestamp,Type,Category,Severity,Content,FilePath,LineNumber,ErrorCode" | Set-Content -Path "$outputPath.csv" -Encoding UTF8
                }
                
                $exportResult.OutputPath = "$outputPath.csv"
                $exportResult.Statistics.FileSizeBytes = (Get-Item "$outputPath.csv").Length
            }
            
            default {
                throw "Unsupported export format: $exportFormat"
            }
        }
        
        $exportResult.Success = $true
        
        Write-SafeLog "Unity analysis data export completed: $($exportResult.OutputPath), Size: $($exportResult.Statistics.FileSizeBytes) bytes" -Level Info
        
        return @{
            Success = $true
            Output = $exportResult
            Error = $null
            ExportResult = $exportResult
        }
    }
    catch {
        Write-SafeLog "Unity analysis data export failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            ExportResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

function Get-UnityAnalyticsMetrics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity analytics metrics extraction" -Level Info
    
    # Get metrics parameters
    $logPath = $Command.Arguments.LogPath
    $metricTypes = $Command.Arguments.MetricTypes
    
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    if (-not $metricTypes) {
        $metricTypes = @('ErrorRate', 'Performance', 'Activity', 'Quality')
    }
    
    $metricsResult = @{
        LogPath = $logPath
        ExtractedAt = Get-Date
        MetricTypes = $metricTypes
        Metrics = @{}
        Dashboard = @{}
        KPIs = @{}
    }
    
    Write-SafeLog "Extracting Unity analytics metrics from: $logPath" -Level Debug
    
    try {
        # Validate log path
        if (-not (Test-Path $logPath)) {
            throw "Unity log file not found: $logPath"
        }
        
        # Read log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        $totalLines = $logContent.Count
        
        # Initialize counters
        $errorCount = 0
        $warningCount = 0
        $compilationCount = 0
        $buildCount = 0
        $testCount = 0
        
        # Count various metrics
        foreach ($line in $logContent) {
            if ($line -match 'error CS\d+:') { $errorCount++ }
            if ($line -match 'warning CS\d+:') { $warningCount++ }
            if ($line -match 'Compilation') { $compilationCount++ }
            if ($line -match 'Build') { $buildCount++ }
            if ($line -match 'Test') { $testCount++ }
        }
        
        # Calculate metrics
        $metricsResult.Metrics = @{
            'ErrorRate' = @{
                Value = if ($totalLines -gt 0) { [math]::Round(($errorCount / $totalLines) * 100, 2) } else { 0 }
                Unit = 'Percentage'
                Description = 'Error rate per log lines'
                RawCount = $errorCount
                TotalLines = $totalLines
            }
            'WarningRate' = @{
                Value = if ($totalLines -gt 0) { [math]::Round(($warningCount / $totalLines) * 100, 2) } else { 0 }
                Unit = 'Percentage'
                Description = 'Warning rate per log lines'
                RawCount = $warningCount
            }
            'ActivityLevel' = @{
                Value = $compilationCount + $buildCount + $testCount
                Unit = 'Count'
                Description = 'Total development activity events'
                Breakdown = @{
                    Compilation = $compilationCount
                    Build = $buildCount
                    Test = $testCount
                }
            }
            'QualityScore' = @{
                Value = if (($errorCount + $warningCount) -eq 0) { 100 } else { 
                    [math]::Max(0, [math]::Round(100 - (($errorCount * 10 + $warningCount * 5) / [math]::Max(1, $totalLines) * 100), 2))
                }
                Unit = 'Score'
                Description = 'Code quality score based on error/warning ratio'
                Factors = @{
                    Errors = $errorCount
                    Warnings = $warningCount
                    Impact = 'Errors weighted 2x warnings'
                }
            }
        }
        
        # Generate KPIs for dashboard
        $metricsResult.KPIs = @{
            'OverallHealth' = @{
                Status = if ($metricsResult.Metrics.QualityScore.Value -ge 80) { 'Good' } 
                        elseif ($metricsResult.Metrics.QualityScore.Value -ge 60) { 'Fair' } 
                        else { 'Poor' }
                Score = $metricsResult.Metrics.QualityScore.Value
                Trend = 'Stable'  # Would be calculated from historical data
            }
            'ErrorTrend' = @{
                Current = $errorCount
                Previous = $errorCount  # Would be from historical data
                Change = 0
                Direction = 'Stable'
            }
            'ActivityIndex' = @{
                Level = if ($metricsResult.Metrics.ActivityLevel.Value -ge 50) { 'High' }
                       elseif ($metricsResult.Metrics.ActivityLevel.Value -ge 20) { 'Medium' }
                       else { 'Low' }
                Count = $metricsResult.Metrics.ActivityLevel.Value
            }
        }
        
        # Generate dashboard data
        $metricsResult.Dashboard = @{
            'Summary' = @{
                TotalErrors = $errorCount
                TotalWarnings = $warningCount
                QualityScore = $metricsResult.Metrics.QualityScore.Value
                ActivityLevel = $metricsResult.KPIs.ActivityIndex.Level
                OverallHealth = $metricsResult.KPIs.OverallHealth.Status
            }
            'Charts' = @{
                'ErrorBreakdown' = @{
                    Type = 'Pie'
                    Data = @{
                        Errors = $errorCount
                        Warnings = $warningCount
                        Clean = [math]::Max(0, $totalLines - $errorCount - $warningCount)
                    }
                }
                'ActivityBreakdown' = @{
                    Type = 'Bar'
                    Data = $metricsResult.Metrics.ActivityLevel.Breakdown
                }
            }
        }
        
        Write-SafeLog "Unity analytics metrics extraction completed. Quality Score: $($metricsResult.Metrics.QualityScore.Value), Activity: $($metricsResult.KPIs.ActivityIndex.Level)" -Level Info
        
        return @{
            Success = $true
            Output = $metricsResult
            Error = $null
            MetricsResult = $metricsResult
        }
    }
    catch {
        Write-SafeLog "Unity analytics metrics extraction failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            MetricsResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

#endregion

#region Helper Functions

function Find-UnityExecutable {
    [CmdletBinding()]
    param()
    
    $unityPaths = @(
        "C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe",
        "C:\Program Files\Unity\Editor\Unity.exe",
        "C:\Program Files (x86)\Unity\Editor\Unity.exe"
    )
    
    foreach ($path in $unityPaths) {
        if (Test-Path $path) {
            Write-SafeLog "Found Unity at: $path" -Level Debug
            return $path
        }
    }
    
    # Try to find Unity in PATH
    $unity = Get-Command Unity.exe -ErrorAction SilentlyContinue
    if ($unity) {
        return $unity.Path
    }
    
    Write-SafeLog "Unity executable not found" -Level Warning
    return $null
}

function Set-SafeCommandConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]$MaxExecutionTime,
        
        [Parameter()]
        [string[]]$AllowedPaths,
        
        [Parameter()]
        [string[]]$BlockedCommands
    )
    
    if ($PSBoundParameters.ContainsKey('MaxExecutionTime')) {
        $script:SafeCommandConfig.MaxExecutionTime = $MaxExecutionTime
        Write-SafeLog "Updated max execution time: $MaxExecutionTime seconds" -Level Info
    }
    
    if ($PSBoundParameters.ContainsKey('AllowedPaths')) {
        $script:SafeCommandConfig.AllowedPaths = $AllowedPaths
        Write-SafeLog "Updated allowed paths: $($AllowedPaths -join ', ')" -Level Info
    }
    
    if ($PSBoundParameters.ContainsKey('BlockedCommands')) {
        $script:SafeCommandConfig.BlockedCommands = $BlockedCommands
        Write-SafeLog "Updated blocked commands: $($BlockedCommands -join ', ')" -Level Info
    }
}

function Get-SafeCommandConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:SafeCommandConfig.Clone()
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Core Security Functions (Day 3-4)
    'Invoke-SafeCommand',
    'New-ConstrainedRunspace',
    'Test-CommandSafety',
    'Test-PathSafety',
    'Remove-DangerousCharacters',
    'Set-SafeCommandConfiguration',
    'Get-SafeCommandConfiguration',
    'Write-SafeLog',
    
    # Unity Command Execution Functions (Day 4-5)
    'Invoke-UnityCommand',
    'Invoke-TestCommand',
    'Invoke-PowerShellCommand',
    'Invoke-BuildCommand',
    'Invoke-UnityPlayerBuild',
    'New-UnityBuildScript',
    'Test-UnityBuildResult',
    'Invoke-UnityAssetImport',
    'New-UnityAssetImportScript',
    'Invoke-UnityCustomMethod',
    'Invoke-UnityProjectValidation',
    'Invoke-UnityScriptCompilation',
    'Test-UnityCompilationResult',
    'Find-UnityExecutable',
    
    # ANALYZE Command Functions (Day 6)
    'Invoke-AnalysisCommand',
    'Invoke-UnityLogAnalysis',
    'Invoke-UnityErrorPatternAnalysis',
    'Invoke-UnityPerformanceAnalysis',
    'Invoke-UnityTrendAnalysis',
    'Invoke-UnityReportGeneration',
    'Export-UnityAnalysisData',
    'Get-UnityAnalyticsMetrics'
)

#endregion

Write-SafeLog "SafeCommandExecution module loaded successfully" -Level Inf
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD686YQ9mtCTZus
# zWArsQkOWNaZr3joBWCs9IGzDo+pGaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKqHlI0CAqleyUi5sg9NUzLt
# NbtvoLB2P40IDgIgVmN0MA0GCSqGSIb3DQEBAQUABIIBAHI//9ic1fWatt8DkIBQ
# oLDZXcv0153SxFe6KoECfn2wS+lB44MY5qJUQqC9arnOEDg8+C/bfsv6fCk4NnZZ
# dhzSTRAvxaL3a9Fa/Gi5LXOAsc91AsHAtBScuaIM2PI8c0F4+fLRdzjqLUVDGqAQ
# KFCdQEHxxYY0hiDqiF8uY81DpU6X2DKxlx2gyS9frpI2Eq9Z9JpBl1cXrAeg1w/z
# pTgxhUMEz4H3d+Hg60EYMIHkwuX8HdKjosIsoHWjyCyb/X2KD0gJqPCKcIAPvcyC
# QduY7dmpkZFo7bYAuzCv/ph9ZRqMUbfRuYZFJTFPKmbUs5YlhTNN0+yQnJVC5eXE
# yz0=
# SIG # End signature block
