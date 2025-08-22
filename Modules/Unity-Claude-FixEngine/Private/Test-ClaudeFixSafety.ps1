function Test-ClaudeFixSafety {
    <#
    .SYNOPSIS
    Validates Claude's suggested fix using the safety framework
    
    .DESCRIPTION
    Integrates with Unity-Claude-Safety module to ensure Claude's fix
    meets safety criteria before application
    
    .PARAMETER FilePath
    Path to the file being modified
    
    .PARAMETER SuggestedFix
    Claude's suggested fix content
    
    .PARAMETER ClaudeResponse
    Full Claude response for additional context
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$SuggestedFix,
        
        [Parameter()]
        [string]$ClaudeResponse = ""
    )
    
    Write-FixEngineLog -Message "Validating Claude fix safety for: $FilePath" -Level "DEBUG"
    
    $safetyResult = @{
        IsSafe = $true
        Reason = "No safety concerns detected"
        Confidence = 0.8
        Warnings = @()
        Recommendations = @()
    }
    
    try {
        # Step 1: Basic content safety checks
        $contentSafety = Test-FixContentSafety -SuggestedFix $SuggestedFix
        if (-not $contentSafety.IsSafe) {
            $safetyResult.IsSafe = $false
            $safetyResult.Reason = $contentSafety.Reason
            return $safetyResult
        }
        
        # Step 2: File-specific safety checks
        $fileSafety = Test-FileSpecificSafety -FilePath $FilePath -SuggestedFix $SuggestedFix
        if (-not $fileSafety.IsSafe) {
            $safetyResult.IsSafe = $false
            $safetyResult.Reason = $fileSafety.Reason
            return $safetyResult
        }
        
        # Step 3: Integration with Unity-Claude-Safety module
        if ($script:FixEngineConfig.SafetyIntegrationEnabled -and (Test-RequiredModule -ModuleName "Unity-Claude-Safety")) {
            Write-FixEngineLog -Message "Checking with Unity-Claude-Safety module" -Level "DEBUG"
            
            $moduleSafetyResult = Test-FixSafety -FilePath $FilePath -Confidence $safetyResult.Confidence -FixContent $SuggestedFix
            
            if (-not $moduleSafetyResult.IsSafe) {
                $safetyResult.IsSafe = $false
                $safetyResult.Reason = $moduleSafetyResult.Reason
                return $safetyResult
            }
        }
        
        # Step 4: Calculate confidence based on fix complexity
        $safetyResult.Confidence = Calculate-FixConfidence -SuggestedFix $SuggestedFix -ClaudeResponse $ClaudeResponse
        
        # Step 5: Generate warnings and recommendations
        $safetyResult.Warnings = Get-SafetyWarnings -SuggestedFix $SuggestedFix -FilePath $FilePath
        $safetyResult.Recommendations = Get-SafetyRecommendations -SuggestedFix $SuggestedFix -FilePath $FilePath
        
        Write-FixEngineLog -Message "Claude fix safety validation completed. Safe: $($safetyResult.IsSafe), Confidence: $($safetyResult.Confidence)" -Level "DEBUG"
        
    }
    catch {
        $safetyResult.IsSafe = $false
        $safetyResult.Reason = "Safety validation failed: $_"
        Write-FixEngineLog -Message $safetyResult.Reason -Level "ERROR"
    }
    
    return $safetyResult
}

function Test-FixContentSafety {
    <#
    .SYNOPSIS
    Performs basic content safety analysis on Claude's fix
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SuggestedFix
    )
    
    $result = @{
        IsSafe = $true
        Reason = "Content appears safe"
    }
    
    try {
        # Check for dangerous operations
        $dangerousPatterns = @(
            'File\.Delete\(',
            'Directory\.Delete\(',
            'Process\.Start\(',
            'Registry\.',
            'Environment\.Exit\(',
            'Application\.Quit\(',
            'UnityEditor\.AssetDatabase\.DeleteAsset\(',
            'System\.IO\.File\.Delete\(',
            'Remove-Item',
            'rm -rf',
            'del /f',
            'exec\(',
            'eval\(',
            'Invoke-Expression'
        )
        
        foreach ($pattern in $dangerousPatterns) {
            if ($SuggestedFix -match $pattern) {
                $result.IsSafe = $false
                $result.Reason = "Potentially dangerous operation detected: $pattern"
                Write-FixEngineLog -Message $result.Reason -Level "WARN"
                return $result
            }
        }
        
        # Check for suspicious external calls
        if ($SuggestedFix -match 'System\.Net\.' -or $SuggestedFix -match 'WebClient' -or $SuggestedFix -match 'HttpClient') {
            $result.IsSafe = $false
            $result.Reason = "Network operations detected in fix - manual review required"
            Write-FixEngineLog -Message $result.Reason -Level "WARN"
            return $result
        }
        
        # Check for reflection usage (potentially dangerous)
        if ($SuggestedFix -match 'System\.Reflection\.' -or $SuggestedFix -match 'Assembly\.Load') {
            $result.IsSafe = $false
            $result.Reason = "Reflection operations detected - manual review required"
            Write-FixEngineLog -Message $result.Reason -Level "WARN"
            return $result
        }
        
        # Check for native code interop
        if ($SuggestedFix -match '\[DllImport\]' -or $SuggestedFix -match 'Marshal\.') {
            $result.IsSafe = $false
            $result.Reason = "Native code interop detected - manual review required"
            Write-FixEngineLog -Message $result.Reason -Level "WARN"
            return $result
        }
        
        Write-FixEngineLog -Message "Content safety check passed" -Level "DEBUG"
        
    }
    catch {
        $result.IsSafe = $false
        $result.Reason = "Content safety check failed: $_"
        Write-FixEngineLog -Message $result.Reason -Level "ERROR"
    }
    
    return $result
}

