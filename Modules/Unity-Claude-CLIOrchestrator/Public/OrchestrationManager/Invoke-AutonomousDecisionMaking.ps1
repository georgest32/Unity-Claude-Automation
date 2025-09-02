function Invoke-AutonomousDecisionMaking {
    <#
    .SYNOPSIS
        Makes autonomous decisions based on response analysis
        
    .DESCRIPTION
        Analyzes responses and makes decisions about appropriate actions to take
        
    .PARAMETER ResponseFile
        Path to the response file to analyze for decision making
        
    .OUTPUTS
        PSCustomObject with decision results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseFile
    )
    
    try {
        Write-Host "DEBUG Invoke-AutonomousDecisionMaking: Reading file: $ResponseFile" -ForegroundColor DarkGray
        $content = Get-Content -Path $ResponseFile -Raw | ConvertFrom-Json
        
        $decisionResult = [PSCustomObject]@{
            Timestamp = Get-Date
            ResponseFile = $ResponseFile
            Decision = "CONTINUE"
            Confidence = 50
            Reasoning = @()
            Actions = @()
            SafetyChecks = $true
            PromptType = "Unknown"
            TestPath = $null
            ResponseText = $null
        }
        
        # Enhanced parsing - check for prompt_type field
        if ($content.prompt_type) {
            $decisionResult.PromptType = $content.prompt_type
            Write-Host "DEBUG Detected prompt_type: $($content.prompt_type)" -ForegroundColor DarkGray
            $decisionResult.Reasoning += "Prompt type identified: $($content.prompt_type)"
        }
        
        # Check both response and RESPONSE fields
        $responseText = if ($content.response) { $content.response } elseif ($content.RESPONSE) { $content.RESPONSE } else { $null }
        
        if ($responseText) {
            $decisionResult.ResponseText = $responseText
            Write-Host "DEBUG Response text found: $($responseText.Substring(0, [Math]::Min(100, $responseText.Length)))..." -ForegroundColor DarkGray
            
            # Enhanced decision logic based on prompt type
            Write-Host "DEBUG *** TESTING FLOW TRACE *** Starting prompt-type decision logic" -ForegroundColor Magenta
            Write-Host "DEBUG TESTING FLOW: Prompt type = '$($decisionResult.PromptType)'" -ForegroundColor Magenta
            Write-Host "[TRACE] TESTING FLOW - Full content object:" -ForegroundColor DarkMagenta
            Write-Host "[TRACE] $($content | ConvertTo-Json -Depth 3)" -ForegroundColor DarkMagenta
            Write-Host "[TRACE] TESTING FLOW - Response text length: $($responseText.Length) characters" -ForegroundColor DarkMagenta
            
            switch ($decisionResult.PromptType) {
                "Testing" {
                    Write-Host "DEBUG *** TESTING FLOW *** Processing Testing prompt-type" -ForegroundColor Magenta
                    Write-Host "DEBUG TESTING FLOW: Setting decision to EXECUTE_TEST" -ForegroundColor Magenta
                    Write-Host "[TRACE] TESTING FLOW - Decision object before modification:" -ForegroundColor DarkMagenta
                    Write-Host "[TRACE] $($decisionResult | ConvertTo-Json -Depth 2)" -ForegroundColor DarkMagenta
                    $decisionResult.Decision = "EXECUTE_TEST"
                    $decisionResult.Confidence = 95
                    $decisionResult.Reasoning += "Testing prompt-type requires test execution"
                    
                    # Enhanced test path extraction with multiple patterns
                    Write-Host "DEBUG TESTING FLOW: Attempting to extract test path from response text" -ForegroundColor Magenta
                    Write-Host "DEBUG TESTING FLOW: Response text snippet: $($responseText.Substring(0, [Math]::Min(200, $responseText.Length)))..." -ForegroundColor DarkGray
                    
                    $testPathPatterns = @(
                        "Testing\s*[-:]\s*(.+\.ps1)"  # Testing: path.ps1
                        "Test\s*Path:\s*(.+\.ps1)"  # Test Path: path.ps1
                        "TEST\s*[-:]\s*(.+\.ps1)"     # TEST - path.ps1
                        "(\w+\.ps1)"          # Any .ps1 file
                        "run.*?(\w+\.ps1)"  # run something.ps1
                    )
                    
                    $testPathFound = $false
                    foreach ($pattern in $testPathPatterns) {
                        if ($responseText -match $pattern) {
                            $decisionResult.TestPath = $matches[1]
                            $testPathFound = $true
                            Write-Host "DEBUG TESTING FLOW: Test path extracted with pattern '$pattern': $($decisionResult.TestPath)" -ForegroundColor Green
                            $decisionResult.Actions += "Execute test: $($decisionResult.TestPath)"
                            break
                        }
                    }
                    
                    if (-not $testPathFound) {
                        Write-Host "DEBUG TESTING FLOW: Warning - No test path found in response text" -ForegroundColor Yellow
                        Write-Host "DEBUG TESTING FLOW: Full response text for analysis:" -ForegroundColor Yellow
                        Write-Host "$responseText" -ForegroundColor DarkYellow
                        
                        # Try to find any .ps1 files mentioned
                        $ps1Matches = [regex]::Matches($responseText, "(\w+\.ps1)", "IgnoreCase")
                        if ($ps1Matches.Count -gt 0) {
                            $decisionResult.TestPath = $ps1Matches[0].Groups[1].Value
                            Write-Host "DEBUG TESTING FLOW: Fallback - Found .ps1 file: $($decisionResult.TestPath)" -ForegroundColor Cyan
                            $decisionResult.Actions += "Execute test (fallback): $($decisionResult.TestPath)"
                        }
                        else {
                            Write-Host "DEBUG TESTING FLOW: ERROR - No .ps1 files found at all in response" -ForegroundColor Red
                            $decisionResult.Reasoning += "Warning: No test path could be extracted from response"
                        }
                    }
                }
                "System Test Request" {
                    Write-Host "DEBUG *** TESTING FLOW *** Processing System Test Request prompt-type" -ForegroundColor Magenta
                    $decisionResult.Decision = "EXECUTE_TEST"
                    $decisionResult.Confidence = 95
                    $decisionResult.Reasoning += "System Test Request requires test execution"
                    
                    # Extract test path from recommendation using same enhanced logic as Testing
                    Write-Host "DEBUG TESTING FLOW: Extracting test path for System Test Request" -ForegroundColor Magenta
                    $testPathPatterns = @(
                        "Testing\s*[-:]\s*(.+\.ps1)",
                        "Test\s*Path:\s*(.+\.ps1)",
                        "TEST\s*[-:]\s*(.+\.ps1)",
                        "(\w+\.ps1)",
                        "run.*?(\w+\.ps1)"
                    )
                    
                    $testPathFound = $false
                    foreach ($pattern in $testPathPatterns) {
                        if ($responseText -match $pattern) {
                            $decisionResult.TestPath = $matches[1]
                            $testPathFound = $true
                            Write-Host "DEBUG TESTING FLOW: System test path extracted: $($decisionResult.TestPath)" -ForegroundColor Green
                            $decisionResult.Actions += "Execute test: $($decisionResult.TestPath)"
                            break
                        }
                    }
                    
                    if (-not $testPathFound) {
                        Write-Host "DEBUG TESTING FLOW: Warning - No test path found for System Test Request" -ForegroundColor Yellow
                    }
                }
                "Debugging" {
                    $decisionResult.Decision = "DEBUG"
                    $decisionResult.Confidence = 85
                    $decisionResult.Reasoning += "Debugging prompt-type requires investigation"
                }
                "Continue" {
                    $decisionResult.Decision = "CONTINUE"
                    $decisionResult.Confidence = 90
                    $decisionResult.Reasoning += "Continue prompt-type"
                }
                default {
                    # Fallback to pattern-based decision
                    if ($responseText -match "RECOMMENDATION:\s*(TEST|Testing)") {
                        Write-Host "DEBUG Pattern match found TEST recommendation" -ForegroundColor DarkGray
                        $decisionResult.Decision = "EXECUTE_TEST"
                        $decisionResult.Confidence = 80
                        $decisionResult.Reasoning += "Contains test recommendation"
                        
                        # Try to extract test path
                        if ($responseText -match "(\S+\.ps1)") {
                            $decisionResult.TestPath = $matches[1]
                            Write-Host "DEBUG Extracted test path from pattern: $($decisionResult.TestPath)" -ForegroundColor DarkGray
                        }
                    }
                    elseif ($responseText -match "ERROR|FAIL|CRITICAL") {
                        $decisionResult.Decision = "INVESTIGATE"
                        $decisionResult.Confidence = 75
                        $decisionResult.Reasoning += "Contains error indicators"
                    }
                    elseif ($responseText -match "COMPLETE|SUCCESS|IMPLEMENTED") {
                        $decisionResult.Decision = "CONTINUE"
                        $decisionResult.Confidence = 90
                        $decisionResult.Reasoning += "Task appears complete"
                    }
                }
            }
            
            # Safety validation
            $unsafePatterns = @("rm -rf", "Remove-Item -Recurse -Force", "format", "shutdown")
            foreach ($pattern in $unsafePatterns) {
                if ($responseText -match $pattern) {
                    $decisionResult.SafetyChecks = $false
                    $decisionResult.Decision = "BLOCK"
                    $decisionResult.Reasoning += "Contains potentially unsafe operation: $pattern"
                    Write-Host "DEBUG SAFETY BLOCK: Detected unsafe pattern: $pattern" -ForegroundColor Red
                    break
                }
            }
        }
        else {
            Write-Host "DEBUG WARNING: No response text found in JSON" -ForegroundColor Yellow
        }
        
        Write-Host "DEBUG Decision Result: $($decisionResult.Decision) (Confidence: $($decisionResult.Confidence)%)" -ForegroundColor Cyan
        return $decisionResult
    }
    catch {
        Write-Host "DEBUG ERROR in Invoke-AutonomousDecisionMaking: $($_.Exception.Message)" -ForegroundColor Red
        throw "Decision making failed: $($_.Exception.Message)"
    }
}