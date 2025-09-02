# Unity-Claude-CLIOrchestrator - Pattern Recognition & Classification Engine (Fixed)
# Phase 7 Day 1-2 Hours 5-8: Pattern Recognition & Classification Implementation
# Fixed version using dot-sourcing to avoid module nesting limit
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Module Configuration

$script:PatternConfig = @{
    ConfidenceThreshold = 0.75
    PatternCacheSize = 1000
    LearningEnabled = $true
    LoggingEnabled = $true
    PerformanceTracking = $true
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Dot-source nested components instead of Import-Module to avoid nesting limit
$moduleBasePath = $PSScriptRoot

try {
    # Check if functions are already available (from parent module dot-sourcing)
    $componentsToLoad = @(
        'RecommendationPatternEngine.psm1',
        'EntityContextEngine.psm1',
        'ResponseClassificationEngine.psm1',
        'BayesianConfidenceEngine.psm1'
    )
    
    foreach ($component in $componentsToLoad) {
        $componentPath = Join-Path $moduleBasePath $component
        
        # Only dot-source if the component file exists and we haven't already loaded it
        if (Test-Path $componentPath) {
            # Check if a key function from this component is already available
            $testFunction = switch ($component) {
                'RecommendationPatternEngine.psm1' { 'Find-RecommendationPatterns' }
                'EntityContextEngine.psm1' { 'Extract-ContextEntities' }
                'ResponseClassificationEngine.psm1' { 'Classify-ResponseType' }
                'BayesianConfidenceEngine.psm1' { 'Calculate-OverallConfidence' }
            }
            
            if (-not (Get-Command $testFunction -ErrorAction SilentlyContinue)) {
                . $componentPath
                Write-Verbose "Dot-sourced pattern recognition component: $component"
            } else {
                Write-Verbose "Pattern recognition component already loaded: $component"
            }
        } else {
            Write-Warning "Pattern recognition component not found: $componentPath"
        }
    }
    
    Write-Verbose "All pattern recognition sub-components loaded successfully"
} catch {
    Write-Warning "Failed to load some pattern recognition components: $($_.Exception.Message)"
}

#endregion

#region Logging Functions

function Write-PatternLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "PERF")]
        [string]$Level = "INFO"
    )
    
    if (-not $script:PatternConfig.LoggingEnabled) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [PATTERN] [$Level] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Force
    } catch {
        Write-Verbose "Failed to write to log: $_"
    }
}

#endregion

#region Main Pattern Recognition Function

function Invoke-PatternRecognitionAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive pattern recognition on Claude responses
    .DESCRIPTION
        Analyzes response text using multiple pattern engines to extract recommendations,
        entities, classifications, and confidence scores
    .PARAMETER ResponseText
        The raw response text to analyze
    .PARAMETER Context
        Optional context object with conversation history
    .OUTPUTS
        PSCustomObject with pattern recognition results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [PSCustomObject]$Context
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-PatternLog "Starting pattern recognition analysis" -Level "INFO"
    
    try {
        # Initialize result object
        $result = [PSCustomObject]@{
            Timestamp = Get-Date
            Success = $false
            Recommendations = @()
            Entities = @()
            Classification = $null
            Confidence = 0
            ProcessingTime = 0
            Errors = @()
        }
        
        # Find recommendation patterns
        try {
            $recommendations = Find-RecommendationPatterns -Text $ResponseText
            if ($recommendations) {
                $result.Recommendations = $recommendations
                Write-PatternLog "Found $($recommendations.Count) recommendation patterns" -Level "DEBUG"
            }
        } catch {
            Write-PatternLog "Error finding recommendations: $_" -Level "ERROR"
            $result.Errors += "Recommendation extraction failed: $_"
        }
        
        # Extract context entities
        try {
            $entities = Extract-ContextEntities -Text $ResponseText
            if ($entities) {
                $result.Entities = $entities
                Write-PatternLog "Extracted $($entities.Count) entities" -Level "DEBUG"
            }
        } catch {
            Write-PatternLog "Error extracting entities: $_" -Level "ERROR"
            $result.Errors += "Entity extraction failed: $_"
        }
        
        # Classify response type
        try {
            $classification = Classify-ResponseType -Text $ResponseText -Recommendations $result.Recommendations
            if ($classification) {
                $result.Classification = $classification
                Write-PatternLog "Classified as: $($classification.Type) with confidence $($classification.Confidence)" -Level "DEBUG"
            }
        } catch {
            Write-PatternLog "Error classifying response: $_" -Level "ERROR"
            $result.Errors += "Classification failed: $_"
        }
        
        # Calculate overall confidence
        try {
            $confidence = Calculate-OverallConfidence `
                -Recommendations $result.Recommendations `
                -Entities $result.Entities `
                -Classification $result.Classification `
                -Context $Context
            
            $result.Confidence = $confidence
            Write-PatternLog "Overall confidence: $confidence" -Level "DEBUG"
        } catch {
            Write-PatternLog "Error calculating confidence: $_" -Level "ERROR"
            $result.Errors += "Confidence calculation failed: $_"
        }
        
        $result.Success = ($result.Errors.Count -eq 0)
        
    } catch {
        Write-PatternLog "Critical error in pattern recognition: $_" -Level "ERROR"
        $result.Success = $false
        $result.Errors += "Critical error: $_"
    } finally {
        $stopwatch.Stop()
        $result.ProcessingTime = $stopwatch.ElapsedMilliseconds
        
        if ($script:PatternConfig.PerformanceTracking) {
            Write-PatternLog "Pattern recognition completed in $($stopwatch.ElapsedMilliseconds)ms" -Level "PERF"
        }
    }
    
    return $result
}

#endregion

#region Pattern Cache Management

$script:PatternCache = @{}

function Get-CachedPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key
    )
    
    if ($script:PatternCache.ContainsKey($Key)) {
        $entry = $script:PatternCache[$Key]
        if ((Get-Date) -lt $entry.Expiry) {
            Write-PatternLog "Cache hit for pattern: $Key" -Level "DEBUG"
            return $entry.Value
        } else {
            # Expired entry
            $script:PatternCache.Remove($Key)
        }
    }
    
    return $null
}

function Set-CachedPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        $Value,
        
        [Parameter()]
        [int]$ExpiryMinutes = 30
    )
    
    # Manage cache size
    if ($script:PatternCache.Count -ge $script:PatternConfig.PatternCacheSize) {
        # Remove oldest entries
        $oldest = $script:PatternCache.GetEnumerator() | 
            Sort-Object { $_.Value.Created } |
            Select-Object -First 100
        
        foreach ($entry in $oldest) {
            $script:PatternCache.Remove($entry.Key)
        }
    }
    
    $script:PatternCache[$Key] = @{
        Value = $Value
        Created = Get-Date
        Expiry = (Get-Date).AddMinutes($ExpiryMinutes)
    }
    
    Write-PatternLog "Cached pattern: $Key" -Level "DEBUG"
}

#endregion

# Export public functions
Export-ModuleMember -Function @(
    'Invoke-PatternRecognitionAnalysis',
    'Find-RecommendationPatterns',
    'Extract-ContextEntities',
    'Classify-ResponseType',
    'Calculate-OverallConfidence',
    'Write-PatternLog',
    'Get-CachedPattern',
    'Set-CachedPattern'
)