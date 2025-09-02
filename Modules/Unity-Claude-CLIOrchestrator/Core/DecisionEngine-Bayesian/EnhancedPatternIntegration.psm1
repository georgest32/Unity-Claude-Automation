# EnhancedPatternIntegration.psm1
# Phase 7 Day 3-4 Hours 5-8: Enhanced Pattern Analysis Integration
# Main integration function combining all Bayesian analysis components
# Date: 2025-08-25

#region Enhanced Pattern Analysis Integration

# Main enhanced pattern analysis function
function Invoke-EnhancedPatternAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [switch]$UseBayesian,
        
        [Parameter()]
        [switch]$IncludeNGrams,
        
        [Parameter()]
        [switch]$BuildEntityGraph,
        
        [Parameter()]
        [switch]$AddTemporalContext
    )
    
    Write-DecisionLog "Starting enhanced pattern analysis" "INFO"
    $startTime = Get-Date
    
    $enhancedResult = $AnalysisResult.Clone()
    
    try {
        # Apply Bayesian confidence adjustment
        if ($UseBayesian -and $AnalysisResult.Recommendations) {
            foreach ($rec in $AnalysisResult.Recommendations) {
                $bayesianResult = Invoke-BayesianConfidenceAdjustment `
                    -DecisionType $rec.Type `
                    -ObservedConfidence $rec.Confidence `
                    -ReturnDetails
                
                $rec | Add-Member -NotePropertyName 'BayesianConfidence' -NotePropertyValue $bayesianResult.AdjustedConfidence -Force
                $rec | Add-Member -NotePropertyName 'ConfidenceBand' -NotePropertyValue $bayesianResult.ConfidenceBand -Force
                $rec | Add-Member -NotePropertyName 'Uncertainty' -NotePropertyValue $bayesianResult.Uncertainty -Force
            }
        }
        
        # Build n-gram model for response text
        if ($IncludeNGrams -and $AnalysisResult.ResponseText) {
            $ngramModel = Build-NGramModel -Text $AnalysisResult.ResponseText -N 3 -IncludeStatistics
            $enhancedResult | Add-Member -NotePropertyName 'NGramAnalysis' -NotePropertyValue $ngramModel -Force
        }
        
        # Build entity relationship graph
        if ($BuildEntityGraph -and $AnalysisResult.Entities) {
            $allEntities = @()
            
            # Collect all entities with positions
            $position = 0
            if ($AnalysisResult.Entities.FilePaths) {
                foreach ($path in $AnalysisResult.Entities.FilePaths) {
                    $allEntities += @{
                        Type = 'FilePath'
                        Value = if ($path -is [string]) { $path } else { $path.Value }
                        Position = $position
                        Confidence = if ($path.Confidence) { $path.Confidence } else { 0.9 }
                    }
                    $position += 100
                }
            }
            
            if ($AnalysisResult.Entities.PowerShellCommands) {
                foreach ($cmd in $AnalysisResult.Entities.PowerShellCommands) {
                    $allEntities += @{
                        Type = 'PowerShellCommand'
                        Value = $cmd.Value
                        Position = $position
                        Confidence = $cmd.Confidence
                    }
                    $position += 100
                }
            }
            
            if ($allEntities.Count -gt 0) {
                $entityGraph = Build-EntityRelationshipGraph -Entities $allEntities -IncludeMetrics
                $enhancedResult | Add-Member -NotePropertyName 'EntityGraph' -NotePropertyValue $entityGraph -Force
            }
        }
        
        # Add temporal context
        if ($AddTemporalContext) {
            $primaryRecommendation = $AnalysisResult.Recommendations | Select-Object -First 1
            if ($primaryRecommendation) {
                $temporalDecision = @{
                    DecisionType = $primaryRecommendation.Type
                    Confidence = $primaryRecommendation.Confidence
                    Success = $null  # Will be updated after execution
                }
                
                $temporalDecision = Add-TemporalContext -Decision $temporalDecision
                $enhancedResult | Add-Member -NotePropertyName 'TemporalContext' -NotePropertyValue $temporalDecision.TemporalContext -Force
                
                # Get relevance for this decision type
                $relevance = Get-TemporalContextRelevance -DecisionType $primaryRecommendation.Type
                $enhancedResult | Add-Member -NotePropertyName 'TemporalRelevance' -NotePropertyValue $relevance -Force
            }
        }
        
        $processingTime = ((Get-Date) - $startTime).TotalMilliseconds
        $enhancedResult | Add-Member -NotePropertyName 'EnhancementTimeMs' -NotePropertyValue $processingTime -Force
        
        Write-DecisionLog "Enhanced pattern analysis completed in ${processingTime}ms" "SUCCESS"
        
        return $enhancedResult
        
    } catch {
        Write-DecisionLog "Enhanced pattern analysis failed: $($_.Exception.Message)" "ERROR"
        return $AnalysisResult  # Return original on failure
    }
}

#endregion

# Export enhanced pattern integration function
Export-ModuleMember -Function Invoke-EnhancedPatternAnalysis
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBfVmJv5UOKwB3k
# TrxbWWCACt119zL+lV0EfXXfucRjPqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG8TvhnZ1Y6rtIEemnxA9NUJ
# jKlbcY57BJHa4HgxTpNVMA0GCSqGSIb3DQEBAQUABIIBAG8XX/vsmTp3ROmUSulx
# bEPcoKMQlI7y4vkFUmw3/H00/h95vUfOoqPPOhtdUA2QB57Ml3HMHxkDDLIc88A5
# 88jX8FygHPLon9QZOcdqP53IeSQ/wzXwQjt8RCQ2G955+X6ixyuuRl4gDV/1di7x
# /J9aCOCFV0PnkqUq3MTkOcJjFiU+1iGbbPnwuuX29sT+mhKwe4MYUNVvj04WJtaQ
# DX0DbBHvAZQj2gTZMD3jp0/ZI4JMtIiui98UYzkb4XMl/oGdn7GbI4leLSX+so/u
# 22dJZWFWCnUZHdIEurnlp9D/2OTHPRbhk3qG4wgY2aulFBQqpWMLTmnThaLuPCqP
# ZlI=
# SIG # End signature block
