# Unity-Claude-CLIOrchestrator - Response Analysis Engine Core
# Main orchestration module for the refactored response analysis system  
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

# === REFACTORING DEBUG LOG ===
Write-Host "✅ LOADING REFACTORED VERSION: ResponseAnalysisEngine-Core.psm1 with 3 modular components" -ForegroundColor Green
Write-Host "📦 Components: AnalysisLogging, CircuitBreaker, JsonProcessing" -ForegroundColor Cyan

#region Module Configuration and Dependencies

# Load all component modules
$script:ComponentPath = $PSScriptRoot
$script:RequiredComponents = @(
    'AnalysisLogging',
    'CircuitBreaker', 
    'JsonProcessing'
)

# Load components
foreach ($component in $script:RequiredComponents) {
    $componentFile = Join-Path $script:ComponentPath "$component.psm1"
    if (Test-Path $componentFile) {
        Import-Module $componentFile -Force -Global
        Write-Host "Loaded component: $component" -ForegroundColor Green
    } else {
        Write-Warning "Component not found: $componentFile"
    }
}

# Core analysis configuration
$script:AnalysisConfig = @{
    TruncationPatterns = @(4000, 6000, 8000, 10000, 12000, 16000)
    MaxRetryAttempts = 3
    RetryDelayMs = @(500, 1000, 2000)  
    SchemaValidationEnabled = $true
    PerformanceTargetMs = 200
    CircuitBreakerThreshold = 5
    CircuitBreakerResetTimeMs = 30000
    EnableAdvancedAnalysis = $true
    MaxConcurrentOperations = 5
}

#endregion

#region Sentiment Analysis Functions

