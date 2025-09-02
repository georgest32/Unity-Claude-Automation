# IntelligentPromptEngine-Refactored.psm1
# Refactored orchestrator for intelligent prompt generation engine
# Modular architecture with component imports
# Version: 2.0.0 - Refactored from 1,457-line monolithic module

# Module self-registration for session visibility
if (-not $ExecutionContext.SessionState.Module) {
    $ModuleName = 'IntelligentPromptEngine'
    if (-not (Get-Module -Name $ModuleName)) {
        # Module is being imported but not yet visible in session
        Write-Verbose "[$ModuleName] Ensuring module registration in session" -Verbose:$false
    }
} else {
    # Module context is properly established
    Write-Verbose "[$($ExecutionContext.SessionState.Module.Name)] Module context established" -Verbose:$false
}

#region Import Required Components

# Import logging functionality first
Import-Module "$PSScriptRoot\Core\AgentLogging.psm1" -Force

# Import core configuration and collections
Import-Module "$PSScriptRoot\Core\PromptConfiguration.psm1" -Force

# Import result analysis engine
Import-Module "$PSScriptRoot\Core\ResultAnalysisEngine.psm1" -Force

# Import prompt type selection logic
Import-Module "$PSScriptRoot\Core\PromptTypeSelection.psm1" -Force

# Import template management system
Import-Module "$PSScriptRoot\Core\PromptTemplateSystem.psm1" -Force

Write-AgentLog -Message "IntelligentPromptEngine-Refactored: All core components imported successfully" -Level "INFO" -Component "PromptEngineOrchestrator"

#endregion

#region Enhanced Orchestration Functions

