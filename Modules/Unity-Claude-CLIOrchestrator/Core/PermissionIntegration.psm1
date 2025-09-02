# PermissionIntegration.psm1
# Integrates permission handling into CLIOrchestrator workflow

#region Module Initialization

$script:PermissionIntegrationConfig = @{
    Initialized = $false
    SafeOperationsEnabled = $false
    InterceptorEnabled = $false
    Mode = "Intelligent"
    Statistics = @{
        PromptsProcessed = 0
        PermissionsHandled = 0
        SafeConversions = 0
    }
}

#endregion

#region Integration Functions

function Initialize-PermissionIntegration {
    <#
    .SYNOPSIS
        Initializes permission handling integration with CLIOrchestrator
    .DESCRIPTION
        Sets up permission handlers, safe operations, and interceptors for the orchestrator
    .PARAMETER Mode
        Permission handling mode: Intelligent, Manual, or Passive
    .PARAMETER EnableSafeOperations
        Enable automatic conversion of destructive operations
    .PARAMETER EnableInterceptor
        Enable real-time permission prompt interception
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Intelligent", "Manual", "Passive")]
        [string]$Mode = "Intelligent",
        
        [switch]$EnableSafeOperations,
        
        [switch]$EnableInterceptor
    )
    
    try {
        Write-Verbose "Initializing permission integration..."
        
        # Initialize Safe Operations if enabled
        if ($EnableSafeOperations) {
            Write-Verbose "Initializing Safe Operations Handler..."
            $safeOpsResult = Initialize-SafeOperations -GitAutoCommit:$true
            
            if ($safeOpsResult.Success) {
                $script:PermissionIntegrationConfig.SafeOperationsEnabled = $true
                Write-Host "  ✅ Safe Operations enabled" -ForegroundColor Green
            } else {
                Write-Warning "Safe Operations initialization failed"
            }
        }
        
        # Initialize Permission Interceptor if enabled
        if ($EnableInterceptor) {
            Write-Verbose "Initializing Permission Interceptor..."
            
            # Create integrated permission handler as a hashtable with a handler scriptblock
            $handlerScript = Get-IntegratedPermissionHandler -Mode $Mode
            $permissionHandler = @{
                Handler = $handlerScript
                Mode = $Mode
                Config = @{
                    AutoApproveProjectFiles = $true
                    BlockSystemOperations = $true
                }
            }
            
            try {
                Start-ClaudePermissionInterceptor -PermissionHandler $permissionHandler
                $script:PermissionIntegrationConfig.InterceptorEnabled = $true
                Write-Host "  ✅ Permission Interceptor enabled" -ForegroundColor Green
            } catch {
                Write-Warning "Permission Interceptor initialization failed: $_"
            }
        }
        
        $script:PermissionIntegrationConfig.Mode = $Mode
        $script:PermissionIntegrationConfig.Initialized = $true
        
        return @{
            Success = $true
            Mode = $Mode
            SafeOperations = $script:PermissionIntegrationConfig.SafeOperationsEnabled
            Interceptor = $script:PermissionIntegrationConfig.InterceptorEnabled
        }
        
    } catch {
        Write-Error "Failed to initialize permission integration: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-IntegratedPermissionHandler {
    <#
    .SYNOPSIS
        Creates an integrated permission handler for the orchestrator
    .DESCRIPTION
        Returns a scriptblock that handles permissions based on the specified mode
    .PARAMETER Mode
        Permission handling mode
    #>
    param(
        [string]$Mode = "Intelligent"
    )
    
    $handler = {
        param($PromptInfo)
        
        # Import the safe operations module in the handler scope
        Import-Module "$PSScriptRoot\SafeOperationsHandler.psm1" -Force
        
        # Define safe operations
        $safeTools = @('Read', 'Bash', 'Grep', 'Glob', 'WebSearch', 'WebFetch')
        $safeCommands = @(
            'git status', 'git diff', 'git log', 'git branch',
            'npm test', 'npm run', 'npm list',
            'ls', 'pwd', 'echo', 'cat', 'grep', 'find',
            'dotnet build', 'dotnet test'
        )
        
        $riskyTools = @('Write', 'Edit', 'MultiEdit')
        $dangerousTools = @('Remove-Item', 'rm', 'del', 'Clear-Content')
        
        # Extract tool/command from prompt
        $text = $PromptInfo.OriginalText
        
        # Check for safe tools
        foreach ($tool in $safeTools) {
            if ($text -match "Allow $tool\b") {
                return @{
                    Action = "approve"
                    Response = "y"
                    Reason = "Safe tool: $tool"
                    Confidence = 0.95
                }
            }
        }
        
        # Check for safe commands
        foreach ($cmd in $safeCommands) {
            if ($text -match [regex]::Escape($cmd)) {
                return @{
                    Action = "approve"
                    Response = "y"
                    Reason = "Safe command: $cmd"
                    Confidence = 0.90
                }
            }
        }
        
        # Check for dangerous operations
        foreach ($tool in $dangerousTools) {
            if ($text -match $tool) {
                # Try to convert to safe operation
                if ($script:PermissionIntegrationConfig.SafeOperationsEnabled) {
                    $safeOp = Convert-ToSafeOperation -Command $text
                    if ($safeOp.WasConverted) {
                        return @{
                            Action = "convert"
                            Response = "n"  # Deny original
                            SafeCommand = $safeOp.SafeCommand
                            Reason = "Converted to safe operation: $($safeOp.Explanation)"
                            Confidence = 0.85
                        }
                    }
                }
                
                # Otherwise deny
                return @{
                    Action = "deny"
                    Response = "n"
                    Reason = "Dangerous operation: $tool"
                    Confidence = 0.95
                }
            }
        }
        
        # Check for risky tools (require confirmation in Manual mode)
        if ($Mode -eq "Manual") {
            foreach ($tool in $riskyTools) {
                if ($text -match "Allow $tool\b") {
                    return @{
                        Action = "manual"
                        Response = $null
                        Reason = "Risky tool requires manual confirmation: $tool"
                        Confidence = 0.70
                    }
                }
            }
        } else {
            # In Intelligent mode, approve risky tools for project files
            foreach ($tool in $riskyTools) {
                if ($text -match "Allow $tool\b" -and $text -match "Unity-Claude-Automation") {
                    return @{
                        Action = "approve"
                        Response = "y"
                        Reason = "Risky tool approved for project files: $tool"
                        Confidence = 0.80
                    }
                }
            }
        }
        
        # Default based on mode
        switch ($Mode) {
            "Intelligent" {
                # Make intelligent decision based on context
                if ($text -match "Unity-Claude-Automation" -or $text -match "project") {
                    return @{
                        Action = "approve"
                        Response = "y"
                        Reason = "Project-related operation"
                        Confidence = 0.75
                    }
                } else {
                    return @{
                        Action = "manual"
                        Response = $null
                        Reason = "Unknown operation requires review"
                        Confidence = 0.50
                    }
                }
            }
            "Manual" {
                return @{
                    Action = "manual"
                    Response = $null
                    Reason = "Manual mode - user confirmation required"
                    Confidence = 0.00
                }
            }
            "Passive" {
                return @{
                    Action = "monitor"
                    Response = $null
                    Reason = "Passive mode - monitoring only"
                    Confidence = 0.00
                }
            }
        }
    }
    
    return $handler
}