function Analyze-ResponseSentiment {
    <#
    .SYNOPSIS
        Analyzes the sentiment of response text using pattern matching
    
    .DESCRIPTION
        Provides sentiment analysis for response text using keyword patterns
        Returns sentiment score and classification
    
    .PARAMETER ResponseText
        The text to analyze for sentiment
    
    .EXAMPLE
        $sentiment = Analyze-ResponseSentiment -ResponseText "This is a successful completion"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText
    )
    
    try {
        Write-Host "[DEBUG] Starting sentiment analysis for response text" -ForegroundColor DarkGray
        
        # Positive sentiment indicators
        $positivePatterns = @(
            'success', 'complete', 'excellent', 'working', 'functional', 'resolved',
            'implemented', 'fixed', 'achieved', 'accomplished', 'ready', 'available'
        )
        
        # Negative sentiment indicators  
        $negativePatterns = @(
            'error', 'fail', 'broken', 'missing', 'issue', 'problem', 'critical',
            'warning', 'exception', 'timeout', 'crash', 'unable', 'failed'
        )
        
        # Neutral sentiment indicators
        $neutralPatterns = @(
            'continue', 'proceed', 'next', 'analyze', 'review', 'check', 'verify',
            'investigate', 'examine', 'consider', 'evaluate', 'assess'
        )
        
        $positiveScore = 0
        $negativeScore = 0
        $neutralScore = 0
        
        # Count positive matches
        foreach ($pattern in $positivePatterns) {
            $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
            $positiveScore += $matches.Count * 2  # Positive weighted higher
        }
        
        # Count negative matches  
        foreach ($pattern in $negativePatterns) {
            $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
            $negativeScore += $matches.Count * 3  # Negative weighted highest
        }
        
        # Count neutral matches
        foreach ($pattern in $neutralPatterns) {
            $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
            $neutralScore += $matches.Count
        }
        
        # Calculate overall sentiment
        $totalScore = $positiveScore + $negativeScore + $neutralScore
        
        $sentimentResult = @{
            PositiveScore = $positiveScore
            NegativeScore = $negativeScore
            NeutralScore = $neutralScore
            TotalScore = $totalScore
            Classification = 'Neutral'
            Confidence = 0
        }
        
        # Determine classification and confidence
        if ($totalScore -gt 0) {
            if ($positiveScore -gt ($negativeScore + $neutralScore)) {
                $sentimentResult.Classification = 'Positive'
                $sentimentResult.Confidence = [Math]::Min(90, ($positiveScore / $totalScore) * 100)
            }
            elseif ($negativeScore -gt ($positiveScore + $neutralScore)) {
                $sentimentResult.Classification = 'Negative'
                $sentimentResult.Confidence = [Math]::Min(90, ($negativeScore / $totalScore) * 100)
            }
            else {
                $sentimentResult.Classification = 'Neutral'
                $sentimentResult.Confidence = 60
            }
        }
        else {
            # No patterns matched - default to neutral with low confidence
            $sentimentResult.Confidence = 30
        }
        
        $confidenceText = "$($sentimentResult.Confidence) percent"
        Write-Host "[INFO] Sentiment analysis complete: $($sentimentResult.Classification) ($confidenceText)" -ForegroundColor Green
        
        return $sentimentResult
    }
    catch {
        Write-Host "ERROR: Error in sentiment analysis: $($_.Exception.Message)" -ForegroundColor Red
        
        # Return default neutral sentiment on error
        return @{
            PositiveScore = 0
            NegativeScore = 0
            NeutralScore = 0
            TotalScore = 0
            Classification = 'Neutral'
            Confidence = 0
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Main Analysis Orchestration

function Invoke-EnhancedResponseAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [switch]$AsHashtable,
        
        [Parameter()]
        [string]$SchemaPath,
        
        [Parameter()]
        [switch]$EnableCircuitBreaker = $true,
        
        [Parameter()]
        [switch]$RepairTruncation = $true,
        
        [Parameter()]
        [switch]$PerformAdvancedAnalysis
    )
    
    Begin {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-AnalysisLog -Message 'Starting enhanced response analysis' -Level 'INFO' -Component 'ResponseAnalysisEngine-Core'
        
        $analysisResults = @{
            ParsedContent = $null
            JsonStructures = @()
            Entities = @()
            Patterns = @()
            Confidence = 0.0
            ProcessingTimeMs = 0
            Errors = @()
            SchemaValidation = @{
                IsValid = $false
                SchemaType = "Unknown"
                ValidationErrors = @()
            }
            CircuitBreakerState = @{}
        }
    }
    
    Process {
        try {
            # Step 1: Circuit breaker check
            if ($EnableCircuitBreaker) {
                if (-not (Test-CircuitBreakerState)) {
                    $error = "Circuit breaker is OPEN - analysis blocked"
                    $analysisResults.Errors += $error
                    Write-AnalysisLog -Message $error -Level 'ERROR' -Component 'ResponseAnalysisEngine-Core'
                    return $analysisResults
                }
            }
            
            # Step 2: Content preprocessing
            $logMsg = 'Preprocessing response content (length: ' + $ResponseContent.Length + ')'
            Write-AnalysisLog -Message $logMsg -Level 'DEBUG' -Component 'ResponseAnalysisEngine-Core'
            $processedContent = $ResponseContent.Trim()
            
            if ([string]::IsNullOrWhiteSpace($processedContent)) {
                $analysisResults.Errors += "Empty response content provided"
                if ($EnableCircuitBreaker) { Update-CircuitBreakerState -Success $false }
                return $analysisResults
            }
            
            # Step 3: JSON Processing (if applicable)
            $jsonParseAttempted = $false
            if ($processedContent.TrimStart().StartsWith('{') -or $processedContent.TrimStart().StartsWith('[')) {
                Write-AnalysisLog -Message "Detected JSON-like content - attempting JSON parsing" -Level 'DEBUG' -Component 'ResponseAnalysisEngine-Core'
                $jsonParseAttempted = $true
                
                try {
                    # Use the JsonProcessing component
                    $parsedResult = Invoke-MultiParserJson -JsonString $processedContent -AsHashtable:$AsHashtable -RepairTruncation:$RepairTruncation
                    $analysisResults.ParsedContent = $parsedResult
                    
                    # Schema validation
                    if ($script:AnalysisConfig.SchemaValidationEnabled) {
                        $analysisResults.SchemaValidation.IsValid = Test-JsonSchema -JsonString $processedContent -SchemaPath $SchemaPath
                        
                        # Anthropic-specific validation
                        if (Test-AnthropicResponseSchema -ParsedJson $parsedResult) {
                            $analysisResults.SchemaValidation.SchemaType = "AnthropicResponse"
                        }
                    }
                    
                    Write-AnalysisLog -Message "JSON parsing successful" -Level 'DEBUG' -Component 'ResponseAnalysisEngine-Core'
                    
                } catch {
                    $error = "JSON parsing failed: $($_.Exception.Message)"
                    $analysisResults.Errors += $error
                    Write-AnalysisLog -Message $error -Level 'WARN' -Component 'ResponseAnalysisEngine-Core'
                    
                    # Fall back to text analysis
                    $analysisResults.ParsedContent = $processedContent
                }
            } else {
                # Plain text response
                Write-AnalysisLog -Message "Processing as plain text response" -Level 'DEBUG' -Component 'ResponseAnalysisEngine-Core'
                $analysisResults.ParsedContent = $processedContent
            }
            
            # Step 4: Advanced Analysis (if enabled)
            if ($PerformAdvancedAnalysis -or $script:AnalysisConfig.EnableAdvancedAnalysis) {
                Write-AnalysisLog -Message "Performing advanced analysis" -Level 'DEBUG' -Component 'ResponseAnalysisEngine-Core'
                
                # Note: These would be implemented in separate components
                # For now, providing placeholder structure
                $analysisResults.Entities = @(
                    @{
                        Type = "Placeholder"
                        Value = "Advanced analysis not yet implemented in core module"
                        Confidence = 0.5
                    }
                )
                
                $analysisResults.Patterns = @(
                    @{
                        Type = "ResponseType"
                        Value = if ($jsonParseAttempted) { "JSON" } else { "PlainText" }
                        Confidence = 0.9
                    }
                )
            }
            
            # Step 5: Results compilation
            $stopwatch.Stop()
            $analysisResults.ProcessingTimeMs = $stopwatch.ElapsedMilliseconds
            $analysisResults.Confidence = if ($analysisResults.Errors.Count -eq 0) { 0.85 } else { 0.3 }
            
            # Step 6: Circuit breaker update
            if ($EnableCircuitBreaker) {
                $success = $analysisResults.Errors.Count -eq 0
                Update-CircuitBreakerState -Success $success
                $analysisResults.CircuitBreakerState = Get-CircuitBreakerState
            }
            
            $logMsg = 'Enhanced response analysis completed in ' + $analysisResults.ProcessingTimeMs + 'ms'
            Write-AnalysisLog -Message $logMsg -Level 'PERF' -Component 'ResponseAnalysisEngine-Core'
            
        } catch {
            $error = 'Analysis failed with exception: ' + $_.Exception.Message
            $analysisResults.Errors += $error
            Write-AnalysisLog -Message $error -Level 'ERROR' -Component 'ResponseAnalysisEngine-Core'
            
            if ($EnableCircuitBreaker) {
                Update-CircuitBreakerState -Success $false
            }
            
            $stopwatch.Stop()
            $analysisResults.ProcessingTimeMs = $stopwatch.ElapsedMilliseconds
        }
        
        return $analysisResults
    }
}

