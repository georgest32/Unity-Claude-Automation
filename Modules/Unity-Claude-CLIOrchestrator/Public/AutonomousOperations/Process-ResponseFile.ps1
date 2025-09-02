function Process-ResponseFile {
    <#
    .SYNOPSIS
        Processes Claude response files and extracts recommendations
        
    .DESCRIPTION
        Analyzes response JSON files from Claude to extract recommendations,
        confidence levels, and next actions for autonomous processing
        
    .PARAMETER ResponseFilePath
        Path to the Claude response JSON file
        
    .PARAMETER ExtractRecommendations
        Whether to extract and parse recommendation text
        
    .PARAMETER ValidateStructure
        Whether to validate the JSON structure
        
    .OUTPUTS
        PSCustomObject with processed response information
        
    .EXAMPLE
        $response = Process-ResponseFile -ResponseFilePath ".\ClaudeResponses\response.json" -ExtractRecommendations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseFilePath,
        
        [switch]$ExtractRecommendations,
        [switch]$ValidateStructure
    )
    
    try {
        Write-Host "Processing response file: $ResponseFilePath" -ForegroundColor Cyan
        Write-Host "[DEBUG] TESTING FLOW RESPONSE PROCESSING - Starting response file analysis" -ForegroundColor Magenta
        
        # Validate file exists
        if (-not (Test-Path $ResponseFilePath)) {
            throw "Response file not found: $ResponseFilePath"
        }
        
        # Read and parse JSON
        $jsonContent = Get-Content $ResponseFilePath -Raw -Encoding UTF8
        Write-Host "  File size: $($jsonContent.Length) characters" -ForegroundColor Gray
        Write-Host "[DEBUG] Raw JSON content (first 500 chars): $($jsonContent.Substring(0, [Math]::Min(500, $jsonContent.Length)))" -ForegroundColor DarkGray
        
        try {
            $responseData = $jsonContent | ConvertFrom-Json
        } catch {
            Write-Host "  Warning: Invalid JSON structure, attempting repair..." -ForegroundColor Yellow
            
            # Attempt basic JSON repair
            $repairedJson = $jsonContent
            
            # Fix common issues
            $repairedJson = $repairedJson -replace '(?<!\\)\\(?!["\\/bfnrt]|u[0-9a-fA-F]{4})', '\\\\'
            $repairedJson = $repairedJson -replace ',\s*}', '}'
            $repairedJson = $repairedJson -replace ',\s*]', ']'
            
            try {
                $responseData = $repairedJson | ConvertFrom-Json
                Write-Host "  JSON repair successful" -ForegroundColor Green
            } catch {
                throw "Unable to parse response file as JSON: $_"
            }
        }
        
        $processedResponse = [PSCustomObject]@{
            FilePath = $ResponseFilePath
            ProcessedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            IsValid = $true
            HasRecommendations = $false
            Recommendations = @()
            ConfidenceLevel = "Unknown"
            ResponseType = "Unknown"
            PromptType = "Unknown"
            TestDetails = $null
            NextActions = @()
            Metadata = @{}
        }
        
        # Extract basic metadata
        if ($responseData.timestamp) {
            $processedResponse.Metadata.Timestamp = $responseData.timestamp
        }
        
        # Enhanced prompt type extraction - check multiple fields
        if ($responseData.prompt_type) {
            $processedResponse.PromptType = $responseData.prompt_type
            $processedResponse.ResponseType = $responseData.prompt_type
            Write-Host "[DEBUG] Extracted prompt_type: $($responseData.prompt_type)" -ForegroundColor Green
        } elseif ($responseData."prompt-type") {
            $processedResponse.PromptType = $responseData."prompt-type"
            $processedResponse.ResponseType = $responseData."prompt-type"
            Write-Host "[DEBUG] Extracted prompt-type: $($responseData.'prompt-type')" -ForegroundColor Green
        }
        
        # Extract test details if present
        if ($responseData.details) {
            $processedResponse.TestDetails = $responseData.details
            Write-Host "[DEBUG] Extracted test details: $($responseData.details)" -ForegroundColor Green
        } elseif ($responseData.test_path) {
            $processedResponse.TestDetails = $responseData.test_path
            Write-Host "[DEBUG] Extracted test_path: $($responseData.test_path)" -ForegroundColor Green
        } elseif ($responseData."test-path") {
            $processedResponse.TestDetails = $responseData."test-path"
            Write-Host "[DEBUG] Extracted test-path: $($responseData.'test-path')" -ForegroundColor Green
        }
        
        # Validate structure if requested
        if ($ValidateStructure) {
            $requiredFields = @("timestamp", "RESPONSE")
            $missingFields = @()
            
            foreach ($field in $requiredFields) {
                if (-not ($responseData.PSObject.Properties.Name -contains $field)) {
                    $missingFields += $field
                }
            }
            
            if ($missingFields.Count -gt 0) {
                Write-Host "  Warning: Missing required fields: $($missingFields -join ', ')" -ForegroundColor Yellow
                $processedResponse.IsValid = $false
            }
        }
        
        # Extract recommendations if requested
        if ($ExtractRecommendations) {
            $recommendationText = ""
            
            # Look for RESPONSE field
            if ($responseData.RESPONSE) {
                $recommendationText = $responseData.RESPONSE
            } elseif ($responseData.recommendation) {
                $recommendationText = $responseData.recommendation
            } elseif ($responseData.response) {
                $recommendationText = $responseData.response
            }
            
            Write-Host "[DEBUG] TESTING FLOW - Recommendation text found: $($recommendationText.Length) characters" -ForegroundColor Magenta
            
            if ($recommendationText) {
                $processedResponse.HasRecommendations = $true
                
                # Parse recommendations using enhanced regex patterns
                $recommendationPatterns = @(
                    'RECOMMENDATION:\s*TEST\s*[-:]?\s*([^\n\r]+)',  # RECOMMENDATION: TEST - path
                    'RECOMMENDATION:\s*([^\n\r]+)',                  # RECOMMENDATION: anything
                    '\[RECOMMENDATION:\s*([^\]]+)\]',               # [RECOMMENDATION: ...]
                    'RECOMMEND:\s*([^\n\r]+)'                       # RECOMMEND: ...
                )
                
                foreach ($pattern in $recommendationPatterns) {
                    $matches = [regex]::Matches($recommendationText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    
                    foreach ($match in $matches) {
                        $recommendation = $match.Groups[1].Value.Trim()
                        if ($recommendation -and $recommendation.Length -gt 0) {
                            $processedResponse.Recommendations += [PSCustomObject]@{
                                Text = $recommendation
                                Type = if ($recommendation -match '^(TEST|COMPILE|FIX|RESTART|CONTINUE|COMPLETE|ERROR)') { $matches[1] } else { "UNKNOWN" }
                            }
                            Write-Host "[DEBUG] Found recommendation: $recommendation" -ForegroundColor Cyan
                        }
                    }
                }
                
                # Extract confidence indicators
                if ($recommendationText -match '(?i)confidence[:\s]*([0-9.]+)%?') {
                    $processedResponse.ConfidenceLevel = $matches[1] + "%"
                } elseif ($recommendationText -match '(?i)(high|medium|low)\s+confidence') {
                    $processedResponse.ConfidenceLevel = $matches[1]
                }
            }
        }
        
        # Generate next actions based on recommendations and prompt type
        Write-Host "[DEBUG] TESTING FLOW - Processing next actions for prompt type: $($processedResponse.PromptType)" -ForegroundColor Magenta
        Write-Host "[TRACE] Full processedResponse object:" -ForegroundColor DarkMagenta
        Write-Host "[TRACE] $($processedResponse | ConvertTo-Json -Depth 3)" -ForegroundColor DarkMagenta
        
        # Special handling for Testing prompt type
        if ($processedResponse.PromptType -eq "Testing" -and $processedResponse.TestDetails) {
            Write-Host "[DEBUG] TESTING FLOW - Creating TEST action for: $($processedResponse.TestDetails)" -ForegroundColor Green
            Write-Host "[TRACE] TESTING FLOW - TestDetails validation: Path=$($processedResponse.TestDetails), Exists=$(Test-Path $processedResponse.TestDetails -ErrorAction SilentlyContinue)" -ForegroundColor DarkMagenta
            $processedResponse.NextActions += [PSCustomObject]@{
                Type = "TEST"
                Target = $processedResponse.TestDetails
                Priority = "High"
                Source = "PromptType"
            }
        }
        
        # Process explicit recommendations
        foreach ($rec in $processedResponse.Recommendations) {
            $recText = if ($rec.Text) { $rec.Text } else { $rec }
            
            if ($recText -match '^(TEST|COMPILE|FIX|RESTART|CONTINUE|COMPLETE|ERROR)[\s:-]*(.*)') {
                $actionType = $matches[1]
                $actionTarget = $matches[2].Trim()
                
                # Special handling for TEST recommendations
                if ($actionType -eq "TEST" -and $actionTarget) {
                    Write-Host "[DEBUG] TESTING FLOW - Found TEST recommendation with target: $actionTarget" -ForegroundColor Green
                }
                
                $processedResponse.NextActions += [PSCustomObject]@{
                    Type = $actionType
                    Target = $actionTarget
                    Priority = switch ($actionType) {
                        "ERROR" { "High" }
                        "FIX" { "High" }
                        "TEST" { "High" }  # Changed TEST to High priority
                        "COMPILE" { "Medium" }
                        "RESTART" { "Low" }
                        "CONTINUE" { "Low" }
                        "COMPLETE" { "Low" }
                        default { "Medium" }
                    }
                    Source = "Recommendation"
                }
            }
        }
        
        Write-Host "  Recommendations found: $($processedResponse.Recommendations.Count)" -ForegroundColor Gray
        Write-Host "  Next actions identified: $($processedResponse.NextActions.Count)" -ForegroundColor Gray
        Write-Host "  Confidence level: $($processedResponse.ConfidenceLevel)" -ForegroundColor Gray
        
        Write-Host "Response file processed successfully" -ForegroundColor Green
        
        return $processedResponse
        
    } catch {
        Write-Host "Error processing response file: $_" -ForegroundColor Red
        throw
    }
}