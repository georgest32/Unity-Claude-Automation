# Unity-Claude-CLIOrchestrator - JSON Processing Component  
# Refactored from ResponseAnalysisEngine.psm1 for better maintainability
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Module Configuration and Dependencies

# Import logging functionality
if (Get-Module -Name "AnalysisLogging") {
    # Already loaded, use existing functions
} else {
    # Load from relative path
    $loggingPath = Join-Path $PSScriptRoot "AnalysisLogging.psm1"
    if (Test-Path $loggingPath) {
        Import-Module $loggingPath -Force
    } else {
        # Fallback logging function
        function Write-AnalysisLog {
            param($Message, $Level = "INFO", $Component = "JsonProcessing")
            Write-Host "[$Level] [$Component] $Message"
        }
    }
}

# JSON processing configuration
$script:DefaultJsonConfig = @{
    TruncationPatterns = @(4000, 6000, 8000, 10000, 12000, 16000)
    MaxRetryAttempts = 3
    RetryDelayMs = @(500, 1000, 2000)
    PerformanceTargetMs = 200
    MaxJsonSize = 50MB
}

$script:JsonConfig = $script:DefaultJsonConfig.Clone()

#endregion

#region JSON Truncation Detection and Recovery

function Test-JsonTruncation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString
    )
    
    Write-AnalysisLog -Message "Testing for JSON truncation - length: $($JsonString.Length)" -Level "DEBUG" -Component "JsonProcessing"
    
    # Check for known truncation patterns
    foreach ($pattern in $script:JsonConfig.TruncationPatterns) {
        if ([Math]::Abs($JsonString.Length - $pattern) -lt 50) {
            Write-AnalysisLog -Message "Potential truncation detected at position: $pattern (actual: $($JsonString.Length))" -Level "WARN" -Component "JsonProcessing"
            return $true
        }
    }
    
    # Check for unterminated strings or objects
    $openBraces = ($JsonString.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($JsonString.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    $openBrackets = ($JsonString.ToCharArray() | Where-Object { $_ -eq '[' }).Count
    $closeBrackets = ($JsonString.ToCharArray() | Where-Object { $_ -eq ']' }).Count
    
    if ($openBraces -ne $closeBraces -or $openBrackets -ne $closeBrackets) {
        Write-AnalysisLog -Message "Unbalanced JSON braces/brackets detected - likely truncated" -Level "WARN" -Component "JsonProcessing"
        return $true
    }
    
    # Check for unterminated strings (basic heuristic)
    if ($JsonString.EndsWith('"') -and -not $JsonString.EndsWith('"}') -and -not $JsonString.EndsWith('"]')) {
        Write-AnalysisLog -Message "Potential unterminated string detected" -Level "WARN" -Component "JsonProcessing"
        return $true
    }
    
    return $false
}

function Repair-TruncatedJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString
    )
    
    Write-AnalysisLog -Message "Attempting to repair truncated JSON" -Level "INFO" -Component "JsonProcessing"
    
    $repairedJson = $JsonString
    
    # Remove incomplete final property if present
    if ($repairedJson.EndsWith(',')) {
        $repairedJson = $repairedJson.Substring(0, $repairedJson.Length - 1)
        Write-AnalysisLog -Message "Removed trailing comma" -Level "DEBUG" -Component "JsonProcessing"
    }
    
    # Close unterminated strings
    $quoteCount = ($repairedJson.ToCharArray() | Where-Object { $_ -eq '"' }).Count
    if ($quoteCount % 2 -eq 1) {
        $repairedJson += '"'
        Write-AnalysisLog -Message "Added missing closing quote" -Level "DEBUG" -Component "JsonProcessing"
    }
    
    # Balance braces and brackets
    $openBraces = ($repairedJson.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($repairedJson.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    $openBrackets = ($repairedJson.ToCharArray() | Where-Object { $_ -eq '[' }).Count
    $closeBrackets = ($repairedJson.ToCharArray() | Where-Object { $_ -eq ']' }).Count
    
    # Add missing closing braces
    $bracesToAdd = $openBraces - $closeBraces
    if ($bracesToAdd -gt 0) {
        $repairedJson += ('}' * $bracesToAdd)
        Write-AnalysisLog -Message "Added $bracesToAdd missing closing braces" -Level "DEBUG" -Component "JsonProcessing"
    }
    
    # Add missing closing brackets  
    $bracketsToAdd = $openBrackets - $closeBrackets
    if ($bracketsToAdd -gt 0) {
        $repairedJson += (']' * $bracketsToAdd)
        Write-AnalysisLog -Message "Added $bracketsToAdd missing closing brackets" -Level "DEBUG" -Component "JsonProcessing"
    }
    
    Write-AnalysisLog -Message "JSON repair completed - new length: $($repairedJson.Length)" -Level "INFO" -Component "JsonProcessing"
    return $repairedJson
}

#endregion

#region Multi-Parser System

function ConvertFrom-JsonFast {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString,
        
        [Parameter()]
        [switch]$AsHashtable
    )
    
    Write-AnalysisLog -Message "Using optimized JSON parsing" -Level "DEBUG" -Component "JsonProcessing"
    
    try {
        if ($AsHashtable) {
            # PowerShell 7+ feature, fallback for 5.1
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                return ConvertFrom-Json $InputString -AsHashtable
            } else {
                # PowerShell 5.1 workaround
                $parsed = ConvertFrom-Json $InputString
                return $parsed
            }
        } else {
            return ConvertFrom-Json $InputString
        }
    } catch {
        Write-AnalysisLog -Message "ConvertFrom-JsonFast failed: $($_.Exception.Message)" -Level "ERROR" -Component "JsonProcessing"
        throw
    }
}

