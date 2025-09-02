function Extract-ResponseEntities {
    <#
    .SYNOPSIS
        Extracts entities from Claude response text for analysis
        
    .DESCRIPTION
        Analyzes response text to identify and extract key entities such as:
        - File paths and names
        - Function names
        - Error messages  
        - Recommendations
        - Project components
        - Technical terms
        
    .PARAMETER ResponseText
        The Claude response text to analyze
        
    .PARAMETER EntityTypes
        Optional array of specific entity types to extract
        
    .OUTPUTS
        PSCustomObject containing extracted entities organized by type
        
    .EXAMPLE
        $entities = Extract-ResponseEntities -ResponseText $claudeResponse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText,
        
        [string[]]$EntityTypes = @("FilePaths", "Functions", "Errors", "Recommendations", "Components")
    )
    
    try {
        Write-Verbose "Extracting entities from response text ($($ResponseText.Length) characters)"
        
        $entities = [PSCustomObject]@{
            FilePaths = @()
            Functions = @()
            Errors = @()
            Recommendations = @()
            Components = @()
            TechnicalTerms = @()
            ExtractedAt = Get-Date
            TotalEntities = 0
        }
        
        if ([string]::IsNullOrWhiteSpace($ResponseText)) {
            Write-Warning "Response text is empty or null"
            return $entities
        }
        
        # Extract file paths (common patterns)
        if ($EntityTypes -contains "FilePaths") {
            $filePathPatterns = @(
                '[A-Za-z]:\\[^`n]*\.[a-zA-Z0-9]+',  # Windows paths
                '\./[^`s`n]*\.[a-zA-Z0-9]+',         # Relative paths
                '/[^`s`n]*\.[a-zA-Z0-9]+',           # Unix paths
                '[\w\-\.]+\.ps1',                    # PowerShell files
                '[\w\-\.]+\.psm1',                   # PowerShell modules
                '[\w\-\.]+\.psd1',                   # PowerShell manifests
                '[\w\-\.]+\.json',                   # JSON files
                '[\w\-\.]+\.md'                      # Markdown files
            )
            
            foreach ($pattern in $filePathPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    if ($match.Value -notin $entities.FilePaths) {
                        $entities.FilePaths += $match.Value
                    }
                }
            }
        }
        
        # Extract function names
        if ($EntityTypes -contains "Functions") {
            $functionPatterns = @(
                'function\s+([A-Za-z][\w\-]*)',      # PowerShell functions
                '([A-Za-z][\w\-]*)\s*\(',            # Function calls
                'Get-[A-Za-z][\w\-]*',               # Get- cmdlets
                'Set-[A-Za-z][\w\-]*',               # Set- cmdlets
                'New-[A-Za-z][\w\-]*',               # New- cmdlets
                'Invoke-[A-Za-z][\w\-]*',            # Invoke- cmdlets
                'Test-[A-Za-z][\w\-]*'               # Test- cmdlets
            )
            
            foreach ($pattern in $functionPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $functionName = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $match.Value }
                    if ($functionName -notin $entities.Functions -and $functionName -notmatch '^\d') {
                        $entities.Functions += $functionName
                    }
                }
            }
        }
        
        # Extract error messages
        if ($EntityTypes -contains "Errors") {
            $errorPatterns = @(
                'ERROR[:\s]+([^`n`r]+)',             # ERROR: messages
                'FAIL[:\s]+([^`n`r]+)',              # FAIL: messages
                'Exception[:\s]+([^`n`r]+)',         # Exception messages
                'Error[:\s]+([^`n`r]+)',             # Error: messages
                '\[ERROR\]\s*([^`n`r]+)',            # [ERROR] messages
                'failed[:\s]+([^`n`r]+)'             # failed: messages
            )
            
            foreach ($pattern in $errorPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $errorMsg = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value.Trim() } else { $match.Value.Trim() }
                    if ($errorMsg -notin $entities.Errors) {
                        $entities.Errors += $errorMsg
                    }
                }
            }
        }
        
        # Extract recommendations
        if ($EntityTypes -contains "Recommendations") {
            $recommendationPatterns = @(
                'RECOMMENDATION[:\s]+([^`n`r]+)',     # RECOMMENDATION: 
                'RECOMMENDED[:\s]+([^`n`r]+)',       # RECOMMENDED:
                'should\s+([^`n`r]+)',               # should do...
                'need to\s+([^`n`r]+)',              # need to...
                'suggest\s+([^`n`r]+)'               # suggest...
            )
            
            foreach ($pattern in $recommendationPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $recommendation = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value.Trim() } else { $match.Value.Trim() }
                    if ($recommendation -notin $entities.Recommendations) {
                        $entities.Recommendations += $recommendation
                    }
                }
            }
        }
        
        # Extract components (modules, classes, etc.)
        if ($EntityTypes -contains "Components") {
            $componentPatterns = @(
                'Unity-Claude-[\w\-]+',              # Unity-Claude modules
                'CLIOrchestrator[\w\-]*',            # CLI Orchestrator components
                'WindowManager[\w\-]*',              # Window Manager
                'DecisionEngine[\w\-]*',             # Decision Engine
                'ResponseAnalysis[\w\-]*',           # Response Analysis
                'PatternRecognition[\w\-]*'          # Pattern Recognition
            )
            
            foreach ($pattern in $componentPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    if ($match.Value -notin $entities.Components) {
                        $entities.Components += $match.Value
                    }
                }
            }
        }
        
        # Calculate total entities
        $entities.TotalEntities = $entities.FilePaths.Count + $entities.Functions.Count + 
                                 $entities.Errors.Count + $entities.Recommendations.Count + 
                                 $entities.Components.Count
        
        Write-Verbose "Entity extraction complete:"
        Write-Verbose "  File Paths: $($entities.FilePaths.Count)"
        Write-Verbose "  Functions: $($entities.Functions.Count)"
        Write-Verbose "  Errors: $($entities.Errors.Count)"
        Write-Verbose "  Recommendations: $($entities.Recommendations.Count)"
        Write-Verbose "  Components: $($entities.Components.Count)"
        Write-Verbose "  Total Entities: $($entities.TotalEntities)"
        
        return $entities
        
    } catch {
        Write-Error "Error extracting response entities: $_"
        return [PSCustomObject]@{
            FilePaths = @()
            Functions = @()
            Errors = @()
            Recommendations = @()
            Components = @()
            TechnicalTerms = @()
            ExtractedAt = Get-Date
            TotalEntities = 0
            Error = $_.Exception.Message
        }
    }
}

# Export function
Export-ModuleMember -Function 'Extract-ResponseEntities'