function Invoke-IntelligentPromptGeneration {
    <#
    .SYNOPSIS
    Enhanced orchestrated intelligent prompt generation with modular components
    
    .DESCRIPTION
    Orchestrates the complete intelligent prompt generation process using modular components:
    - Command result analysis and classification
    - Decision tree-based prompt type selection
    - Template-based prompt generation with context
    - Comprehensive error handling and fallback mechanisms
    
    .PARAMETER CommandResult
    The result of a command execution to analyze
    
    .PARAMETER ConversationContext
    Current conversation context for decision making
    
    .PARAMETER HistoricalData
    Historical data for pattern recognition and learning
    
    .EXAMPLE
    $result = Invoke-IntelligentPromptGeneration -CommandResult $cmdResult -ConversationContext $context
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$CommandResult,
        
        [Parameter()]
        [hashtable]$ConversationContext = @{},
        
        [Parameter()]
        [hashtable]$HistoricalData = @{}
    )
    
    Write-AgentLog -Message "Starting enhanced intelligent prompt generation orchestration" -Level "INFO" -Component "PromptEngineOrchestrator"
    
    try {
        $generationResult = @{
            Success = $false
            Prompt = ""
            Analysis = @{}
            Selection = @{}
            Template = @{}
            ProcessingTime = 0
            Error = $null
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Step 1: Analyze command result
        Write-AgentLog -Message "Step 1: Analyzing command result" -Level "DEBUG" -Component "PromptEngineOrchestrator"
        $analysisResult = Invoke-CommandResultAnalysis -CommandResult $CommandResult -ConversationContext $ConversationContext -HistoricalData $HistoricalData
        
        if (-not $analysisResult.Success) {
            throw "Result analysis failed: $($analysisResult.Error)"
        }
        
        $generationResult.Analysis = $analysisResult
        Write-AgentLog -Message "Result analysis completed: Classification=$($analysisResult.Analysis.Classification), Confidence=$($analysisResult.Analysis.Confidence)" -Level "INFO" -Component "PromptEngineOrchestrator"
        
        # Step 2: Select prompt type using decision tree
        Write-AgentLog -Message "Step 2: Selecting prompt type using decision tree" -Level "DEBUG" -Component "PromptEngineOrchestrator"
        $selectionResult = Invoke-PromptTypeSelection -ResultAnalysis $analysisResult -ConversationContext $ConversationContext -HistoricalData $HistoricalData
        
        if (-not $selectionResult.Success) {
            throw "Prompt type selection failed: $($selectionResult.Error)"
        }
        
        $generationResult.Selection = $selectionResult
        Write-AgentLog -Message "Prompt type selected: $($selectionResult.Selection.PromptType) with confidence $($selectionResult.Selection.Confidence)" -Level "INFO" -Component "PromptEngineOrchestrator"
        
        # Step 3: Create and render prompt template
        Write-AgentLog -Message "Step 3: Creating and rendering prompt template" -Level "DEBUG" -Component "PromptEngineOrchestrator"
        $templateResult = New-PromptTemplate -TemplateType $selectionResult.Selection.PromptType -ResultAnalysis $analysisResult -ConversationContext $ConversationContext -HistoricalData $HistoricalData
        
        if (-not $templateResult.Success) {
            throw "Template creation failed: $($templateResult.Error)"
        }
        
        # Step 4: Render final prompt
        $renderResult = Invoke-TemplateRendering -Template $templateResult.Template -AdditionalContext $ConversationContext
        
        if (-not $renderResult.Success) {
            throw "Template rendering failed: $($renderResult.Error)"
        }
        
        $generationResult.Template = $templateResult
        $generationResult.Prompt = $renderResult.RenderedPrompt
        $generationResult.Success = $true
        
        $stopwatch.Stop()
        $generationResult.ProcessingTime = $stopwatch.ElapsedMilliseconds
        
        Write-AgentLog -Message "Enhanced intelligent prompt generation completed successfully in $($generationResult.ProcessingTime)ms" -Level "INFO" -Component "PromptEngineOrchestrator"
        
        return $generationResult
    }
    catch {
        if ($stopwatch) { $stopwatch.Stop() }
        if ($stopwatch) { $generationResult.ProcessingTime = $stopwatch.ElapsedMilliseconds }
        $generationResult.Error = $_.ToString()
        
        Write-AgentLog -Message "Enhanced intelligent prompt generation failed: $_" -Level "ERROR" -Component "PromptEngineOrchestrator"
        
        # Fallback: Create simple prompt
        $fallbackPrompt = New-FallbackPrompt -CommandResult $CommandResult -Error $_
        $generationResult.Prompt = $fallbackPrompt
        
        return $generationResult
    }
}

function New-FallbackPrompt {
    <#
    .SYNOPSIS
    Creates a simple fallback prompt when intelligent generation fails
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$CommandResult,
        
        [Parameter()]
        [object]$Error
    )
    
    Write-AgentLog -Message "Creating fallback prompt due to generation failure" -Level "WARNING" -Component "PromptEngineOrchestrator"
    
    $fallbackPrompt = "# Fallback Prompt - Analysis Required`n`n"
    $fallbackPrompt += "*Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*`n"
    $fallbackPrompt += "*Note: Intelligent prompt generation encountered an error and fell back to basic mode*`n`n"
    
    $fallbackPrompt += "## Command Result Analysis Needed`n`n"
    $fallbackPrompt += "A command was executed and needs analysis. Please review the following information:`n`n"
    
    if ($CommandResult.ContainsKey('ExitCode')) {
        $fallbackPrompt += "**Exit Code**: $($CommandResult.ExitCode)`n"
    }
    
    if ($CommandResult.ContainsKey('Output') -and $CommandResult.Output) {
        $fallbackPrompt += "**Output**: $($CommandResult.Output.ToString().Substring(0, [Math]::Min(500, $CommandResult.Output.ToString().Length)))"
        if ($CommandResult.Output.ToString().Length -gt 500) {
            $fallbackPrompt += "... (truncated)"
        }
        $fallbackPrompt += "`n"
    }
    
    if ($CommandResult.ContainsKey('Error') -and $CommandResult.Error) {
        $fallbackPrompt += "**Error**: $($CommandResult.Error.ToString().Substring(0, [Math]::Min(300, $CommandResult.Error.ToString().Length)))"
        if ($CommandResult.Error.ToString().Length -gt 300) {
            $fallbackPrompt += "... (truncated)"
        }
        $fallbackPrompt += "`n"
    }
    
    $fallbackPrompt += "`n## Request`n`n"
    $fallbackPrompt += "Please analyze this command result and advise on:"
    $fallbackPrompt += "`n1. Whether the operation was successful or failed"
    $fallbackPrompt += "`n2. Any issues that need to be addressed"
    $fallbackPrompt += "`n3. Recommended next steps"
    $fallbackPrompt += "`n4. Any patterns or insights from the output"
    
    return $fallbackPrompt
}

