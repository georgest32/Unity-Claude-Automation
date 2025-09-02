function Invoke-ComprehensiveResponseAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive analysis of Claude responses
        
    .DESCRIPTION
        Analyzes response files for patterns, recommendations, and actionable insights
        
    .PARAMETER ResponseFile
        Path to the response file to analyze
        
    .OUTPUTS
        PSCustomObject with analysis results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseFile
    )
    
    try {
        if (-not (Test-Path $ResponseFile)) {
            throw "Response file not found: $ResponseFile"
        }
        
        $content = Get-Content -Path $ResponseFile -Raw | ConvertFrom-Json
        
        $analysisResults = [PSCustomObject]@{
            Timestamp = Get-Date
            ResponseFile = $ResponseFile
            ResponseType = "Unknown"
            Confidence = 0
            RecommendationTypes = @{}
            ActionableInsights = @()
            Status = "Analyzed"
        }
        
        # Basic response analysis
        if ($content.RESPONSE) {
            $responseText = $content.RESPONSE
            
            # Classify response type
            if ($responseText -match "RECOMMENDATION:|TEST:|ERROR:|SUCCESS:") {
                $analysisResults.ResponseType = "Actionable"
                $analysisResults.Confidence = 85
            }
            elseif ($responseText -match "COMPLETE|IMPLEMENTED|FIXED") {
                $analysisResults.ResponseType = "Status Update"
                $analysisResults.Confidence = 90
            }
            else {
                $analysisResults.ResponseType = "Informational"
                $analysisResults.Confidence = 70
            }
            
            # Extract recommendations
            $recommendations = [regex]::Matches($responseText, "RECOMMENDATION:\s*(.+)")
            foreach ($match in $recommendations) {
                $recType = $match.Groups[1].Value
                if ($analysisResults.RecommendationTypes.ContainsKey($recType)) {
                    $analysisResults.RecommendationTypes[$recType]++
                }
                else {
                    $analysisResults.RecommendationTypes[$recType] = 1
                }
            }
            
            # Generate insights
            if ($analysisResults.RecommendationTypes.Count -gt 0) {
                $topRecommendation = $analysisResults.RecommendationTypes.GetEnumerator() | 
                                   Sort-Object Value -Descending | 
                                   Select-Object -First 1
                
                if ($topRecommendation) {
                    $analysisResults.ActionableInsights += "Most common recommendation: $($topRecommendation.Name) - $($topRecommendation.Value) occurrences"
                }
            }
        }
        
        return $analysisResults
    }
    catch {
        throw "Analysis failed: $($_.Exception.Message)"
    }
}