function New-AutonomousPrompt {
    <#
    .SYNOPSIS
        Creates an intelligent autonomous prompt with boilerplate integration
        
    .DESCRIPTION
        Constructs prompts for autonomous operations, integrating boilerplate text,
        directives, and context-aware content generation
        
    .PARAMETER BasePrompt
        The base prompt text to enhance
        
    .PARAMETER Context
        Additional context information to include
        
    .PARAMETER IncludeDirective
        Whether to include the simple directive for response formatting
        
    .PARAMETER Priority
        Priority level for the prompt (High, Medium, Low)
        
    .OUTPUTS
        String - The constructed autonomous prompt
        
    .EXAMPLE
        $prompt = New-AutonomousPrompt -BasePrompt "Analyze test results" -Context $testResults -Priority "High"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePrompt,
        
        [string]$Context = "",
        [switch]$IncludeDirective,
        [ValidateSet("High", "Medium", "Low")]
        [string]$Priority = "Medium"
    )
    
    # Initialize script variables if not already set
    if (-not $script:SimpleDirective) {
        $script:SimpleDirective = " ================================================== CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH: [RECOMMENDATION: CONTINUE]; [RECOMMENDATION: TEST <Name>]; [RECOMMENDATION: FIX <File>]; [RECOMMENDATION: COMPILE]; [RECOMMENDATION: RESTART <Module>]; [RECOMMENDATION: COMPLETE]; [RECOMMENDATION: ERROR <Description>]=================================================="
    }
    
    if (-not $script:BoilerplatePrompt) {
        try {
            $boilerplatePath = Join-Path $PSScriptRoot "..\..\Resources\BoilerplatePrompt.txt"
            if (Test-Path $boilerplatePath) {
                $script:BoilerplatePrompt = Get-Content -Path $boilerplatePath -Raw
            }
        } catch {
            Write-Host "Warning: Could not load boilerplate prompt file: $_" -ForegroundColor Yellow
        }
        
        if (-not $script:BoilerplatePrompt) {
            # Fallback to simple directive if file not found
            $script:BoilerplatePrompt = "Please process the following recommendation and provide a detailed response."
        }
    }
    
    try {
        Write-Host "Creating autonomous prompt..." -ForegroundColor Cyan
        Write-Host "  Base Prompt Length: $($BasePrompt.Length) characters" -ForegroundColor Gray
        Write-Host "  Priority: $Priority" -ForegroundColor Gray
        
        $promptBuilder = @()
        
        # Add priority indicator
        $priorityIndicator = switch ($Priority) {
            "High" { "[HIGH PRIORITY TASK]" }
            "Medium" { "[STANDARD TASK]" }
            "Low" { "[LOW PRIORITY TASK]" }
        }
        $promptBuilder += $priorityIndicator
        $promptBuilder += ""
        
        # Add boilerplate if available
        if ($script:BoilerplatePrompt -and $script:BoilerplatePrompt.Trim()) {
            $promptBuilder += "SYSTEM CONTEXT:"
            $promptBuilder += $script:BoilerplatePrompt.Trim()
            $promptBuilder += ""
            $promptBuilder += "TASK REQUEST:"
        }
        
        # Add base prompt
        $promptBuilder += $BasePrompt.Trim()
        
        # Add context if provided
        if ($Context -and $Context.Trim()) {
            $promptBuilder += ""
            $promptBuilder += "ADDITIONAL CONTEXT:"
            $promptBuilder += $Context.Trim()
        }
        
        # Add directive if requested
        if ($IncludeDirective) {
            $promptBuilder += ""
            $promptBuilder += "RESPONSE REQUIREMENTS:"
            $promptBuilder += $script:SimpleDirective
        }
        
        # Add timestamp
        $promptBuilder += ""
        $promptBuilder += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        $finalPrompt = $promptBuilder -join "`n"
        
        Write-Host "  Final Prompt Length: $($finalPrompt.Length) characters" -ForegroundColor Gray
        Write-Host "Autonomous prompt created successfully" -ForegroundColor Green
        
        return $finalPrompt
        
    } catch {
        Write-Host "Error creating autonomous prompt: $_" -ForegroundColor Red
        throw
    }
}