function Get-PromptEngineStatus {
    <#
    .SYNOPSIS
    Get comprehensive status of the intelligent prompt engine and its components
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog -Message "Gathering intelligent prompt engine status" -Level "DEBUG" -Component "PromptEngineOrchestrator"
    
    try {
        $status = @{
            EngineVersion = "2.0.0"
            Architecture = "Modular"
            Components = @{}
            Configuration = @{}
            Health = "Unknown"
            LastUpdate = Get-Date
        }
        
        # Get configuration
        $config = Get-PromptEngineConfig
        $status.Configuration = $config
        
        # Check component availability
        $components = @{
            'PromptConfiguration' = Test-ComponentAvailability -ComponentName 'Get-PromptEngineConfig'
            'ResultAnalysisEngine' = Test-ComponentAvailability -ComponentName 'Invoke-CommandResultAnalysis'
            'PromptTypeSelection' = Test-ComponentAvailability -ComponentName 'Invoke-PromptTypeSelection'
            'PromptTemplateSystem' = Test-ComponentAvailability -ComponentName 'New-PromptTemplate'
        }
        
        $status.Components = $components
        
        # Determine overall health
        $healthyComponents = ($components.Values | Where-Object { $_ -eq $true }).Count
        $totalComponents = $components.Count
        
        if ($healthyComponents -eq $totalComponents) {
            $status.Health = "Healthy"
        }
        elseif ($healthyComponents -gt ($totalComponents / 2)) {
            $status.Health = "Degraded"
        }
        else {
            $status.Health = "Critical"
        }
        
        Write-AgentLog -Message "Prompt engine status: $($status.Health) ($healthyComponents/$totalComponents components healthy)" -Level "INFO" -Component "PromptEngineOrchestrator"
        
        return @{
            Success = $true
            Status = $status
            Error = $null
        }
    }
    catch {
        Write-AgentLog -Message "Failed to get prompt engine status: $_" -Level "ERROR" -Component "PromptEngineOrchestrator"
        return @{
            Success = $false
            Status = @{}
            Error = $_.ToString()
        }
    }
}

function Test-ComponentAvailability {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComponentName
    )
    
    try {
        $command = Get-Command $ComponentName -ErrorAction SilentlyContinue
        return ($null -ne $command)
    }
    catch {
        return $false
    }
}

