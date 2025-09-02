#Requires -Version 5.1
<#
.SYNOPSIS
    Command type-specific handlers for SafeCommandExecution module.

.DESCRIPTION
    Provides implementation for different command types including Unity,
    Test, PowerShell, Build, and Analysis commands.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 395-714)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force
Import-Module "$PSScriptRoot\ValidationEngine.psm1" -Force
Import-Module "$PSScriptRoot\RunspaceManagement.psm1" -Force

#region Unity Command Implementation

function Invoke-UnityCommand {
    <#
    .SYNOPSIS
    Executes Unity-specific commands safely.
    
    .DESCRIPTION
    Handles Unity executable commands with proper argument sanitization
    and timeout protection.
    #>
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

#endregion

#region Test Command Implementation

function Invoke-TestCommand {
    <#
    .SYNOPSIS
    Executes test commands in a constrained runspace.
    
    .DESCRIPTION
    Safely runs Pester tests and other testing frameworks
    within security boundaries.
    #>
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

#endregion

#region PowerShell Command Implementation

function Invoke-PowerShellCommand {
    <#
    .SYNOPSIS
    Executes PowerShell scripts in a heavily constrained environment.
    
    .DESCRIPTION
    Runs arbitrary PowerShell with minimal allowed commands
    and constrained language mode.
    #>
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

#endregion

#region Build Command Router

function Invoke-BuildCommand {
    <#
    .SYNOPSIS
    Routes build commands to appropriate Unity build handlers.
    
    .DESCRIPTION
    Validates and routes build operations to specific Unity build functions.
    #>
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

#endregion

#region Analysis Command Router

function Invoke-AnalysisCommand {
    <#
    .SYNOPSIS
    Routes analysis commands to appropriate Unity analysis handlers.
    
    .DESCRIPTION
    Validates and routes analysis operations to specific Unity analysis functions.
    #>
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

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-UnityCommand',
    'Invoke-TestCommand',
    'Invoke-PowerShellCommand',
    'Invoke-BuildCommand',
    'Invoke-AnalysisCommand'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Command type handler implementations (lines 395-714)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDcOqRlDYBsgnX8
# IEx22ouE8KgVhop4ZM8OtC29zubvXqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHvVNM7/GOBZ/hPdfOduFMo6
# EjZetpTe4JB6/3YJvG2gMA0GCSqGSIb3DQEBAQUABIIBALGaK7yuxw9ooluwTEK5
# CAcom7+63SzS/A3bMXA1eGk70P8JMC3BXW9itkmpeckkH3BVkkVMYF14tTjHIN6o
# Pm7T5s990JSvJpBoOWJc7YQEy7Rx4RO2V9muMsyDBq5fn11SMQ4gx0IZ6OVEP7Xz
# 4Ujd4L3iNl+9/FQ0difLNxowVJvstTU3rfE6YeEeipdN7is3HIMIbXeNebo4+fc2
# av9zrCYNvQgGaP3PqTRi+ZOa0CBvwUvSH66Lra1iFclwhvIU5i9ZUHddfIbukUoV
# APk6xJzbdF5zx1vAdxmOr+AhtblBc630pkhgnDwVnh0qPZG+88FMor7+aVTzKr58
# Jfo=
# SIG # End signature block
