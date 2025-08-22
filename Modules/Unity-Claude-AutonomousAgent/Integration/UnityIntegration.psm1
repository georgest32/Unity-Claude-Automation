# UnityIntegration.psm1  
# Unity-specific integration and helper functions
# Extracted from main module during refactoring
# Date: 2025-08-18
# IMPORTANT: ASCII only, no backticks, proper variable delimiting

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Unity Integration Functions

function Get-PatternConfidence {
    <#
    .SYNOPSIS
    Gets confidence score for pattern matching results
    
    .DESCRIPTION
    Calculates confidence based on pattern match quality and context
    
    .PARAMETER Pattern
    The pattern that was matched
    
    .PARAMETER MatchText
    The text that matched the pattern
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter(Mandatory = $true)]
        [string]$MatchText
    )
    
    Write-AgentLog -Message "Calculating pattern confidence for: $Pattern" -Level "DEBUG" -Component "PatternAnalyzer"
    
    try {
        # Calculate confidence based on pattern specificity and match quality
        $confidence = 0.5  # Base confidence
        
        # Higher confidence for specific patterns
        if ($Pattern -match "CS\\d{4}") {
            $confidence = 0.95  # Unity error codes are very specific
        }
        elseif ($Pattern -match "RECOMMENDED") {
            $confidence = 0.9   # Explicit recommendations are high confidence
        }
        elseif ($Pattern -match "\\?") {
            $confidence = 0.8   # Questions are moderately specific
        }
        
        # Adjust for match length (longer matches often more reliable)
        if ($MatchText.Length -gt 50) {
            $confidence += 0.1
        }
        
        # Cap confidence at 1.0
        $confidence = [Math]::Min(1.0, $confidence)
        
        Write-AgentLog -Message "Pattern confidence calculated: $confidence" -Level "DEBUG" -Component "PatternAnalyzer"
        
        return $confidence
    }
    catch {
        Write-AgentLog -Message "Pattern confidence calculation failed: $_" -Level "ERROR" -Component "PatternAnalyzer"
        return 0.5  # Default confidence
    }
}

function Convert-TypeToStandard {
    <#
    .SYNOPSIS
    Converts various command types to standard format
    
    .DESCRIPTION
    Normalizes command types for consistent processing
    
    .PARAMETER Type
    The command type to convert
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type
    )
    
    Write-AgentLog -Message "Converting type to standard: $Type" -Level "DEBUG" -Component "TypeConverter"
    
    try {
        $standardType = $Type.ToUpper().Trim()
        
        # Map variations to standard types
        $typeMapping = @{
            "TESTING" = "TEST"
            "TESTS" = "TEST"
            "COMPILATION" = "BUILD"
            "COMPILE" = "BUILD"
            "ANALYSIS" = "ANALYZE"
            "REVIEW" = "ANALYZE"
            "DEBUG" = "ANALYZE"
            "TROUBLESHOOT" = "ANALYZE"
        }
        
        if ($typeMapping.ContainsKey($standardType)) {
            $standardType = $typeMapping[$standardType]
            Write-AgentLog -Message "Type mapped: $Type -> $standardType" -Level "DEBUG" -Component "TypeConverter"
        }
        
        return $standardType
    }
    catch {
        Write-AgentLog -Message "Type conversion failed: $_" -Level "ERROR" -Component "TypeConverter"
        return $Type  # Return original if conversion fails
    }
}

function Convert-ActionToType {
    <#
    .SYNOPSIS
    Converts action descriptions to command types
    
    .DESCRIPTION
    Analyzes action text to determine appropriate command type
    
    .PARAMETER ActionText
    The action description text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActionText
    )
    
    Write-AgentLog -Message "Converting action to type: $ActionText" -Level "DEBUG" -Component "ActionConverter"
    
    try {
        $actionLower = $ActionText.ToLower()
        
        # Analyze action text for command type indicators
        if ($actionLower -match "test|check|validate|verify") {
            return "TEST"
        }
        elseif ($actionLower -match "build|compile|create|generate") {
            return "BUILD"
        }
        elseif ($actionLower -match "analyze|review|examine|investigate") {
            return "ANALYZE"
        }
        elseif ($actionLower -match "debug|troubleshoot|fix|resolve") {
            return "DEBUG"
        }
        else {
            return "GENERAL"
        }
    }
    catch {
        Write-AgentLog -Message "Action conversion failed: $_" -Level "ERROR" -Component "ActionConverter"
        return "GENERAL"
    }
}

function Normalize-RecommendationType {
    <#
    .SYNOPSIS
    Normalizes recommendation types for consistent processing
    
    .DESCRIPTION
    Ensures recommendation types follow standard conventions
    
    .PARAMETER Recommendation
    The recommendation object to normalize
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation
    )
    
    Write-AgentLog -Message "Normalizing recommendation type" -Level "DEBUG" -Component "RecommendationNormalizer"
    
    try {
        # Convert and standardize the type
        $originalType = $Recommendation.Type
        $standardType = Convert-TypeToStandard -Type $originalType
        
        # Update the recommendation
        $Recommendation.Type = $standardType
        $Recommendation.OriginalType = $originalType
        $Recommendation.Normalized = $true
        $Recommendation.NormalizedAt = Get-Date
        
        Write-AgentLog -Message "Recommendation normalized: $originalType -> $standardType" -Level "DEBUG" -Component "RecommendationNormalizer"
        
        return $Recommendation
    }
    catch {
        Write-AgentLog -Message "Recommendation normalization failed: $_" -Level "ERROR" -Component "RecommendationNormalizer"
        return $Recommendation  # Return original if normalization fails
    }
}