function Initialize-IntelligentPromptEngine {
    <#
    .SYNOPSIS
    Initialize the intelligent prompt engine and verify all components are working
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog -Message "Initializing enhanced intelligent prompt engine" -Level "INFO" -Component "PromptEngineOrchestrator"
    
    try {
        $initResult = @{
            Success = $false
            ComponentsInitialized = @()
            ComponentsFailed = @()
            OverallHealth = "Unknown"
            Error = $null
        }
        
        # Test each component
        $components = @(
            @{ Name = "PromptConfiguration"; TestFunction = "Get-PromptEngineConfig" },
            @{ Name = "ResultAnalysisEngine"; TestFunction = "Invoke-CommandResultAnalysis" },
            @{ Name = "PromptTypeSelection"; TestFunction = "Invoke-PromptTypeSelection" },
            @{ Name = "PromptTemplateSystem"; TestFunction = "New-PromptTemplate" }
        )
        
        foreach ($component in $components) {
            try {
                $testCommand = Get-Command $component.TestFunction -ErrorAction SilentlyContinue
                if ($testCommand) {
                    $initResult.ComponentsInitialized += $component.Name
                    Write-AgentLog -Message "Component initialized: $($component.Name)" -Level "DEBUG" -Component "PromptEngineOrchestrator"
                }
                else {
                    $initResult.ComponentsFailed += $component.Name
                    Write-AgentLog -Message "Component failed to initialize: $($component.Name)" -Level "WARNING" -Component "PromptEngineOrchestrator"
                }
            }
            catch {
                $initResult.ComponentsFailed += $component.Name
                Write-AgentLog -Message "Component initialization error: $($component.Name) - $_" -Level "ERROR" -Component "PromptEngineOrchestrator"
            }
        }
        
        # Determine overall health
        $healthyCount = $initResult.ComponentsInitialized.Count
        $totalCount = $components.Count
        
        if ($healthyCount -eq $totalCount) {
            $initResult.OverallHealth = "Healthy"
            $initResult.Success = $true
        }
        elseif ($healthyCount -gt ($totalCount / 2)) {
            $initResult.OverallHealth = "Degraded"
            $initResult.Success = $true
        }
        else {
            $initResult.OverallHealth = "Critical"
            $initResult.Success = $false
            $initResult.Error = "Critical component failures prevent engine operation"
        }
        
        Write-AgentLog -Message "Intelligent prompt engine initialization complete: $($initResult.OverallHealth) ($healthyCount/$totalCount components)" -Level "INFO" -Component "PromptEngineOrchestrator"
        
        return $initResult
    }
    catch {
        Write-AgentLog -Message "Intelligent prompt engine initialization failed: $_" -Level "ERROR" -Component "PromptEngineOrchestrator"
        return @{
            Success = $false
            ComponentsInitialized = @()
            ComponentsFailed = @()
            OverallHealth = "Critical"
            Error = $_.ToString()
        }
    }
}

#endregion

#region Module Exports

# Export all orchestration functions
Export-ModuleMember -Function @(
    'Invoke-IntelligentPromptGeneration',
    'Get-PromptEngineStatus', 
    'Initialize-IntelligentPromptEngine'
)

# Re-export key component functions for direct access
Export-ModuleMember -Function @(
    'Get-PromptEngineConfig',
    'Invoke-CommandResultAnalysis',
    'Invoke-PromptTypeSelection',
    'New-PromptTemplate'
)

Write-AgentLog -Message "IntelligentPromptEngine-Refactored module loaded successfully with modular architecture" -Level "INFO" -Component "PromptEngineOrchestrator"

#endregion

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDsLJ8wu84ZBbMt
# V1H2ayu9P1TK0aEdCR/Lw+jXue7MfaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAYZlFyeFlPgGJIuZ5vnWceb
# rT5VZqHdE/hK4/51KYz3MA0GCSqGSIb3DQEBAQUABIIBAC72BZVKAgDUg6Byqsl1
# xrklfJAeoozvlvyE9zbtGAgMi2a9kYeDk1q5nmyuKoZrvbSYiV3obODkCr/6YT+d
# T9ZFDQgcOV2PRoh4j3XDZrjMvaDmJ7ROJC0GeMXL1HVRidDhyWIbqwS9KspaeQwI
# /PkaPuLE8KTekLaN3wha2GiVFti1DyElVAoiNv8v63aN2XzDIZatA+QVdr5Tk7vX
# X0q11ssGWvfdMFsX8eIb6p5deo0lWklE6S8t1RA1CA4dZqBCZ669ZZr1hADLpCgz
# SLOHj+JQsQ1SKt52O1ar84cLW/zo4vjmIru1vgJFV3WkixZX1bqkY7dY3cxGhSMl
# LeE=
# SIG # End signature block
