# DecisionMaking.psm1
# Autonomous decision making and analysis functions

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
            ExecutionMode = "Safe"
            RequiresConfirmation = $false
        }
        
        # Decision logic based on prompt type and action
        switch ($analysis.PromptType) {
            "Testing" {
                if ($responseData.test_path -and (Test-Path $responseData.test_path)) {
                    $decision.Action = "EXECUTE_TEST"
                    $decision.Parameters.TestPath = $responseData.test_path
                    $decision.Parameters.TestType = $responseData.test_type
                    $decision.ExecutionMode = "Safe"
                    Write-Host "      Decision: Execute test at $($responseData.test_path)" -ForegroundColor Yellow
                }
            }
            
            "Debugging" {
                if ($analysis.ActionType -eq "FIX") {
                    $decision.Action = "APPLY_FIX"
                    $decision.Parameters.FixType = "Automated"
                    $decision.RequiresConfirmation = $true
                    Write-Host "      Decision: Apply automated fix (requires confirmation)" -ForegroundColor Yellow
                }
            }
            
            "Fix" {
                if ($responseData.fix_applied) {
                    $decision.Action = "VALIDATE_FIX"
                    $decision.Parameters.ValidationRequired = $true
                    Write-Host "      Decision: Validate applied fix" -ForegroundColor Yellow
                }
            }
            
            "Compile" {
                if ($responseData.compilation_required) {
                    $decision.Action = "TRIGGER_COMPILATION"
                    $decision.Parameters.CompilationType = "Incremental"
                    Write-Host "      Decision: Trigger compilation" -ForegroundColor Yellow
                }
            }
            
            "Complete" {
                $decision.Action = "GENERATE_SUMMARY"
                $decision.Parameters.IncludeMetrics = $true
                Write-Host "      Decision: Generate completion summary" -ForegroundColor Yellow
            }
            
            default {
                if ($analysis.RequiresAction -and $analysis.ActionType) {
                    $decision.Action = "EXECUTE_RECOMMENDED"
                    $decision.Parameters.ActionType = $analysis.ActionType
                    $decision.RequiresConfirmation = ($analysis.Priority -eq "High")
                    Write-Host "      Decision: Execute recommended action - $($analysis.ActionType)" -ForegroundColor Yellow
                }
                else {
                    $decision.Action = "MONITOR"
                    Write-Host "      Decision: Continue monitoring" -ForegroundColor Gray
                }
            }
        }
        
        # Safety validation
        if ($decision.Action -and $decision.Action -ne "MONITOR") {
            $safetyCheck = Test-DecisionSafety -Decision $decision
            if (-not $safetyCheck) {
                Write-Host "      Safety check failed - action blocked" -ForegroundColor Red
                $decision.Action = "BLOCKED"
            }
        }
        
        return $decision
    }
    catch {
        Write-Host "ERROR in Invoke-AutonomousDecisionMaking: $_" -ForegroundColor Red
        return $null
    }
}

function Test-DecisionSafety {
    <#
    .SYNOPSIS
        Validates decision safety before execution
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Decision
    )
    
    try {
        # Define unsafe actions
        $unsafeActions = @(
            "DELETE_FILES",
            "MODIFY_SYSTEM",
            "EXECUTE_ARBITRARY"
        )
        
        # Check if action is unsafe
        if ($Decision.Action -in $unsafeActions) {
            Write-Host "        Safety: Action '$($Decision.Action)' is marked as unsafe" -ForegroundColor Red
            return $false
        }
        
        # Check parameters for unsafe patterns
        foreach ($param in $Decision.Parameters.Keys) {
            $value = $Decision.Parameters[$param]
            
            # Check for system paths
            if ($value -match 'C:\\Windows|C:\\Program Files|System32') {
                Write-Host "        Safety: System path detected in parameters" -ForegroundColor Red
                return $false
            }
            
            # Check for dangerous commands
            if ($value -match 'Remove-Item|Delete|Format|Clear-') {
                Write-Host "        Safety: Dangerous command detected" -ForegroundColor Red
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

# Functions are available directly when dot-sourced
# No Export-ModuleMember needed for dot-sourcing