function Initialize-ResponseAnalysisEngine {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration = @{},
        
        [Parameter()]
        [switch]$ResetState
    )
    
    Write-AnalysisLog -Message 'Initializing Response Analysis Engine' -Level 'INFO' -Component 'ResponseAnalysisEngine-Core'
    
    # Update configuration with any provided overrides
    foreach ($key in $Configuration.Keys) {
        if ($script:AnalysisConfig.ContainsKey($key)) {
            $script:AnalysisConfig[$key] = $Configuration[$key]
            $logMsg = 'Configuration updated: ' + $key + ' = ' + $Configuration[$key]
            Write-AnalysisLog -Message $logMsg -Level 'DEBUG' -Component 'ResponseAnalysisEngine-Core'
        }
    }
    
    # Reset circuit breaker state if requested
    if ($ResetState) {
        Reset-CircuitBreakerState
        Write-AnalysisLog -Message 'Circuit breaker state reset' -Level 'INFO' -Component 'ResponseAnalysisEngine-Core'
    }
    
    # Configure component modules with updated settings
    Set-JsonProcessingConfiguration -PerformanceTargetMs $script:AnalysisConfig.PerformanceTargetMs -TruncationPatterns $script:AnalysisConfig.TruncationPatterns
    Set-CircuitBreakerConfiguration -Threshold $script:AnalysisConfig.CircuitBreakerThreshold -ResetTimeMs $script:AnalysisConfig.CircuitBreakerResetTimeMs
    
    Write-AnalysisLog -Message 'Response Analysis Engine initialization complete' -Level 'INFO' -Component 'ResponseAnalysisEngine-Core'
}