function Invoke-MultiParserJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString,
        
        [Parameter()]
        [switch]$AsHashtable,
        
        [Parameter()]
        [switch]$RepairTruncation
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-AnalysisLog -Message "Starting multi-parser JSON processing" -Level "DEBUG" -Component "JsonProcessing"
    
    try {
        # Check for truncation and repair if requested
        if ($RepairTruncation -and (Test-JsonTruncation -JsonString $JsonString)) {
            Write-AnalysisLog -Message "Truncation detected - attempting repair" -Level "WARN" -Component "JsonProcessing"
            $JsonString = Repair-TruncatedJson -JsonString $JsonString
        }
        
        # Primary parser: ConvertFrom-JsonFast (if available) or optimized built-in
        try {
            Write-AnalysisLog -Message "Attempting primary parser (ConvertFrom-JsonFast)" -Level "DEBUG" -Component "JsonProcessing"
            $result = ConvertFrom-JsonFast -InputString $JsonString -AsHashtable:$AsHashtable
            
            $stopwatch.Stop()
            Write-AnalysisLog -Message "Primary parser successful in $($stopwatch.ElapsedMilliseconds)ms" -Level "PERF" -Component "JsonProcessing"
            return $result
            
        } catch {
            Write-AnalysisLog -Message "Primary parser failed: $($_.Exception.Message)" -Level "WARN" -Component "JsonProcessing"
        }
        
        # Fallback parser: Built-in ConvertFrom-Json
        try {
            Write-AnalysisLog -Message "Attempting fallback parser (ConvertFrom-Json)" -Level "DEBUG" -Component "JsonProcessing"
            
            if ($AsHashtable -and $PSVersionTable.PSVersion.Major -ge 7) {
                $result = ConvertFrom-Json $JsonString -AsHashtable -ErrorAction Stop
            } else {
                $result = ConvertFrom-Json $JsonString -ErrorAction Stop
            }
            
            $stopwatch.Stop()
            Write-AnalysisLog -Message "Fallback parser successful in $($stopwatch.ElapsedMilliseconds)ms" -Level "PERF" -Component "JsonProcessing"
            return $result
            
        } catch {
            Write-AnalysisLog -Message "Fallback parser failed: $($_.Exception.Message)" -Level "WARN" -Component "JsonProcessing"
        }
        
        # Final fallback: Return null as all parsing failed
        Write-AnalysisLog -Message "All JSON parsing attempts failed" -Level "ERROR" -Component "JsonProcessing"
        throw "All JSON parsers failed: Unable to parse JSON content"
        
    } finally {
        if ($stopwatch.IsRunning) {
            $stopwatch.Stop()
        }
        
        # Performance monitoring
        if ($stopwatch.ElapsedMilliseconds -gt $script:JsonConfig.PerformanceTargetMs) {
            Write-AnalysisLog -Message "JSON parsing exceeded performance target: $($stopwatch.ElapsedMilliseconds)ms > $($script:JsonConfig.PerformanceTargetMs)ms" -Level "WARN" -Component "JsonProcessing"
        }
    }
}