function Test-FileSpecificSafety {
    <#
    .SYNOPSIS
    Performs file-specific safety checks based on file location and type
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$SuggestedFix
    )
    
    $result = @{
        IsSafe = $true
        Reason = "File-specific checks passed"
    }
    
    try {
        # Check if modifying critical Unity files
        $criticalFolders = @(
            "ProjectSettings",
            "Packages",
            "Library"
        )
        
        foreach ($folder in $criticalFolders) {
            if ($FilePath -match $folder) {
                $result.IsSafe = $false
                $result.Reason = "Attempting to modify critical Unity folder: $folder"
                Write-FixEngineLog -Message $result.Reason -Level "WARN"
                return $result
            }
        }
        
        # Check for Editor script modifications with runtime code
        if ($FilePath -match "Editor" -and $SuggestedFix -match "MonoBehaviour|Start\(\)|Update\(\)|Awake\(\)") {
            $result.IsSafe = $false
            $result.Reason = "Runtime code detected in Editor script"
            Write-FixEngineLog -Message $result.Reason -Level "WARN"
            return $result
        }
        
        # Check for main scene or essential game files
        $essentialFiles = @(
            "GameManager",
            "PlayerController", 
            "MainMenu",
            "SceneManager"
        )
        
        $fileName = Split-Path $FilePath -Leaf
        foreach ($essential in $essentialFiles) {
            if ($fileName -match $essential -and $SuggestedFix.Length -gt 1000) {
                # Large changes to essential files require higher scrutiny
                $result.IsSafe = $false
                $result.Reason = "Large modification suggested for essential file: $fileName"
                Write-FixEngineLog -Message $result.Reason -Level "WARN"
                return $result
            }
        }
        
        Write-FixEngineLog -Message "File-specific safety check passed" -Level "DEBUG"
        
    }
    catch {
        $result.IsSafe = $false
        $result.Reason = "File-specific safety check failed: $_"
        Write-FixEngineLog -Message $result.Reason -Level "ERROR"
    }
    
    return $result
}

function Calculate-FixConfidence {
    <#
    .SYNOPSIS
    Calculates confidence score for Claude's fix based on various factors
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SuggestedFix,
        
        [Parameter()]
        [string]$ClaudeResponse = ""
    )
    
    $baseConfidence = 0.7
    $factors = @()
    
    try {
        # Factor 1: Fix size (smaller is generally safer)
        $fixLength = $SuggestedFix.Length
        if ($fixLength -lt 100) {
            $factors += 0.1  # Small fix bonus
        } elseif ($fixLength -gt 1000) {
            $factors += -0.2  # Large fix penalty
        }
        
        # Factor 2: Fix type
        if ($SuggestedFix -match '^\s*using\s+') {
            $factors += 0.2  # Using statement fixes are generally safe
        }
        
        if ($SuggestedFix -match 'class\s+\w+' -and $SuggestedFix -match '\{.*\}') {
            $factors += -0.1  # Complete class replacement is riskier
        }
        
        # Factor 3: Claude's explanation quality
        if ($ClaudeResponse.Length -gt 200 -and $ClaudeResponse -match 'because|reason|explanation') {
            $factors += 0.1  # Good explanation bonus
        }
        
        # Factor 4: Presence of comments in fix
        if ($SuggestedFix -match '//.*' -or $SuggestedFix -match '/\*.*\*/') {
            $factors += 0.05  # Comments suggest thoughtful fix
        }
        
        # Calculate final confidence
        $finalConfidence = $baseConfidence + ($factors | Measure-Object -Sum).Sum
        
        # Clamp between 0.1 and 0.95
        $finalConfidence = [Math]::Max(0.1, [Math]::Min(0.95, $finalConfidence))
        
        Write-FixEngineLog -Message "Calculated fix confidence: $finalConfidence (factors: $($factors -join ', '))" -Level "DEBUG"
        
        return $finalConfidence
    }
    catch {
        Write-FixEngineLog -Message "Failed to calculate fix confidence: $_" -Level "WARN"
        return 0.5  # Default moderate confidence
    }
}