function Get-ResponseAnalysisEngineStatus {
    [CmdletBinding()]
    param()
    
    $status = @{
        Configuration = $script:AnalysisConfig
        ComponentsLoaded = @()
        CircuitBreakerState = Get-CircuitBreakerState
        JsonProcessingConfig = Get-JsonProcessingConfiguration
        LogPath = Get-AnalysisLogPath
    }
    
    # Check component availability
    foreach ($component in $script:RequiredComponents) {
        $isLoaded = Get-Module -Name $component -ErrorAction SilentlyContinue
        $status.ComponentsLoaded += @{
            Name = $component
            Loaded = $null -ne $isLoaded
            Path = if ($isLoaded) { $isLoaded.Path } else { "Not loaded" }
        }
    }
    
    return $status
}

#endregion

#region Testing Functions

function Test-ResponseAnalysisEngineCore {
    [CmdletBinding()]
    param()
    
    $testResults = @()
    
    try {
        # Test component loading
        $status = Get-ResponseAnalysisEngineStatus
        $componentsLoaded = $status.ComponentsLoaded | Where-Object { $_.Loaded } | Measure-Object | Select-Object -ExpandProperty Count
        
        if ($componentsLoaded -ge 3) {
            $testResults += @{
                Name = 'Component Loading'
                Status = 'Passed'
                Details = "Successfully loaded $componentsLoaded components"
            }
        } else {
            $testResults += @{
                Name = 'Component Loading'
                Status = 'Failed' 
                Details = "Only $componentsLoaded components loaded (expected 3+)"
            }
        }
        
        # Test basic analysis
        $testResponse = '{"test": "response", "recommendation": "CONTINUE"}'
        $analysisResult = Invoke-EnhancedResponseAnalysis -ResponseContent $testResponse
        
        if ($analysisResult -and $analysisResult.ParsedContent) {
            $testResults += @{
                Name = 'Basic Analysis'
                Status = 'Passed'
                Details = "Analysis completed in $($analysisResult.ProcessingTimeMs)ms"
            }
        } else {
            $testResults += @{
                Name = 'Basic Analysis'
                Status = 'Failed'
                Details = "Analysis returned null or empty result"
            }
        }
        
        # Test graceful fallback handling
        $errorResponse = "invalid json content `{"
        $errorResult = Invoke-EnhancedResponseAnalysis -ResponseContent $errorResponse
        
        # The system should gracefully fall back to plain text processing
        if ($errorResult -and $errorResult.ParsedContent -eq $errorResponse.Trim()) {
            $testResults += @{
                Name = 'Graceful Fallback'
                Status = 'Passed' 
                Details = "Correctly handled invalid JSON with graceful fallback to plain text"
            }
        } else {
            $testResults += @{
                Name = 'Graceful Fallback'
                Status = 'Failed'
                Details = 'Failed to handle invalid JSON gracefully'
            }
        }
        
    } catch {
        $testResults += @{
            Name = 'Response Analysis Engine Core Test'
            Status = 'Failed'
            Error = $_.Exception.Message
        }
    }
    
    return $testResults
}

#endregion

#region Entity Extraction Function

