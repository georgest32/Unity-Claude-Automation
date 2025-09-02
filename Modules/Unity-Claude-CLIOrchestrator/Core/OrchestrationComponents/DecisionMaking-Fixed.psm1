# DecisionMaking-Fixed.psm1
# Simplified version with just the essential functions for testing

function Invoke-ComprehensiveResponseAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive analysis of Claude response
    #>
    [CmdletBinding()]
    param(
        [string]$ResponseFile
    )
    
    try {
        Write-Host "    Performing comprehensive response analysis..." -ForegroundColor Cyan
        
        if (-not (Test-Path $ResponseFile)) {
            throw "Response file not found: $ResponseFile"
        }
        
        # Read and parse response
        $responseContent = Get-Content -Path $ResponseFile -Raw
        $responseData = $responseContent | ConvertFrom-Json
        
        $analysis = [PSCustomObject]@{
            Timestamp = Get-Date
            ResponseFile = $ResponseFile
            PromptType = $null
            Confidence = 0
            Entities = @{}
            Recommendations = @()
            RequiresAction = $false
            ActionType = $null
            Priority = "Normal"
            SafetyCheck = "Passed"
        }
        
        # Determine prompt type
        if ($responseData.prompt_type) {
            $analysis.PromptType = $responseData.prompt_type
        }
        elseif ($responseData."prompt-type") {
            $analysis.PromptType = $responseData."prompt-type"
        }
        elseif ($responseData.task -match "test|validate|verify") {
            $analysis.PromptType = "Testing"
        }
        elseif ($responseData.task -match "debug|fix|resolve") {
            $analysis.PromptType = "Debugging"
        }
        else {
            $analysis.PromptType = "General"
        }
        
        Write-Host "      Prompt Type: $($analysis.PromptType)" -ForegroundColor Gray
        
        # Extract entities and recommendations
        if ($responseData.RESPONSE) {
            $response = $responseData.RESPONSE
            
            # Check for recommendations
            if ($response -match "RECOMMENDATION:\s*(.+)") {
                $analysis.Recommendations += $matches[1]
                $analysis.RequiresAction = $true
            }
            
            # Check for specific actions
            if ($response -match "(FIX|EXECUTE|COMPILE|DEBUG|TEST)") {
                $analysis.ActionType = $matches[1]
                $analysis.RequiresAction = $true
            }
            
            # Determine priority
            if ($response -match "CRITICAL|URGENT|HIGH") {
                $analysis.Priority = "High"
            }
            elseif ($response -match "LOW|MINOR") {
                $analysis.Priority = "Low"
            }
        }
        
        # Calculate confidence based on data completeness
        $confidenceFactors = 0
        if ($analysis.PromptType -ne "General") { $confidenceFactors += 20 }
        if ($analysis.Recommendations.Count -gt 0) { $confidenceFactors += 20 }
        if ($responseData.test_results) { $confidenceFactors += 20 }
        if ($responseData.analysis_complete) { $confidenceFactors += 20 }
        if ($analysis.ActionType) { $confidenceFactors += 20 }
        
        $analysis.Confidence = $confidenceFactors
        
        Write-Host "      Analysis Confidence: $($analysis.Confidence)%" -ForegroundColor Gray
        Write-Host "      Requires Action: $($analysis.RequiresAction)" -ForegroundColor Gray
        
        return $analysis
    }
    catch {
        Write-Host "ERROR in Invoke-ComprehensiveResponseAnalysis: $_" -ForegroundColor Red
        return $null
    }
}

function Invoke-AutonomousDecisionMaking {
    <#
    .SYNOPSIS
        Makes autonomous decisions based on response analysis
    #>
    [CmdletBinding()]
    param(
        [string]$ResponseFile
    )
    
    try {
        Write-Host "    Making autonomous decision..." -ForegroundColor Cyan
        
        # First perform analysis
        $analysis = Invoke-ComprehensiveResponseAnalysis -ResponseFile $ResponseFile
        if (-not $analysis) {
            throw "Failed to analyze response"
        }
        
        # Read response data
        $responseContent = Get-Content -Path $ResponseFile -Raw
        $responseData = $responseContent | ConvertFrom-Json
        
        $decision = [PSCustomObject]@{
            Timestamp = Get-Date
            ResponseFile = $ResponseFile
            Analysis = $analysis
            Action = $null
            Parameters = @{}
            SafetyLevel = "High"
            Decision = "NO_ACTION"
            Confidence = 0
            TestPath = $null
            TestType = $null
            Reasoning = "No clear action determined"
        }
        
        # Decision logic based on analysis
        if ($analysis.PromptType -eq "Testing" -and $analysis.RequiresAction) {
            $decision.Decision = "EXECUTE_TEST"
            $decision.Action = "ExecuteTest"
            $decision.Confidence = 85
            $decision.Reasoning = "Testing prompt type with clear action requirement"
            
            # Extract test details if available
            if ($responseData.details) {
                $decision.TestPath = $responseData.details
                $decision.Parameters["TestScript"] = $responseData.details
            }
            elseif ($responseData.RESPONSE -match "TEST.*?([.\w\\-]+\.ps1)") {
                $decision.TestPath = $matches[1]
                $decision.Parameters["TestScript"] = $matches[1]
            }
            
            $decision.TestType = "PowerShell"
        }
        elseif ($analysis.ActionType -eq "TEST") {
            $decision.Decision = "EXECUTE_TEST"
            $decision.Action = "ExecuteTest"
            $decision.Confidence = 75
            $decision.Reasoning = "Explicit TEST action identified"
        }
        elseif ($analysis.Priority -eq "High" -and $analysis.RequiresAction) {
            $decision.Decision = "ESCALATE"
            $decision.Action = "Escalate"
            $decision.Confidence = 60
            $decision.Reasoning = "High priority action requires escalation"
        }
        
        Write-Host "      Decision: $($decision.Decision)" -ForegroundColor Gray
        Write-Host "      Confidence: $($decision.Confidence)%" -ForegroundColor Gray
        Write-Host "      Test Path: $($decision.TestPath)" -ForegroundColor Gray
        
        return $decision
    }
    catch {
        Write-Host "ERROR in Invoke-AutonomousDecisionMaking: $_" -ForegroundColor Red
        return $null
    }
}

# Simple safety validation function
function Test-DecisionSafety {
    <#
    .SYNOPSIS
        Validates decision safety
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Decision
    )
    
    try {
        Write-Host "        Validating decision safety..." -ForegroundColor Cyan
        
        # Basic safety checks
        if ($Decision.Action -eq "ExecuteTest" -and $Decision.TestPath) {
            # Check if test path is safe
            $testPath = $Decision.TestPath
            if ($testPath -match "\.\./" -or $testPath -match "^[C-Z]:") {
                Write-Host "        Safety: Potentially unsafe test path: $testPath" -ForegroundColor Yellow
                return $false
            }
        }
        
        Write-Host "        Safety: Decision passed safety validation" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR in Test-DecisionSafety: $_" -ForegroundColor Red
        return $false
    }
}

Write-Verbose "DecisionMaking-Fixed module functions loaded successfully"