function Submit-ClaudePromptWithPermissions {
    <#
    .SYNOPSIS
        Submits a prompt to Claude with integrated permission handling
    .DESCRIPTION
        Enhanced version of Submit-ClaudePrompt that includes permission handling
    .PARAMETER Prompt
        The prompt to submit
    .PARAMETER UseSafeOperations
        Convert destructive operations to safe alternatives
    .PARAMETER WaitForResponse
        Wait for Claude's response
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [switch]$UseSafeOperations,
        
        [switch]$WaitForResponse = $true
    )
    
    try {
        # Update statistics
        $script:PermissionIntegrationConfig.Statistics.PromptsProcessed++
        
        # Pre-process prompt for safe operations if enabled
        if ($UseSafeOperations -and $script:PermissionIntegrationConfig.SafeOperationsEnabled) {
            Write-Verbose "Checking prompt for destructive operations..."
            
            # Check if prompt contains destructive commands
            $destructivePatterns = @(
                'remove-item', 'rm -rf', 'del ', 'delete',
                'clear-content', 'git reset --hard',
                'drop table', 'truncate'
            )
            
            foreach ($pattern in $destructivePatterns) {
                if ($Prompt -match $pattern) {
                    Write-Host "⚠️ Detected potentially destructive operation: $pattern" -ForegroundColor Yellow
                    
                    # Convert to safe operation
                    $safeResult = Convert-ToSafeOperation -Command $Prompt
                    if ($safeResult.WasConverted) {
                        Write-Host "✅ Converted to safe operation: $($safeResult.Explanation)" -ForegroundColor Green
                        $Prompt = $safeResult.SafeCommand
                        $script:PermissionIntegrationConfig.Statistics.SafeConversions++
                    }
                }
            }
        }
        
        # Submit the prompt using the orchestrator
        Write-Verbose "Submitting prompt to Claude..."
        $result = Submit-ClaudePrompt -Prompt $Prompt -WaitForResponse:$WaitForResponse
        
        # If interceptor is enabled, it will handle permission prompts automatically
        if ($script:PermissionIntegrationConfig.InterceptorEnabled) {
            Write-Verbose "Permission interceptor is handling any permission prompts..."
        }
        
        return $result
        
    } catch {
        Write-Error "Failed to submit prompt with permissions: $_"
        throw
    }
}

function Get-PermissionIntegrationStatus {
    <#
    .SYNOPSIS
        Gets the current status of permission integration
    .DESCRIPTION
        Returns detailed status information about the permission handling system
    #>
    [CmdletBinding()]
    param()
    
    $status = @{
        Initialized = $script:PermissionIntegrationConfig.Initialized
        Mode = $script:PermissionIntegrationConfig.Mode
        Components = @{
            SafeOperations = @{
                Enabled = $script:PermissionIntegrationConfig.SafeOperationsEnabled
                Status = if ($script:PermissionIntegrationConfig.SafeOperationsEnabled) { "Active" } else { "Disabled" }
            }
            Interceptor = @{
                Enabled = $script:PermissionIntegrationConfig.InterceptorEnabled
                Status = if ($script:PermissionIntegrationConfig.InterceptorEnabled) { "Active" } else { "Disabled" }
            }
        }
        Statistics = $script:PermissionIntegrationConfig.Statistics
    }
    
    # Add permission handler statistics if available
    try {
        $permStats = Get-PermissionStatistics -ErrorAction SilentlyContinue
        if ($permStats) {
            $status.PermissionStatistics = $permStats
        }
    } catch {
        # Permission handler might not be loaded
    }
    
    return $status
}

#endregion

#region Export

Export-ModuleMember -Function @(
    'Initialize-PermissionIntegration',
    'Submit-ClaudePromptWithPermissions',
    'Get-PermissionIntegrationStatus',
    'Get-IntegratedPermissionHandler'
)

#endregion