#endregion

#region Schema Validation

function Test-JsonSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString,
        
        [Parameter()]
        [string]$SchemaPath
    )
    
    Write-AnalysisLog -Message "Validating JSON schema" -Level "DEBUG" -Component "JsonProcessing"
    
    # Basic JSON syntax validation first
    try {
        if (Get-Command Test-Json -ErrorAction SilentlyContinue) {
            if ($SchemaPath -and (Test-Path $SchemaPath)) {
                Write-AnalysisLog -Message "Validating against schema: $SchemaPath" -Level "DEBUG" -Component "JsonProcessing"
                $isValid = $JsonString | Test-Json -SchemaFile $SchemaPath
            } else {
                Write-AnalysisLog -Message "Validating JSON syntax only" -Level "DEBUG" -Component "JsonProcessing"
                $isValid = $JsonString | Test-Json
            }
            
            if (-not $isValid) {
                Write-AnalysisLog -Message "JSON schema validation failed" -Level "ERROR" -Component "JsonProcessing"
                return $false
            }
        } else {
            Write-AnalysisLog -Message "Test-Json cmdlet not available - using try-catch validation" -Level "DEBUG" -Component "JsonProcessing"
            ConvertFrom-Json -InputString $JsonString -ErrorAction Stop | Out-Null
        }
        
        Write-AnalysisLog -Message "JSON schema validation successful" -Level "DEBUG" -Component "JsonProcessing"
        return $true
        
    } catch {
        Write-AnalysisLog -Message "JSON schema validation failed: $($_.Exception.Message)" -Level "ERROR" -Component "JsonProcessing"
        return $false
    }
}

function Test-AnthropicResponseSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ParsedJson
    )
    
    Write-AnalysisLog -Message "Validating Anthropic response schema" -Level "DEBUG" -Component "JsonProcessing"
    
    # Basic Claude Code CLI response structure validation
    $requiredFields = @()
    $hasRecommendation = $false
    
    try {
        # Check for common Claude Code CLI response patterns
        if ($ParsedJson -is [string]) {
            # String response - check for recommendation patterns
            $recommendationPatterns = @(
                'RECOMMENDATION:\s*(CONTINUE|TEST|FIX|COMPILE|RESTART|COMPLETE|ERROR)',
                'RECOMMENDED:\s*(TEST|FIX|CONTINUE|RESTART)',
                'Next steps?:\s*',
                'To validate this'
            )
            
            foreach ($pattern in $recommendationPatterns) {
                if ($ParsedJson -match $pattern) {
                    $hasRecommendation = $true
                    break
                }
            }
        } elseif ($ParsedJson -is [PSObject]) {
            # Object response - check for structured format
            $properties = $ParsedJson | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
            
            # Look for common response fields
            $commonFields = @('recommendation', 'action', 'next_step', 'result', 'status', 'response')
            foreach ($field in $commonFields) {
                if ($properties -contains $field) {
                    $hasRecommendation = $true
                    break
                }
            }
        }
        
        if ($hasRecommendation) {
            Write-AnalysisLog -Message "Valid Anthropic response structure detected" -Level "DEBUG" -Component "JsonProcessing"
            return $true
        } else {
            Write-AnalysisLog -Message "No valid recommendation pattern found in response" -Level "WARN" -Component "JsonProcessing"
            return $false
        }
        
    } catch {
        Write-AnalysisLog -Message "Anthropic schema validation failed: $($_.Exception.Message)" -Level "ERROR" -Component "JsonProcessing"
        return $false
    }
}

#endregion

#region Configuration Management

function Set-JsonProcessingConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int[]]$TruncationPatterns,
        
        [Parameter()]
        [int]$MaxRetryAttempts,
        
        [Parameter()]
        [int[]]$RetryDelayMs,
        
        [Parameter()]
        [int]$PerformanceTargetMs,
        
        [Parameter()]
        [long]$MaxJsonSize
    )
    
    if ($TruncationPatterns) { $script:JsonConfig.TruncationPatterns = $TruncationPatterns }
    if ($MaxRetryAttempts) { $script:JsonConfig.MaxRetryAttempts = $MaxRetryAttempts }
    if ($RetryDelayMs) { $script:JsonConfig.RetryDelayMs = $RetryDelayMs }
    if ($PerformanceTargetMs) { $script:JsonConfig.PerformanceTargetMs = $PerformanceTargetMs }
    if ($MaxJsonSize) { $script:JsonConfig.MaxJsonSize = $MaxJsonSize }
    
    Write-AnalysisLog -Message "JSON processing configuration updated" -Level "INFO" -Component "JsonProcessing"
}