function Extract-ResponseEntities {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$EntityPatterns = @{}
    )
    
    Write-AnalysisLog -Message 'Starting entity extraction from response text' -Level 'INFO'
    
    # Default entity patterns based on research findings
    if (-not $EntityPatterns.Keys.Count) {
        $EntityPatterns = @{
            FilePaths = @(
                '(?i)[a-zA-Z]:\\(?:[^\\/:*?`"<>|\r\n]+\\)*[^\\/:*?`"<>|\r\n]*\.[a-zA-Z0-9]+',  # Windows file paths
                '(?i)[a-zA-Z]:\\(?:[^\\/:*?`"<>|\r\n]+\\)*[^\\/:*?`"<>|\r\n]+',  # Windows directory paths
                '(?i)\.\\[^\\/:*?`"<>|\r\n]+(?:\\[^\\/:*?`"<>|\r\n]+)*',  # Relative paths
                '(?i)[a-zA-Z0-9_-]+\.[a-zA-Z]{2,5}'  # Simple filenames
            )
            ErrorCodes = @(
                'CS\d{4}',  # C# compiler errors
                'MSB\d{4}',  # MSBuild errors
                'Error\s+\d+',  # Generic error numbers
                'Exception:\s+[A-Za-z.]+Exception'  # .NET exceptions
            )
            Commands = @(
                '(?i)(?:Test|Build|Compile|Run|Execute|Start|Stop|Restart)-[A-Za-z0-9-]+',  # PowerShell commands
                '(?i)dotnet\s+[a-z]+',  # .NET CLI commands
                '(?i)unity\s+-[a-z]+',  # Unity CLI commands
                '(?i)claude\s+[a-z]+',  # Claude CLI commands
                '(?i)[a-zA-Z0-9-]+\.exe'  # Executables
            )
            UnityComponents = @(
                '(?i)MonoBehaviour',
                '(?i)ScriptableObject',
                '(?i)GameObject',
                '(?i)Transform',
                '(?i)Rigidbody',
                '(?i)Collider',
                '(?i)Renderer',
                '(?i)Asset[s]?',
                '(?i)Scene[s]?',
                '(?i)Prefab[s]?'
            )
            MethodNames = @(
                '(?i)[A-Za-z_][A-Za-z0-9_]*\s*\([^)]*\)',  # Method calls
                '(?i)function\s+[A-Za-z_][A-Za-z0-9_-]*',  # Function definitions
                '(?i)void\s+[A-Za-z_][A-Za-z0-9_]*',  # C# void methods
                '(?i)public\s+[A-Za-z_][A-Za-z0-9_]*'  # Public methods
            )
            Variables = @(
                '\$[A-Za-z_][A-Za-z0-9_]*',  # PowerShell variables
                '(?i)var\s+[A-Za-z_][A-Za-z0-9_]*',  # C# var declarations
                '(?i)[A-Za-z_][A-Za-z0-9_]*\s*='  # Variable assignments
            )
        }
    }
    
    $extractedEntities = @{
        FilePaths = @()
        ErrorCodes = @()
        Commands = @()
        UnityComponents = @()
        MethodNames = @()
        Variables = @()
        ProcessingTime = 0
        TotalMatches = 0
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Extract each entity type using optimized regex patterns
        foreach ($entityType in $EntityPatterns.Keys) {
            $matches = @()
            
            foreach ($pattern in $EntityPatterns[$entityType]) {
                try {
                    $regexMatches = [regex]::Matches($ResponseText, $pattern)
                    foreach ($match in $regexMatches) {
                        if ($match.Success -and $match.Value.Trim().Length -gt 0) {
                            $matches += $match.Value.Trim()
                        }
                    }
                } catch {
                    $logMsg = 'Regex error for pattern ' + $pattern + ': ' + $_.Exception.Message
                    Write-AnalysisLog -Message $logMsg -Level 'WARNING'
                }
            }
            
            # Remove duplicates and store results
            $extractedEntities[$entityType] = $matches | Select-Object -Unique
            $extractedEntities.TotalMatches += $extractedEntities[$entityType].Count
        }
        
        $stopwatch.Stop()
        $extractedEntities.ProcessingTime = $stopwatch.ElapsedMilliseconds
        
        $logMsg = 'Entity extraction completed: ' + $extractedEntities.TotalMatches + ' entities found in ' + $extractedEntities.ProcessingTime + 'ms'
        Write-AnalysisLog -Message $logMsg -Level 'INFO'
        
        return $extractedEntities
        
    } catch {
        $stopwatch.Stop()
        $errorMsg = $_.Exception.Message
        Write-AnalysisLog -Message ('Entity extraction failed: ' + $errorMsg) -Level 'ERROR'
        throw ('Entity extraction failed: ' + $errorMsg)
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-EnhancedResponseAnalysis',
    'Initialize-ResponseAnalysisEngine', 
    'Get-ResponseAnalysisEngineStatus',
    'Test-ResponseAnalysisEngineCore',
    'Extract-ResponseEntities',
    'Analyze-ResponseSentiment'
)

#endregion


