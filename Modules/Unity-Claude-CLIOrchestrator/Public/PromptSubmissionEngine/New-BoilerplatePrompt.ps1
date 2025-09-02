function New-BoilerplatePrompt {
    <#
    .SYNOPSIS
        Creates properly formatted boilerplate prompts for Claude Code CLI submission
        
    .DESCRIPTION
        Builds prompts using the standard boilerplate template with proper prompt-type 
        formatting as specified in the boilerplate requirements. 
        Format: "[BOILERPLATE PROMPT] [PROMPT-TYPE] - [DETAILS/FILE_PATHS]"
        
    .PARAMETER PromptType
        The type of prompt (Testing, Debugging, ARP, Continue, Review)
        
    .PARAMETER Details
        Specific details, file paths, or additional instructions for the prompt
        
    .PARAMETER FilePaths
        Optional array of file paths to include in the prompt
        
    .OUTPUTS
        String - Complete formatted prompt ready for submission
        
    .EXAMPLE
        $prompt = New-BoilerplatePrompt -PromptType "Testing" -Details "Please analyze the results from running Test-CLIOrchestrator-FullFeatured.ps1" -FilePaths @("Test-Results-20250828.json")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Testing", "Debugging", "ARP", "Continue", "Review")]
        [string]$PromptType,
        
        [Parameter(Mandatory=$true)]
        [string]$Details,
        
        [string[]]$FilePaths = @(),
        
        [string]$BoilerplateResourcePath = ".\Modules\Unity-Claude-CLIOrchestrator\Resources\BoilerplatePrompt.txt"
    )
    
    try {
        Write-Host "Building boilerplate prompt..." -ForegroundColor Cyan
        Write-Host "  Prompt Type: $PromptType" -ForegroundColor Gray
        Write-Host "  Details: $Details" -ForegroundColor Gray
        
        # Load boilerplate template
        if (Test-Path $BoilerplateResourcePath) {
            $boilerplateTemplate = Get-Content -Path $BoilerplateResourcePath -Raw
            Write-Host "  Loaded boilerplate template ($($boilerplateTemplate.Length) characters)" -ForegroundColor Gray
        } else {
            Write-Warning "Boilerplate template not found at: $BoilerplateResourcePath"
            Write-Host "  Using fallback minimal boilerplate" -ForegroundColor Yellow
            $boilerplateTemplate = @"
#Important: if the Claude Code root directory is Unity-Claude-Automation/ then the current project is Unity Claude Automation, NOT Symbolic Memory.

#Instruction
You are an expert software developer who always wants to have all the information they need before starting on a task.

***END OF BOILERPLATE***
"@
        }
        
        # Build the file paths section if provided
        $filePathsSection = ""
        if ($FilePaths -and $FilePaths.Count -gt 0) {
            $filePathsSection = " Files: " + ($FilePaths -join ", ")
        }
        
        # Construct the complete prompt in the required format
        # Format: "[BOILERPLATE PROMPT] [PROMPT-TYPE] - [DETAILS/FILE_PATHS]"
        $completePrompt = @"
$boilerplateTemplate

//Prompt type, additional instructions, and parameters below:
$PromptType`: $Details$filePathsSection
"@
        
        Write-Host "  Complete prompt built successfully" -ForegroundColor Green
        Write-Host "  Total length: $($completePrompt.Length) characters" -ForegroundColor Gray
        
        return $completePrompt
        
    } catch {
        Write-Error "Error building boilerplate prompt: $_"
        
        # Fallback: Return a simple prompt format
        $fallbackPrompt = "$PromptType`: $Details"
        if ($FilePaths -and $FilePaths.Count -gt 0) {
            $fallbackPrompt += " Files: " + ($FilePaths -join ", ")
        }
        
        Write-Warning "Using fallback prompt format: $fallbackPrompt"
        return $fallbackPrompt
    }
}

function Submit-BoilerplatePrompt {
    <#
    .SYNOPSIS
        Builds and submits a properly formatted boilerplate prompt to Claude
        
    .DESCRIPTION
        Combines boilerplate prompt building with submission in a single operation
        
    .PARAMETER PromptType
        The type of prompt (Testing, Debugging, ARP, Continue, Review)
        
    .PARAMETER Details
        Specific details, file paths, or additional instructions for the prompt
        
    .PARAMETER FilePaths
        Optional array of file paths to include in the prompt
        
    .OUTPUTS
        Boolean - True if submission was successful, False otherwise
        
    .EXAMPLE
        $success = Submit-BoilerplatePrompt -PromptType "Testing" -Details "Please analyze test results" -FilePaths @("results.json")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Testing", "Debugging", "ARP", "Continue", "Review")]
        [string]$PromptType,
        
        [Parameter(Mandatory=$true)]
        [string]$Details,
        
        [string[]]$FilePaths = @()
    )
    
    try {
        Write-Host ""
        Write-Host "[BOILERPLATE SUBMISSION] Building and submitting prompt..." -ForegroundColor Cyan
        
        # Build the complete boilerplate prompt
        $completePrompt = New-BoilerplatePrompt -PromptType $PromptType -Details $Details -FilePaths $FilePaths
        
        if (-not $completePrompt) {
            Write-Host "[ERROR] Failed to build boilerplate prompt" -ForegroundColor Red
            return $false
        }
        
        # Submit using the enhanced clipboard-based method
        $success = Submit-ToClaudeViaTypeKeys -PromptText $completePrompt
        
        if ($success) {
            Write-Host "[SUCCESS] Boilerplate prompt submitted successfully!" -ForegroundColor Green
            Write-Host "  Prompt Type: $PromptType" -ForegroundColor Gray
            Write-Host "  Total Length: $($completePrompt.Length) characters" -ForegroundColor Gray
        } else {
            Write-Host "[ERROR] Boilerplate prompt submission failed" -ForegroundColor Red
        }
        
        return $success
        
    } catch {
        Write-Host "[ERROR] Exception in boilerplate prompt submission: $_" -ForegroundColor Red
        return $false
    }
}

# Export functions only if loaded as part of a module
# When dot-sourced directly, Export-ModuleMember will cause an error
if ($MyInvocation.MyCommand.Module) {
    Export-ModuleMember -Function @(
        'New-BoilerplatePrompt',
        'Submit-BoilerplatePrompt'
    )
}
# Functions are automatically available when dot-sourced