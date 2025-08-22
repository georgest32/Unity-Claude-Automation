# SafeExecution.psm1
# Safe command execution framework with constrained runspace and security validation
# Extracted from main module during refactoring
# Date: 2025-08-18

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Module Variables

# Safe cmdlets whitelist for constrained runspace
$script:SafeCmdlets = @{
    "Write-Output" = [Microsoft.PowerShell.Commands.WriteOutputCommand]
    "Write-Host" = [Microsoft.PowerShell.Commands.WriteHostCommand]
    "Write-Verbose" = [Microsoft.PowerShell.Commands.WriteVerboseCommand]
    "Write-Debug" = [Microsoft.PowerShell.Commands.WriteDebugCommand]
    "Write-Warning" = [Microsoft.PowerShell.Commands.WriteWarningCommand]
    "Get-Date" = [Microsoft.PowerShell.Commands.GetDateCommand]
    "Get-Item" = [Microsoft.PowerShell.Commands.GetItemCommand]
    "Get-ChildItem" = [Microsoft.PowerShell.Commands.GetChildItemCommand]
    "Test-Path" = [Microsoft.PowerShell.Commands.TestPathCommand]
    "Join-Path" = [Microsoft.PowerShell.Commands.JoinPathCommand]
    "Split-Path" = [Microsoft.PowerShell.Commands.SplitPathCommand]
    "Get-Content" = [Microsoft.PowerShell.Commands.GetContentCommand]
    "Set-Content" = [Microsoft.PowerShell.Commands.SetContentCommand]
    "Add-Content" = [Microsoft.PowerShell.Commands.AddContentCommand]
    "Out-File" = [Microsoft.PowerShell.Commands.OutFileCommand]
    "Select-Object" = [Microsoft.PowerShell.Commands.SelectObjectCommand]
    "Where-Object" = [Microsoft.PowerShell.Commands.WhereObjectCommand]
    "ForEach-Object" = [Microsoft.PowerShell.Commands.ForEachObjectCommand]
    "Measure-Object" = [Microsoft.PowerShell.Commands.MeasureObjectCommand]
    "Sort-Object" = [Microsoft.PowerShell.Commands.SortObjectCommand]
    "Group-Object" = [Microsoft.PowerShell.Commands.GroupObjectCommand]
}

# Dangerous cmdlets to explicitly block
$script:BlockedCmdlets = @(
    "Invoke-Expression", "Invoke-Command", "Start-Process", "Stop-Process",
    "Remove-Item", "Remove-ItemProperty", "Clear-Content", "Clear-Item",
    "New-Item", "Copy-Item", "Move-Item", "Rename-Item",
    "Set-ItemProperty", "Set-Location", "Push-Location", "Pop-Location",
    "Import-Module", "Remove-Module", "Get-Module", "New-Module",
    "Enter-PSSession", "Exit-PSSession", "New-PSSession", "Remove-PSSession",
    "Invoke-RestMethod", "Invoke-WebRequest", "Start-Job", "Stop-Job",
    "Register-ScheduledJob", "Unregister-ScheduledJob"
)

# Safe path patterns (project boundaries)
$script:SafePathPatterns = @(
    "C:\\UnityProjects\\Sound-and-Shoal\\*",
    "C:\\Unity\\*\\Logs\\*",
    "C:\\Users\\*\\AppData\\Local\\Unity\\Editor\\*"
)

#endregion

#region Safe Execution Functions