function Get-SafetyWarnings {
    <#
    .SYNOPSIS
    Generates safety warnings for the suggested fix
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SuggestedFix,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $warnings = @()
    
    try {
        # Large file replacement warning
        if ($SuggestedFix.Length -gt 2000) {
            $warnings += "Large fix detected ($($SuggestedFix.Length) characters) - consider reviewing manually"
        }
        
        # Complex code pattern warning
        if ($SuggestedFix -match 'unsafe\s+' -or $SuggestedFix -match 'fixed\s+') {
            $warnings += "Unsafe code detected in fix"
        }
        
        # Threading warning
        if ($SuggestedFix -match 'Thread\.' -or $SuggestedFix -match 'Task\.' -or $SuggestedFix -match 'async\s+') {
            $warnings += "Threading/async code detected - ensure Unity main thread compatibility"
        }
        
        # Performance warning
        if ($SuggestedFix -match 'foreach.*Update\(' -or $SuggestedFix -match 'Find.*Update\(') {
            $warnings += "Potential performance issue detected - operations in Update() method"
        }
        
        # Unity lifecycle warning
        if ($SuggestedFix -match 'OnDestroy' -or $SuggestedFix -match 'OnApplicationQuit') {
            $warnings += "Unity lifecycle methods detected - ensure proper cleanup"
        }
        
        Write-FixEngineLog -Message "Generated $($warnings.Count) safety warnings" -Level "DEBUG"
        
    }
    catch {
        Write-FixEngineLog -Message "Failed to generate safety warnings: $_" -Level "WARN"
    }
    
    return $warnings
}

function Get-SafetyRecommendations {
    <#
    .SYNOPSIS
    Generates safety recommendations for the suggested fix
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SuggestedFix,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $recommendations = @()
    
    try {
        # Backup recommendation for large changes
        if ($SuggestedFix.Length -gt 1000) {
            $recommendations += "Consider creating additional manual backup before applying large fix"
        }
        
        # Testing recommendation
        if ($SuggestedFix -match 'public\s+class' -or $SuggestedFix -match 'public\s+.*void') {
            $recommendations += "Test the modified functionality thoroughly after applying fix"
        }
        
        # Version control recommendation
        if ($FilePath -match "GameManager|PlayerController|MainMenu") {
            $recommendations += "Commit current state to version control before applying fix to essential file"
        }
        
        # Code review recommendation
        if ($SuggestedFix -match 'using\s+System\.' -and $SuggestedFix -match '\{.*\}') {
            $recommendations += "Consider code review for complex fix involving system namespaces"
        }
        
        Write-FixEngineLog -Message "Generated $($recommendations.Count) safety recommendations" -Level "DEBUG"
        
    }
    catch {
        Write-FixEngineLog -Message "Failed to generate safety recommendations: $_" -Level "WARN"
    }
    
    return $recommendations
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWtXiTKccJkXjCFqjHTRa3HL1
# JNWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU7rCh/1EQGNd8ipmD2ikfd9KeE7MwDQYJKoZIhvcNAQEBBQAEggEAZKew
# JfeSIPhxN7zaugSvQrBOvV3PALwH7D/pdkYwsean/KSTJ7oaA1t07x3Zt6jQVido
# TwfXhUCE/W5+tOpKgMp8lu5amVBb3AdddZz6gSvCGOI0ZEKsJ6g54EjKOh6LXe7r
# 9Ih5MVGveY74zUSKZqIZ43la26ih3qWYEPljz1Iz52CWfkTC94lXsabT8OA4Jn+F
# hB5161JVUlzroUbJDe+Iz8w6dtgSSf7h9yUnubIyQfX69UjzpDEN3C1wm/fexAbA
# 2v+XGeTm6Q7l8aHqktWtlnFy4inSOxRoFObkXHZW41GNekbzoot08jPgQcDQrKTG
# yJG99gfTrxP8jYqV5Q==
# SIG # End signature block