function Remove-DuplicateRecommendations {
    <#
    .SYNOPSIS
    Removes duplicate recommendations from a collection
    
    .DESCRIPTION
    Identifies and removes duplicate recommendations based on type and content similarity
    
    .PARAMETER Recommendations
    Array of recommendations to deduplicate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations
    )
    
    Write-AgentLog -Message "Removing duplicate recommendations from $($Recommendations.Count) items" -Level "DEBUG" -Component "DuplicateRemover"
    
    try {
        $uniqueRecommendations = @()
        $seenRecommendations = @{}
        
        foreach ($rec in $Recommendations) {
            # Create a key for duplicate detection
            $key = "$($rec.Type)::$($rec.Command)"
            
            if (-not $seenRecommendations.ContainsKey($key)) {
                $seenRecommendations[$key] = $true
                $uniqueRecommendations += $rec
                Write-AgentLog -Message "Keeping unique recommendation: $($rec.Type)" -Level "DEBUG" -Component "DuplicateRemover"
            } else {
                Write-AgentLog -Message "Removing duplicate recommendation: $($rec.Type)" -Level "DEBUG" -Component "DuplicateRemover"
            }
        }
        
        $removedCount = $Recommendations.Count - $uniqueRecommendations.Count
        Write-AgentLog -Message "Removed $removedCount duplicates, $($uniqueRecommendations.Count) unique recommendations remain" -Level "INFO" -Component "DuplicateRemover"
        
        return $uniqueRecommendations
    }
    catch {
        Write-AgentLog -Message "Duplicate removal failed: $_" -Level "ERROR" -Component "DuplicateRemover"
        return $Recommendations  # Return original array if deduplication fails
    }
}

function Get-StringSimilarity {
    <#
    .SYNOPSIS
    Calculates similarity between two strings
    
    .DESCRIPTION
    Uses Levenshtein distance to calculate string similarity for recommendation comparison
    
    .PARAMETER String1
    First string to compare
    
    .PARAMETER String2
    Second string to compare
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    Write-AgentLog -Message "Calculating string similarity" -Level "DEBUG" -Component "StringComparator"
    
    try {
        if ($String1 -eq $String2) {
            return 1.0  # Perfect match
        }
        
        if ([string]::IsNullOrEmpty($String1) -or [string]::IsNullOrEmpty($String2)) {
            return 0.0  # No similarity with empty strings
        }
        
        # Simple similarity calculation (can be enhanced with Levenshtein distance)
        $maxLength = [Math]::Max($String1.Length, $String2.Length)
        $minLength = [Math]::Min($String1.Length, $String2.Length)
        
        # Basic character overlap calculation
        $commonChars = 0
        $shorter = if ($String1.Length -le $String2.Length) { $String1 } else { $String2 }
        $longer = if ($String1.Length -gt $String2.Length) { $String1 } else { $String2 }
        
        for ($i = 0; $i -lt $shorter.Length; $i++) {
            if ($i -lt $longer.Length -and $shorter[$i] -eq $longer[$i]) {
                $commonChars++
            }
        }
        
        $similarity = [Math]::Round($commonChars / $maxLength, 2)
        
        Write-AgentLog -Message "String similarity calculated: $similarity" -Level "DEBUG" -Component "StringComparator"
        
        return $similarity
    }
    catch {
        Write-AgentLog -Message "String similarity calculation failed: $_" -Level "ERROR" -Component "StringComparator"
        return 0.0
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Submit-PromptToClaude',
    'New-FollowUpPrompt',
    'Submit-ToClaude',
    'Get-ClaudeResponseStatus',
    'Get-PatternConfidence',
    'Convert-TypeToStandard',
    'Convert-ActionToType',
    'Normalize-RecommendationType',
    'Remove-DuplicateRecommendations',
    'Get-StringSimilarity'
)

Write-AgentLog "UnityIntegration and ClaudeIntegration functions loaded successfully" -Level "INFO" -Component "Integration"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpWz2S6A7eU/hjHxu7UX2piQX
# vr6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU7L+RhMi9ssc69WsR0jdvCKMfo98wDQYJKoZIhvcNAQEBBQAEggEAPsHU
# 2UouHHW5B5M0hPkstC/yWzFvfj5l+KkrdnxrUxxKfmVljJtkvZMUDgL8ZU+X+Qkj
# Nx8oa9ZLj9x1bLhhMac7wvA3Zs2cMkbfcGwaKLDm8PPavlNxYNDMKyn5cSkG8zTU
# 0YPP4iyyfyb8bD2RM35U8tsuWhkfxSeFVZzYzMsL7GrT/HvsX7D45DNHQG1l1Pec
# VP8K2XniY/OfTuATQaI5zjQpFrhDrfCu+cr5hfsI0OAUfxugvbRxJXUbLgb2NeSy
# /7M7+VjO5G6LI+qW5Y7H2SuqrtEqP+sVqyGYZ43eRyrt00cxLdQQ0tRQdQ/Hg3Vn
# 5KwWI37LDYmnVMUT+w==
# SIG # End signature block