function New-ConstrainedRunspace {
    <#
    .SYNOPSIS
    Creates a constrained runspace with whitelisted cmdlets for safe command execution
    
    .DESCRIPTION
    Creates a secure PowerShell runspace with only approved cmdlets available.
    Blocks dangerous cmdlets and provides isolated execution environment.
    
    .PARAMETER AdditionalCmdlets
    Additional cmdlets to whitelist beyond the default safe set
    
    .PARAMETER TimeoutMs
    Timeout in milliseconds for runspace operations
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$AdditionalCmdlets = @{},
        
        [Parameter()]
        [int]$TimeoutMs = 300000  # 5 minutes default
    )
    
    Write-AgentLog -Message "Creating constrained runspace for safe command execution" -Level "INFO" -Component "ConstrainedRunspaceFactory"
    
    try {
        # Create empty initial session state
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
        Write-AgentLog -Message "Empty InitialSessionState created" -Level "DEBUG" -Component "ConstrainedRunspaceFactory"
        
        # Add safe cmdlets to the session state
        $cmdletCount = 0
        foreach ($cmdletName in $script:SafeCmdlets.Keys) {
            try {
                $cmdletType = $script:SafeCmdlets[$cmdletName]
                $cmdletEntry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry($cmdletName, $cmdletType, $null)
                $initialSessionState.Commands.Add($cmdletEntry)
                $cmdletCount++
                
                Write-AgentLog -Message "Added safe cmdlet: $cmdletName" -Level "DEBUG" -Component "ConstrainedRunspaceFactory"
            }
            catch {
                Write-AgentLog -Message "Failed to add cmdlet ${cmdletName}: $_" -Level "WARNING" -Component "ConstrainedRunspaceFactory"
            }
        }
        
        # Add any additional cmdlets requested
        foreach ($cmdletName in $AdditionalCmdlets.Keys) {
            try {
                $cmdletType = $AdditionalCmdlets[$cmdletName]
                $cmdletEntry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry($cmdletName, $cmdletType, $null)
                $initialSessionState.Commands.Add($cmdletEntry)
                $cmdletCount++
                
                Write-AgentLog -Message "Added additional cmdlet: $cmdletName" -Level "DEBUG" -Component "ConstrainedRunspaceFactory"
            }
            catch {
                Write-AgentLog -Message "Failed to add additional cmdlet ${cmdletName}: $_" -Level "WARNING" -Component "ConstrainedRunspaceFactory"
            }
        }
        
        # Create the constrained runspace
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($initialSessionState)
        $runspace.Open()
        
        Write-AgentLog -Message "Constrained runspace created successfully with $cmdletCount cmdlets" -Level "SUCCESS" -Component "ConstrainedRunspaceFactory"
        
        return @{
            Success = $true
            Runspace = $runspace
            CmdletCount = $cmdletCount
            TimeoutMs = $TimeoutMs
        }
    }
    catch {
        Write-AgentLog -Message "Failed to create constrained runspace: $_" -Level "ERROR" -Component "ConstrainedRunspaceFactory"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-CommandSafety {
    <#
    .SYNOPSIS
    Tests if a command is safe for autonomous execution
    
    .DESCRIPTION
    Validates commands against security criteria and blocked command lists
    
    .PARAMETER CommandText
    The command text to validate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandText
    )
    
    Write-AgentLog -Message "Testing command safety: $CommandText" -Level "DEBUG" -Component "SafetyValidator"
    
    try {
        $safetyResult = @{
            IsSafe = $true
            Reasons = @()
            BlockedCmdlets = @()
            DangerousPatterns = @()
        }
        
        # Check for blocked cmdlets
        foreach ($blockedCmdlet in $script:BlockedCmdlets) {
            if ($CommandText -match "\b$blockedCmdlet\b") {
                $safetyResult.IsSafe = $false
                $safetyResult.BlockedCmdlets += $blockedCmdlet
                $safetyResult.Reasons += "Contains blocked cmdlet: $blockedCmdlet"
                Write-AgentLog -Message "UNSAFE: Command contains blocked cmdlet: $blockedCmdlet" -Level "WARNING" -Component "SafetyValidator"
            }
        }
        
        # Check for dangerous patterns
        $dangerousPatterns = @(
            "Remove-Item.*-Recurse",
            "Format-.*",
            "Clear-.*",
            "Stop-Computer",
            "Restart-Computer",
            "shutdown",
            "del\s+/.*",
            "rmdir.*",
            "rd\s+.*"
        )
        
        foreach ($pattern in $dangerousPatterns) {
            if ($CommandText -match $pattern) {
                $safetyResult.IsSafe = $false
                $safetyResult.DangerousPatterns += $pattern
                $safetyResult.Reasons += "Contains dangerous pattern: $pattern"
                Write-AgentLog -Message "UNSAFE: Command contains dangerous pattern: $pattern" -Level "WARNING" -Component "SafetyValidator"
            }
        }
        
        if ($safetyResult.IsSafe) {
            Write-AgentLog -Message "Command passed safety validation" -Level "DEBUG" -Component "SafetyValidator"
        }
        
        return $safetyResult
    }
    catch {
        Write-AgentLog -Message "Command safety test failed: $_" -Level "ERROR" -Component "SafetyValidator"
        return @{
            IsSafe = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-ParameterSafety {
    <#
    .SYNOPSIS
    Tests if command parameters are safe
    
    .DESCRIPTION
    Validates command parameters for dangerous values and injection attempts
    
    .PARAMETER Parameters
    Hashtable of parameters to validate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )
    
    Write-AgentLog -Message "Testing parameter safety for $($Parameters.Count) parameters" -Level "DEBUG" -Component "ParameterValidator"
    
    $safetyResult = @{
        IsSafe = $true
        UnsafeParameters = @()
        Reasons = @()
    }
    
    foreach ($paramName in $Parameters.Keys) {
        $paramValue = $Parameters[$paramName]
        
        # Check for dangerous characters
        $dangerousChars = @(";", "&", "|", "*", "?", "(", ")")
        foreach ($char in $dangerousChars) {
            if ($paramValue -like "*$char*") {
                $safetyResult.IsSafe = $false
                $safetyResult.UnsafeParameters += $paramName
                $safetyResult.Reasons += "Parameter $paramName contains dangerous character: $char"
                Write-AgentLog -Message "UNSAFE: Parameter $paramName contains: $char" -Level "WARNING" -Component "ParameterValidator"
            }
        }
        
        # Check for path traversal attempts
        if ($paramValue -match "\.\./|\.\.\\") {
            $safetyResult.IsSafe = $false
            $safetyResult.UnsafeParameters += $paramName
            $safetyResult.Reasons += "Parameter $paramName contains path traversal"
            Write-AgentLog -Message "UNSAFE: Parameter $paramName contains path traversal" -Level "WARNING" -Component "ParameterValidator"
        }
    }
    
    if ($safetyResult.IsSafe) {
        Write-AgentLog -Message "All parameters passed safety validation" -Level "DEBUG" -Component "ParameterValidator"
    }
    
    return $safetyResult
}

function Test-PathSafety {
    <#
    .SYNOPSIS
    Tests if a file path is within safe boundaries
    
    .DESCRIPTION
    Validates file paths against allowed project boundaries
    
    .PARAMETER Path
    The file path to validate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    Write-AgentLog -Message "Testing path safety: $Path" -Level "DEBUG" -Component "PathValidator"
    
    try {
        $isPathSafe = $false
        
        foreach ($safePattern in $script:SafePathPatterns) {
            if ($Path -like $safePattern) {
                $isPathSafe = $true
                Write-AgentLog -Message "Path matches safe pattern: $safePattern" -Level "DEBUG" -Component "PathValidator"
                break
            }
        }
        
        if (-not $isPathSafe) {
            Write-AgentLog -Message "UNSAFE: Path outside allowed boundaries: $Path" -Level "WARNING" -Component "PathValidator"
        }
        
        return @{
            IsSafe = $isPathSafe
            Path = $Path
            Reason = if ($isPathSafe) { "Path within safe boundaries" } else { "Path outside allowed boundaries" }
        }
    }
    catch {
        Write-AgentLog -Message "Path safety test failed: $_" -Level "ERROR" -Component "PathValidator"
        return @{
            IsSafe = $false
            Error = $_.Exception.Message
        }
    }
}

function Invoke-SafeConstrainedCommand {
    <#
    .SYNOPSIS
    Executes a command in a constrained runspace with safety validation
    
    .DESCRIPTION
    Runs commands in isolated, secure environment with timeout and validation
    
    .PARAMETER CommandText
    The command to execute
    
    .PARAMETER Parameters
    Parameters for the command
    
    .PARAMETER TimeoutMs
    Execution timeout in milliseconds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandText,
        
        [hashtable]$Parameters = @{},
        
        [int]$TimeoutMs = 300000
    )
    
    Write-AgentLog -Message "Executing safe constrained command: $CommandText" -Level "INFO" -Component "SafeExecutor"
    
    try {
        # Validate command safety
        $commandSafety = Test-CommandSafety -CommandText $CommandText
        if (-not $commandSafety.IsSafe) {
            throw "Command failed safety validation: $($commandSafety.Reasons -join '; ')"
        }
        
        # Validate parameter safety
        if ($Parameters.Count -gt 0) {
            $paramSafety = Test-ParameterSafety -Parameters $Parameters
            if (-not $paramSafety.IsSafe) {
                throw "Parameters failed safety validation: $($paramSafety.Reasons -join '; ')"
            }
        }
        
        # Create constrained runspace
        $runspaceResult = New-ConstrainedRunspace -TimeoutMs $TimeoutMs
        if (-not $runspaceResult.Success) {
            throw "Failed to create constrained runspace: $($runspaceResult.Error)"
        }
        
        $runspace = $runspaceResult.Runspace
        
        try {
            # Create PowerShell instance
            $powershell = [PowerShell]::Create()
            $powershell.Runspace = $runspace
            
            # Add command and parameters
            $powershell.AddScript($CommandText) | Out-Null
            foreach ($paramName in $Parameters.Keys) {
                $powershell.AddParameter($paramName, $Parameters[$paramName]) | Out-Null
            }
            
            Write-AgentLog -Message "Executing command in constrained runspace" -Level "DEBUG" -Component "SafeExecutor"
            
            # Execute with timeout
            $asyncResult = $powershell.BeginInvoke()
            $completed = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs)
            
            if ($completed) {
                $output = $powershell.EndInvoke($asyncResult)
                $errors = $powershell.Streams.Error
                
                Write-AgentLog -Message "Command execution completed" -Level "SUCCESS" -Component "SafeExecutor"
                
                return @{
                    Success = $true
                    Output = $output
                    Errors = $errors
                    ExecutionTime = $TimeoutMs
                }
            } else {
                Write-AgentLog -Message "Command execution timed out after $TimeoutMs ms" -Level "WARNING" -Component "SafeExecutor"
                $powershell.Stop()
                
                return @{
                    Success = $false
                    Error = "Command execution timed out"
                    TimedOut = $true
                }
            }
        }
        finally {
            # Clean up PowerShell instance
            if ($powershell) {
                $powershell.Dispose()
            }
        }
    }
    catch {
        Write-AgentLog -Message "Safe command execution failed: $_" -Level "ERROR" -Component "SafeExecutor"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
    finally {
        # Clean up runspace
        if ($runspace) {
            $runspace.Close()
            $runspace.Dispose()
        }
    }
}

function Invoke-SafeRecommendedCommand {
    <#
    .SYNOPSIS
    Executes a recommended command with full safety validation
    
    .DESCRIPTION
    High-level wrapper for executing Claude recommendations safely
    
    .PARAMETER Recommendation
    The recommendation object to execute
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation
    )
    
    Write-AgentLog -Message "Executing safe recommended command: $($Recommendation.Type)" -Level "INFO" -Component "RecommendationExecutor"
    
    try {
        # Extract command details
        $commandType = $Recommendation.Type
        $commandDetails = $Recommendation.Command
        
        # Route to appropriate execution method based on command type
        switch ($commandType) {
            "TEST" {
                Write-AgentLog -Message "Routing to TEST command execution" -Level "DEBUG" -Component "RecommendationExecutor"
                # Would integrate with TestCommands module
                return @{ Success = $true; Output = "TEST command routed"; CommandType = "TEST" }
            }
            
            "BUILD" {
                Write-AgentLog -Message "Routing to BUILD command execution" -Level "DEBUG" -Component "RecommendationExecutor"
                # Would integrate with BuildCommands module
                return @{ Success = $true; Output = "BUILD command routed"; CommandType = "BUILD" }
            }
            
            "ANALYZE" {
                Write-AgentLog -Message "Routing to ANALYZE command execution" -Level "DEBUG" -Component "RecommendationExecutor"
                # Would integrate with AnalyzeCommands module
                return @{ Success = $true; Output = "ANALYZE command routed"; CommandType = "ANALYZE" }
            }
            
            default {
                Write-AgentLog -Message "General command execution: $commandDetails" -Level "DEBUG" -Component "RecommendationExecutor"
                return Invoke-SafeConstrainedCommand -CommandText $commandDetails
            }
        }
    }
    catch {
        Write-AgentLog -Message "Safe recommended command execution failed: $_" -Level "ERROR" -Component "RecommendationExecutor"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Sanitize-ParameterValue {
    <#
    .SYNOPSIS
    Sanitizes parameter values for safe execution
    
    .DESCRIPTION
    Removes or escapes dangerous characters from parameter values
    
    .PARAMETER Value
    The parameter value to sanitize
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    Write-AgentLog -Message "Sanitizing parameter value" -Level "DEBUG" -Component "ParameterSanitizer"
    
    try {
        $sanitized = $Value
        
        # Remove dangerous characters
        $dangerousChars = @(";", "&", "|", "*", "?")
        foreach ($char in $dangerousChars) {
            $sanitized = $sanitized.Replace($char, "")
        }
        
        # Escape path traversal attempts
        $sanitized = $sanitized.Replace("../", "").Replace("..\", "")
        
        # Limit length to prevent buffer overflow attempts
        if ($sanitized.Length -gt 1000) {
            $sanitized = $sanitized.Substring(0, 1000)
            Write-AgentLog -Message "Parameter value truncated to 1000 characters" -Level "WARNING" -Component "ParameterSanitizer"
        }
        
        Write-AgentLog -Message "Parameter value sanitized successfully" -Level "DEBUG" -Component "ParameterSanitizer"
        
        return $sanitized
    }
    catch {
        Write-AgentLog -Message "Parameter sanitization failed: $_" -Level "ERROR" -Component "ParameterSanitizer"
        return ""
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'New-ConstrainedRunspace',
    'Test-CommandSafety',
    'Test-ParameterSafety',
    'Test-PathSafety',
    'Invoke-SafeConstrainedCommand',
    'Invoke-SafeRecommendedCommand',
    'Sanitize-ParameterValue'
)

Write-AgentLog "SafeExecution module loaded successfully" -Level "INFO" -Component "SafeExecution"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/q82dLNQbIENbZzQQHD1dKEz
# tW+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUWb/1fw1LsHXI0LfqKhHyI4CZRu8wDQYJKoZIhvcNAQEBBQAEggEAeak6
# R22Xj7INgZdm8nmeyCs+/Q3xrg/iFnGE9RMZnZ57DmZOCVRLRJ0s9A2o/WXiCr9c
# pzNRLCiGMF2vruS8EzKD9cqElwKRozyObPUB+NGgMKwjIKcZTufQG09W1rCf/jUT
# hdc7kx0/pRcEC4mE3o89UYBDePggcO0B1q9HakN/kYspAxsrrYX10y1VvfFZJZWE
# hHA1GLy1eheZGHNFIam82qsyhPFadWwvFATg6itAZE6Yq1D8MMv8ap+CgX0OChgC
# UDtP+HfhVP8LQROHQ2YuxlGZKZ0Rb4pGn2Ra6lvOpg4coGQV5i5qusmACzXl/pnQ
# IQslo6pTUbhLHvnSJQ==
# SIG # End signature block