function Get-JsonProcessingConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:JsonConfig
}

#endregion

#region Testing Functions

function Test-JsonProcessingComponent {
    [CmdletBinding()]
    param()
    
    $testResults = @()
    
    try {
        # Test basic JSON parsing
        $testJson = '{"test": "value", "number": 42}'
        $parsed = Invoke-MultiParserJson -JsonString $testJson
        
        if ($parsed.test -eq "value" -and $parsed.number -eq 42) {
            $testResults += @{
                Name = "Basic JSON Parsing"
                Status = "Passed"
                Details = "Successfully parsed simple JSON object"
            }
        } else {
            $testResults += @{
                Name = "Basic JSON Parsing"
                Status = "Failed"
                Details = "JSON parsing returned unexpected values"
            }
        }
        
        # Test truncation detection
        $truncatedJson = '{"incomplete": "value"'  # Missing closing brace
        $isTruncated = Test-JsonTruncation -JsonString $truncatedJson
        
        if ($isTruncated) {
            $testResults += @{
                Name = "Truncation Detection"
                Status = "Passed"
                Details = "Successfully detected truncated JSON"
            }
        } else {
            $testResults += @{
                Name = "Truncation Detection"
                Status = "Failed"  
                Details = "Failed to detect obvious truncation"
            }
        }
        
        # Test JSON repair
        $repairedJson = Repair-TruncatedJson -JsonString $truncatedJson
        $repairWorked = $false
        
        try {
            ConvertFrom-Json $repairedJson | Out-Null
            $repairWorked = $true
        } catch {
            # Repair didn't work
        }
        
        if ($repairWorked) {
            $testResults += @{
                Name = "JSON Repair"
                Status = "Passed"
                Details = "Successfully repaired truncated JSON"
            }
        } else {
            $testResults += @{
                Name = "JSON Repair"
                Status = "Failed"
                Details = "Repaired JSON still invalid"
            }
        }
        
        # Test schema validation
        $validJson = '{"recommendation": "TEST", "confidence": 0.85}'
        $isValidSchema = Test-JsonSchema -JsonString $validJson
        
        if ($isValidSchema) {
            $testResults += @{
                Name = "Schema Validation"
                Status = "Passed"
                Details = "JSON schema validation working"
            }
        } else {
            $testResults += @{
                Name = "Schema Validation"
                Status = "Failed"
                Details = "Valid JSON failed schema validation"
            }
        }
        
    } catch {
        $testResults += @{
            Name = "JSON Processing Component Test"
            Status = "Failed"
            Error = $_.Exception.Message
        }
    }
    
    return $testResults
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Test-JsonTruncation',
    'Repair-TruncatedJson',
    'ConvertFrom-JsonFast', 
    'Invoke-MultiParserJson',
    'Test-JsonSchema',
    'Test-AnthropicResponseSchema',
    'Set-JsonProcessingConfiguration',
    'Get-JsonProcessingConfiguration',
    'Test-JsonProcessingComponent'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCdpKn0ODn/yRgu
# qh9vmzSU3QlmbnHmdTABoVM1JZZPq6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIzzgArb+c/U6xbD3zXWlp4s
# JJrlPab+QHI9mrWxGdvHMA0GCSqGSIb3DQEBAQUABIIBACYFs6N6jUJfBlBAo+Mu
# QLBzGdlNYqecQ1kQLj1hHhXHpfjnojV1spD8NZvMooQcKcOnvIGh2Uo+gBtcN6W+
# YGvdb0XhewWqWmSAS76aNQENJmgKg1e/awm3idwumVqEP2Zrer16Sn5wvp79SBeQ
# harZlKT9H2Tm26p+6D4hV2BuD4E/rLWSkOwqkmNZXODVvUhos3CTsRqaycYkI8g6
# Hjs2JsN6jNxdZqcWehp0r0kW5gaWDcaLJIeOE9c+DMBNfJ3I/x9pzHDpfdY4MBrF
# gc+5R1yXFVFyncM467fOsDUva5ppOh4I7xXHny5MwscKvZpEfcoUAVYrYd9Ugfo4
# FFw=
# SIG # End signature block
