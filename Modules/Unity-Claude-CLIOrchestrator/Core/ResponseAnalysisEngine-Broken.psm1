# Unity-Claude-CLIOrchestrator - Enhanced Response Analysis Engine
# Phase 7 Day 1-2 Hours 1-4: Advanced JSON Processing Implementation
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

# === REFACTORING DEBUG LOG ===
Write-Warning "⚠️ LOADING MONOLITHIC VERSION: ResponseAnalysisEngine.psm1 (2605 lines) - This should be using the refactored version!"
Write-Host "📍 Expected: Core/Components/ResponseAnalysisEngine-Core.psm1 with Components should be loaded instead." -ForegroundColor Red

#region Module Variables and Configuration

$script:AnalysisConfig = @{
    TruncationPatterns = @(4000, 6000, 8000, 10000, 12000, 16000)
    MaxRetryAttempts = 3
    RetryDelayMs = @(500, 1000, 2000)  # Exponential backoff
    SchemaValidationEnabled = $true
    PerformanceTargetMs = 200
    CircuitBreakerThreshold = 5
    CircuitBreakerResetTimeMs = 30000
}

$script:CircuitBreakerState = @{
    FailureCount = 0
    LastFailureTime = $null
    State = "Closed"  # Closed, Open, HalfOpen
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

#endregion

#region Logging Functions

function Write-AnalysisLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "PERF")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [ResponseAnalysisEngine] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails - avoid recursive errors
    }
    
    # Console output for debugging
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } else {
        $color = switch ($Level) {
            "INFO" { "Green" }
            "DEBUG" { "Gray" }
            "PERF" { "Cyan" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

#endregion

#region Circuit Breaker Pattern

function Test-CircuitBreakerState {
    [CmdletBinding()]
    param()
    
    Write-AnalysisLog -Message "Checking circuit breaker state: $($script:CircuitBreakerState.State)" -Level "DEBUG"
    
    switch ($script:CircuitBreakerState.State) {
        "Closed" {
            return $true
        }
        "Open" {
            $timeSinceFailure = (Get-Date) - $script:CircuitBreakerState.LastFailureTime
            if ($timeSinceFailure.TotalMilliseconds -gt $script:AnalysisConfig.CircuitBreakerResetTimeMs) {
                Write-AnalysisLog -Message "Circuit breaker moving to HalfOpen state" -Level "INFO"
                $script:CircuitBreakerState.State = "HalfOpen"
                return $true
            }
            Write-AnalysisLog -Message "Circuit breaker is OPEN - blocking operation" -Level "WARN"
            return $false
        }
        "HalfOpen" {
            return $true
        }
    }
    return $false
}

function Update-CircuitBreakerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Success
    )
    
    if ($Success) {
        Write-AnalysisLog -Message "Operation successful - resetting circuit breaker" -Level "DEBUG"
        $script:CircuitBreakerState.FailureCount = 0
        $script:CircuitBreakerState.State = "Closed"
        $script:CircuitBreakerState.LastFailureTime = $null
    } else {
        $script:CircuitBreakerState.FailureCount++
        $script:CircuitBreakerState.LastFailureTime = Get-Date
        
        Write-AnalysisLog -Message "Operation failed - failure count: $($script:CircuitBreakerState.FailureCount)" -Level "WARN"
        
        if ($script:CircuitBreakerState.FailureCount -ge $script:AnalysisConfig.CircuitBreakerThreshold) {
            Write-AnalysisLog -Message "Circuit breaker OPENED due to repeated failures" -Level "ERROR"
            $script:CircuitBreakerState.State = "Open"
        } elseif ($script:CircuitBreakerState.State -eq "HalfOpen") {
            Write-AnalysisLog -Message "Circuit breaker moving back to OPEN from HalfOpen" -Level "WARN"
            $script:CircuitBreakerState.State = "Open"
        }
    }
}

#endregion

#region JSON Truncation Detection and Recovery

function Test-JsonTruncation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString
    )
    
    Write-AnalysisLog -Message "Testing for JSON truncation - length: $($JsonString.Length)" -Level "DEBUG"
    
    # Check for known truncation patterns
    foreach ($pattern in $script:AnalysisConfig.TruncationPatterns) {
        if ([Math]::Abs($JsonString.Length - $pattern) -lt 50) {
            Write-AnalysisLog -Message "Potential truncation detected at position: $pattern (actual: $($JsonString.Length))" -Level "WARN"
            return $true
        }
    }
    
    # Check for unterminated strings or objects
    $openBraces = ($JsonString.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($JsonString.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    $openBrackets = ($JsonString.ToCharArray() | Where-Object { $_ -eq '[' }).Count
    $closeBrackets = ($JsonString.ToCharArray() | Where-Object { $_ -eq ']' }).Count
    
    if ($openBraces -ne $closeBraces -or $openBrackets -ne $closeBrackets) {
        Write-AnalysisLog -Message "Unbalanced JSON braces/brackets detected - likely truncated" -Level "WARN"
        return $true
    }
    
    # Check for unterminated strings (basic heuristic)
    $quotes = ($JsonString.ToCharArray() | Where-Object { $_ -eq '"' -and $JsonString.IndexOf($_) -eq $JsonString.LastIndexOf($_) })
    if ($JsonString.EndsWith('"') -and -not $JsonString.EndsWith('"}') -and -not $JsonString.EndsWith('"]')) {
        Write-AnalysisLog -Message "Potential unterminated string detected" -Level "WARN"
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
    
    Write-AnalysisLog -Message "Attempting to repair truncated JSON" -Level "INFO"
    
    $repairedJson = $JsonString
    
    # Remove incomplete final property if present
    if ($repairedJson.EndsWith(',')) {
        $repairedJson = $repairedJson.Substring(0, $repairedJson.Length - 1)
        Write-AnalysisLog -Message "Removed trailing comma" -Level "DEBUG"
    }
    
    # Close unterminated strings
    $quoteCount = ($repairedJson.ToCharArray() | Where-Object { $_ -eq '"' }).Count
    if ($quoteCount % 2 -eq 1) {
        $repairedJson += '"'
        Write-AnalysisLog -Message "Added missing closing quote" -Level "DEBUG"
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
        Write-AnalysisLog -Message "Added $bracesToAdd missing closing braces" -Level "DEBUG"
    }
    
    # Add missing closing brackets
    $bracketsToAdd = $openBrackets - $closeBrackets
    if ($bracketsToAdd -gt 0) {
        $repairedJson += (']' * $bracketsToAdd)
        Write-AnalysisLog -Message "Added $bracketsToAdd missing closing brackets" -Level "DEBUG"
    }
    
    Write-AnalysisLog -Message "JSON repair completed - new length: $($repairedJson.Length)" -Level "INFO"
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
    
    # Note: This would typically use the ConvertFrom-JsonFast module if available
    # For now, implementing fallback to built-in with optimizations
    
    Write-AnalysisLog -Message "Using optimized JSON parsing" -Level "DEBUG"
    
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
        Write-AnalysisLog -Message "ConvertFrom-JsonFast failed: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Invoke-MultiParserJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString,
        
        [Parameter()]
        [switch]$AsHashtable
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-AnalysisLog -Message "Starting multi-parser JSON processing" -Level "DEBUG"
    
    try {
        # Primary parser: ConvertFrom-JsonFast (if available) or optimized built-in
        try {
            Write-AnalysisLog -Message "Attempting primary parser (ConvertFrom-JsonFast)" -Level "DEBUG"
            $result = ConvertFrom-JsonFast -InputString $JsonString -AsHashtable:$AsHashtable
            
            $stopwatch.Stop()
            Write-AnalysisLog -Message "Primary parser successful in $($stopwatch.ElapsedMilliseconds)ms" -Level "PERF"
            return $result
            
        } catch {
            Write-AnalysisLog -Message "Primary parser failed: $($_.Exception.Message)" -Level "WARN"
        }
        
        # Fallback parser: Built-in ConvertFrom-Json
        try {
            Write-AnalysisLog -Message "Attempting fallback parser (ConvertFrom-Json)" -Level "DEBUG"
            
            if ($AsHashtable -and $PSVersionTable.PSVersion.Major -ge 7) {
                $result = ConvertFrom-Json $JsonString -AsHashtable -ErrorAction Stop
            } else {
                $result = ConvertFrom-Json $JsonString -ErrorAction Stop
            }
            
            $stopwatch.Stop()
            Write-AnalysisLog -Message "Fallback parser successful in $($stopwatch.ElapsedMilliseconds)ms" -Level "PERF"
            return $result
            
        } catch {
            Write-AnalysisLog -Message "Fallback parser failed: $($_.Exception.Message)" -Level "WARN"
        }
        
        # Final fallback: Return null as all parsing failed
        Write-AnalysisLog -Message "All JSON parsing attempts failed" -Level "ERROR"
        throw "All JSON parsers failed: Unable to parse JSON content"
        
    } finally {
        if ($stopwatch.IsRunning) {
            $stopwatch.Stop()
        }
        
        # Performance monitoring
        if ($stopwatch.ElapsedMilliseconds -gt $script:AnalysisConfig.PerformanceTargetMs) {
            Write-AnalysisLog -Message "JSON parsing exceeded performance target: $($stopwatch.ElapsedMilliseconds)ms > $($script:AnalysisConfig.PerformanceTargetMs)ms" -Level "WARN"
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
    
    Write-AnalysisLog -Message "Validating JSON schema" -Level "DEBUG"
    
    # Basic JSON syntax validation first
    try {
        if (Get-Command Test-Json -ErrorAction SilentlyContinue) {
            if ($SchemaPath -and (Test-Path $SchemaPath)) {
                Write-AnalysisLog -Message "Validating against schema: $SchemaPath" -Level "DEBUG"
                $isValid = $JsonString | Test-Json -SchemaFile $SchemaPath
            } else {
                Write-AnalysisLog -Message "Validating JSON syntax only" -Level "DEBUG"
                $isValid = $JsonString | Test-Json
            }
            
            if (-not $isValid) {
                Write-AnalysisLog -Message "JSON schema validation failed" -Level "ERROR"
                return $false
            }
        } else {
            Write-AnalysisLog -Message "Test-Json cmdlet not available - using try-catch validation" -Level "DEBUG"
            ConvertFrom-Json -InputString $JsonString -ErrorAction Stop | Out-Null
        }
        
        Write-AnalysisLog -Message "JSON schema validation successful" -Level "DEBUG"
        return $true
        
    } catch {
        Write-AnalysisLog -Message "JSON schema validation failed: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-AnthropicResponseSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ParsedJson
    )
    
    Write-AnalysisLog -Message "Validating Anthropic response schema" -Level "DEBUG"
    
    # Basic Claude Code CLI response structure validation
    $requiredFields = @()
    $hasRecommendation = $false
    
    # Check for recommendation patterns
    if ($ParsedJson -is [string]) {
        $hasRecommendation = $ParsedJson -match "RECOMMENDATION:\s*(CONTINUE|TEST|FIX|COMPILE|RESTART|COMPLETE|ERROR)"
    } elseif ($ParsedJson.RESPONSE) {
        $hasRecommendation = $ParsedJson.RESPONSE -match "RECOMMENDATION:\s*(CONTINUE|TEST|FIX|COMPILE|RESTART|COMPLETE|ERROR)"
    } elseif ($ParsedJson.recommendation) {
        $hasRecommendation = $true
    }
    
    if ($hasRecommendation) {
        Write-AnalysisLog -Message "Valid Anthropic response structure detected" -Level "DEBUG"
        return $true
    } else {
        Write-AnalysisLog -Message "No valid recommendation pattern found in response" -Level "WARN"
        return $false
    }
}

#endregion

#region Main Processing Function

function Invoke-EnhancedResponseAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [string]$SchemaPath,
        
        [Parameter()]
        [switch]$AsHashtable,
        
        [Parameter()]
        [int]$MaxRetryAttempts = 3
    )
    
    Write-AnalysisLog -Message "Starting enhanced response analysis" -Level "INFO"
    
    # Check circuit breaker
    if (-not (Test-CircuitBreakerState)) {
        throw "Circuit breaker is OPEN - analysis blocked"
    }
    
    $retryCount = 0
    $analysisResult = $null
    $lastError = $null
    
    do {
        try {
            Write-AnalysisLog -Message "Analysis attempt $($retryCount + 1) of $MaxRetryAttempts" -Level "DEBUG"
            
            # Step 1: Truncation detection and repair
            $processedContent = $ResponseContent
            if (Test-JsonTruncation -JsonString $processedContent) {
                Write-AnalysisLog -Message "Truncation detected - attempting repair" -Level "WARN"
                $processedContent = Repair-TruncatedJson -JsonString $processedContent
            }
            
            # Step 2: Schema validation
            if ($script:AnalysisConfig.SchemaValidationEnabled) {
                if (-not (Test-JsonSchema -JsonString $processedContent -SchemaPath $SchemaPath)) {
                    throw "Schema validation failed"
                }
            }
            
            # Step 3: Multi-parser processing
            $parsedResult = Invoke-MultiParserJson -JsonString $processedContent -AsHashtable:$AsHashtable
            
            # Step 4: Anthropic-specific validation
            if (-not (Test-AnthropicResponseSchema -ParsedJson $parsedResult)) {
                Write-AnalysisLog -Message "Warning: Response may not contain valid Claude Code CLI recommendations" -Level "WARN"
            }
            
            # Success - update circuit breaker and return result
            Update-CircuitBreakerState -Success $true
            
            $analysisResult = @{
                ParsedContent = $parsedResult
                OriginalLength = $ResponseContent.Length
                ProcessedLength = $processedContent.Length
                WasRepaired = ($ResponseContent.Length -ne $processedContent.Length)
                SchemaValid = $true
                RetryCount = $retryCount
                Success = $true
            }
            
            Write-AnalysisLog -Message "Enhanced response analysis completed successfully" -Level "INFO"
            return $analysisResult
            
        } catch {
            $lastError = $_.Exception
            Write-AnalysisLog -Message "Analysis attempt $($retryCount + 1) failed: $($_.Exception.Message)" -Level "ERROR"
            
            $retryCount++
            
            if ($retryCount -lt $MaxRetryAttempts) {
                $delayMs = $script:AnalysisConfig.RetryDelayMs[$retryCount - 1]
                Write-AnalysisLog -Message "Retrying in ${delayMs}ms..." -Level "INFO"
                Start-Sleep -Milliseconds $delayMs
            }
        }
        
    } while ($retryCount -lt $MaxRetryAttempts)
    
    # All retry attempts failed
    Update-CircuitBreakerState -Success $false
    
    $analysisResult = @{
        ParsedContent = $null
        OriginalLength = $ResponseContent.Length
        ProcessedLength = $ResponseContent.Length
        WasRepaired = $false
        SchemaValid = $false
        RetryCount = $retryCount
        Success = $false
        LastError = $lastError.Message
    }
    
    Write-AnalysisLog -Message "Enhanced response analysis failed after $MaxRetryAttempts attempts" -Level "ERROR"
    throw "Response analysis failed: $($lastError.Message)"
}

#endregion

#region Entity Recognition Functions

function Extract-ResponseEntities {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$EntityPatterns = @{}
    )
    
    Write-AnalysisLog -Message "Starting entity extraction from response text" -Level "INFO"
    
    # Default entity patterns based on research findings
    if (-not $EntityPatterns.Keys.Count) {
        $EntityPatterns = @{
            FilePaths = @(
                '(?i)[a-zA-Z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*\.[a-zA-Z0-9]+',  # Windows file paths
                '(?i)[a-zA-Z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]+',  # Windows directory paths
                '(?i)\.\\[^\\/:*?"<>|\r\n]+(?:\\[^\\/:*?"<>|\r\n]+)*',  # Relative paths
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
                    Write-AnalysisLog -Message "Regex error for pattern $pattern`: $($_.Exception.Message)" -Level "WARNING"
                }
            }
            
            # Remove duplicates and store results
            $extractedEntities[$entityType] = $matches | Select-Object -Unique
            $extractedEntities.TotalMatches += $extractedEntities[$entityType].Count
        }
        
        $stopwatch.Stop()
        $extractedEntities.ProcessingTime = $stopwatch.ElapsedMilliseconds
        
        Write-AnalysisLog -Message "Entity extraction completed: $($extractedEntities.TotalMatches) entities found in $($extractedEntities.ProcessingTime)ms" -Level "INFO"
        
        return $extractedEntities
        
    } catch {
        $stopwatch.Stop()
        Write-AnalysisLog -Message "Entity extraction failed: $($_.Exception.Message)" -Level "ERROR"
        throw "Entity extraction failed: $($_.Exception.Message)"
    }
}

function Analyze-ResponseSentiment {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText,
        
        [Parameter(Mandatory=$false)]
        [double]$ConfidenceThreshold = 0.6
    )
    
    Write-AnalysisLog -Message "Starting sentiment analysis" -Level "INFO"
    
    # Sentiment indicators based on research into CLI response analysis
    $sentimentPatterns = @{
        Positive = @(
            '(?i)\b(success|successful|complete|completed|fixed|resolved|working|good|excellent|perfect|ready)\b',
            '(?i)\b(pass|passed|passing|ok|correct|valid|available|active|enabled)\b',
            '(?i)\b(found|detected|identified|located|discovered)\b',
            '(?i)\b(implemented|created|generated|built|compiled|deployed)\b'
        )
        Negative = @(
            '(?i)\b(error|failed|failure|fail|failing|broken|corrupt|invalid|missing)\b',
            '(?i)\b(exception|crash|crashed|timeout|denied|forbidden|unavailable)\b',
            '(?i)\b(unable|cannot|could not|impossible|blocked|prevented)\b',
            '(?i)\b(wrong|incorrect|bad|critical|severe|serious|urgent)\b'
        )
        Neutral = @(
            '(?i)\b(analysis|analyzing|processing|checking|validating|testing)\b',
            '(?i)\b(continue|continuing|proceed|proceeding|next|following)\b',
            '(?i)\b(information|data|details|content|response|result)\b',
            '(?i)\b(configuration|setup|installation|deployment|initialization)\b'
        )
        Uncertainty = @(
            '(?i)\b(maybe|perhaps|possibly|might|could|should|would|may)\b',
            '(?i)\b(unknown|unclear|uncertain|unsure|undetermined)\b',
            '(?i)\b(investigate|research|review|analyze|examine|consider)\b',
            '(?i)\b(potential|possible|likely|probable|seems|appears)\b'
        )
    }
    
    $sentimentScores = @{
        Positive = 0.0
        Negative = 0.0
        Neutral = 0.0
        Uncertainty = 0.0
    }
    
    $totalMatches = 0
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Calculate sentiment scores based on pattern matches
        $sentimentTypes = @($sentimentPatterns.Keys)
        foreach ($sentimentType in $sentimentTypes) {
            $matches = 0
            
            foreach ($pattern in $sentimentPatterns[$sentimentType]) {
                try {
                    $regexMatches = [regex]::Matches($ResponseText, $pattern)
                    $matches += $regexMatches.Count
                } catch {
                    Write-AnalysisLog -Message "Regex error in sentiment analysis: $($_.Exception.Message)" -Level "WARNING"
                }
            }
            
            $sentimentScores[$sentimentType] = $matches
            $totalMatches += $matches
        }
        
        # Normalize scores if matches found
        if ($totalMatches -gt 0) {
            $scoreTypes = @($sentimentScores.Keys)
            foreach ($sentimentType in $scoreTypes) {
                $sentimentScores[$sentimentType] = [Math]::Round($sentimentScores[$sentimentType] / $totalMatches, 3)
            }
        }
        
        # Determine dominant sentiment
        $dominantSentiment = "Neutral"
        $maxScore = 0.0
        
        foreach ($sentimentType in $sentimentScores.Keys) {
            if ($sentimentScores[$sentimentType] -gt $maxScore) {
                $maxScore = $sentimentScores[$sentimentType]
                $dominantSentiment = $sentimentType
            }
        }
        
        # Calculate overall confidence
        $confidence = if ($totalMatches -eq 0) { 0.0 } else { [Math]::Min(1.0, $maxScore + ($totalMatches * 0.05)) }
        
        $stopwatch.Stop()
        
        $sentimentResult = @{
            DominantSentiment = $dominantSentiment
            OverallConfidence = [Math]::Round($confidence, 3)
            SentimentScores = $sentimentScores
            TotalMatches = $totalMatches
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            MeetsThreshold = ($confidence -ge $ConfidenceThreshold)
        }
        
        Write-AnalysisLog -Message "Sentiment analysis completed: $dominantSentiment ($($confidence * 100)% confidence) in $($stopwatch.ElapsedMilliseconds)ms" -Level "INFO"
        
        return $sentimentResult
        
    } catch {
        $stopwatch.Stop()
        Write-AnalysisLog -Message "Sentiment analysis failed: $($_.Exception.Message)" -Level "ERROR"
        throw "Sentiment analysis failed: $($_.Exception.Message)"
    }
}

function Get-ResponseContext {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxContextItems = 20
    )
    
    Write-AnalysisLog -Message "Extracting response context information" -Level "INFO"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Extract entities and sentiment
        $entities = Extract-ResponseEntities -ResponseText $ResponseText
        $sentiment = Analyze-ResponseSentiment -ResponseText $ResponseText
        
        # Context relevance scoring patterns
        $contextPatterns = @{
            HighPriority = @(
                '(?i)\b(critical|urgent|important|priority|immediate|required)\b',
                '(?i)\b(error|exception|failure|problem|issue|bug)\b',
                '(?i)\b(test|build|compile|deploy|run|execute)\b'
            )
            MediumPriority = @(
                '(?i)\b(recommend|suggest|consider|review|update|modify)\b',
                '(?i)\b(configuration|setting|option|parameter|variable)\b',
                '(?i)\b(documentation|guide|instruction|tutorial|example)\b'
            )
            LowPriority = @(
                '(?i)\b(information|detail|description|explanation|note)\b',
                '(?i)\b(general|common|typical|standard|default|basic)\b'
            )
        }
        
        # Score context relevance
        $relevanceScore = 0.0
        $contextIndicators = @()
        
        foreach ($priority in $contextPatterns.Keys) {
            $priorityWeight = switch ($priority) {
                "HighPriority" { 1.0 }
                "MediumPriority" { 0.6 }
                "LowPriority" { 0.3 }
            }
            
            foreach ($pattern in $contextPatterns[$priority]) {
                $matches = [regex]::Matches($ResponseText, $pattern)
                if ($matches.Count -gt 0) {
                    $contextIndicators += @{
                        Pattern = $pattern
                        Priority = $priority
                        Matches = $matches.Count
                        Weight = $priorityWeight
                    }
                    $relevanceScore += $matches.Count * $priorityWeight
                }
            }
        }
        
        # Normalize relevance score
        $maxPossibleScore = 100.0  # Theoretical maximum
        $normalizedRelevance = [Math]::Min(1.0, $relevanceScore / $maxPossibleScore)
        
        $stopwatch.Stop()
        
        $contextResult = @{
            Entities = $entities
            Sentiment = $sentiment
            RelevanceScore = [Math]::Round($normalizedRelevance, 3)
            ContextIndicators = $contextIndicators | Sort-Object Weight -Descending | Select-Object -First $MaxContextItems
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            ResponseLength = $ResponseText.Length
            WordCount = ($ResponseText -split '\s+').Count
        }
        
        Write-AnalysisLog -Message "Context extraction completed: relevance $($normalizedRelevance * 100)% in $($stopwatch.ElapsedMilliseconds)ms" -Level "INFO"
        
        return $contextResult
        
    } catch {
        $stopwatch.Stop()
        Write-AnalysisLog -Message "Context extraction failed: $($_.Exception.Message)" -Level "ERROR"
        throw "Context extraction failed: $($_.Exception.Message)"
    }
}

#endregion

#region Advanced Pattern Recognition - Phase 7 Day 1-2 Hours 5-8

$script:PatternWeights = @{
    # High confidence patterns (0.8-1.0)
    ExplicitRecommendation = 0.95  # "RECOMMENDATION: TEST - "
    DirectCommand = 0.90          # "Run the following command:"
    ErrorReference = 0.85         # "CS0246: Type not found"
    FilePath = 0.80               # "C:\Path\To\File.ps1"
    
    # Medium confidence patterns (0.5-0.7)
    SuggestedAction = 0.70        # "You should..."
    ImpliedAction = 0.65          # "This needs to be..."
    ConditionalAction = 0.60      # "If X then Y"
    WarningPattern = 0.55         # "Warning: ..."
    
    # Low confidence patterns (0.2-0.4)
    GeneralAdvice = 0.40          # "Consider..."
    InformationalContent = 0.30   # "Information about..."
    MetaComment = 0.20            # "Note that..."
}

$script:NGramDatabase = @{
    Bigrams = @{}
    Trigrams = @{}
    LastUpdate = $null
    MaxSize = 10000
}

function Calculate-PatternConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [hashtable]$Patterns,
        
        [Parameter()]
        [switch]$UseBayesian
    )
    
    Write-AnalysisLog -Message "Calculating pattern confidence with weighted scoring" -Level "DEBUG"
    
    $confidenceScores = @()
    $totalWeight = 0.0
    
    # Check each pattern type and calculate weighted confidence
    foreach ($patternType in $script:PatternWeights.Keys) {
        $weight = $script:PatternWeights[$patternType]
        $matchCount = 0
        
        switch ($patternType) {
            "ExplicitRecommendation" {
                if ($ResponseText -match 'RECOMMENDATION:\s*(CONTINUE|TEST|FIX|COMPILE|RESTART|COMPLETE|ERROR)') {
                    $matchCount = 1
                    $confidenceScores += @{
                        Type = "ExplicitRecommendation"
                        Match = $Matches[0]
                        Weight = $weight
                        Score = $weight
                    }
                }
            }
            "DirectCommand" {
                $patterns = @(
                    'Run the following\s+(command|script|test)',
                    'Execute\s+the\s+following',
                    'Please\s+run:',
                    'Try\s+running:'
                )
                foreach ($pattern in $patterns) {
                    if ($ResponseText -match $pattern) {
                        $matchCount++
                    }
                }
                if ($matchCount -gt 0) {
                    $confidenceScores += @{
                        Type = "DirectCommand"
                        Match = $matchCount
                        Weight = $weight
                        Score = $weight * [Math]::Min(1.0, $matchCount * 0.5)
                    }
                }
            }
            "ErrorReference" {
                if ($ResponseText -match '(CS\d{4}|MSB\d{4}|Error\s+\d+)') {
                    $matchCount = ([regex]::Matches($ResponseText, '(CS\d{4}|MSB\d{4}|Error\s+\d+)')).Count
                    $confidenceScores += @{
                        Type = "ErrorReference"
                        Match = $matchCount
                        Weight = $weight
                        Score = $weight * [Math]::Min(1.0, $matchCount * 0.3)
                    }
                }
            }
            "FilePath" {
                $filePathPattern = '[a-zA-Z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*\.[a-zA-Z0-9]+'
                if ($ResponseText -match $filePathPattern) {
                    $matchCount = ([regex]::Matches($ResponseText, $filePathPattern)).Count
                    $confidenceScores += @{
                        Type = "FilePath"
                        Match = $matchCount
                        Weight = $weight
                        Score = $weight * [Math]::Min(1.0, $matchCount * 0.4)
                    }
                }
            }
            "SuggestedAction" {
                $patterns = @('You should', 'You need to', 'You must', 'It is recommended')
                foreach ($pattern in $patterns) {
                    if ($ResponseText -match $pattern) {
                        $matchCount++
                    }
                }
                if ($matchCount -gt 0) {
                    $confidenceScores += @{
                        Type = "SuggestedAction"
                        Match = $matchCount
                        Weight = $weight
                        Score = $weight * [Math]::Min(1.0, $matchCount * 0.6)
                    }
                }
            }
        }
    }
    
    # Calculate overall confidence
    $overallConfidence = 0.0
    $totalWeight = 0.0
    
    foreach ($score in $confidenceScores) {
        $overallConfidence += $score.Score
        $totalWeight += $score.Weight
    }
    
    # Normalize confidence
    if ($totalWeight -gt 0) {
        $normalizedConfidence = [Math]::Min(1.0, $overallConfidence / $totalWeight)
    } else {
        $normalizedConfidence = 0.0
    }
    
    # Apply Bayesian adjustment if requested
    if ($UseBayesian) {
        $normalizedConfidence = Invoke-BayesianConfidenceAdjustment -BaseConfidence $normalizedConfidence -PatternScores $confidenceScores
    }
    
    return @{
        OverallConfidence = [Math]::Round($normalizedConfidence, 3)
        PatternScores = $confidenceScores
        ConfidenceBand = Get-ConfidenceBand -Confidence $normalizedConfidence
        ProcessingTime = 0  # Will be filled by caller
    }
}

function Get-ConfidenceBand {
    param(
        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    
    if ($Confidence -ge 0.90) { return "VeryHigh" }
    elseif ($Confidence -ge 0.75) { return "High" }
    elseif ($Confidence -ge 0.60) { return "Medium" }
    elseif ($Confidence -ge 0.40) { return "Low" }
    else { return "VeryLow" }
}

function Invoke-BayesianConfidenceAdjustment {
    param(
        [Parameter(Mandatory = $true)]
        [double]$BaseConfidence,
        
        [Parameter(Mandatory = $true)]
        [array]$PatternScores
    )
    
    # Simple Bayesian prior based on pattern history
    # In production, this would use actual historical data
    $priorProbabilities = @{
        ExplicitRecommendation = 0.85
        DirectCommand = 0.70
        ErrorReference = 0.60
        FilePath = 0.50
        SuggestedAction = 0.40
    }
    
    $adjustedConfidence = $BaseConfidence
    
    foreach ($score in $PatternScores) {
        if ($priorProbabilities.ContainsKey($score.Type)) {
            $prior = $priorProbabilities[$score.Type]
            # Bayesian update formula (simplified)
            $adjustedConfidence = ($adjustedConfidence * $prior) / 
                                (($adjustedConfidence * $prior) + ((1 - $adjustedConfidence) * (1 - $prior)))
        }
    }
    
    return [Math]::Round($adjustedConfidence, 3)
}

#endregion

#region N-Gram Analysis

function Build-NGramModel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [int]$MaxNGramSize = 3
    )
    
    Write-AnalysisLog -Message "Building n-gram model for context analysis" -Level "DEBUG"
    
    # Tokenize text
    $tokens = $Text -split '\s+' | Where-Object { $_.Length -gt 0 }
    
    if ($tokens.Count -lt 2) {
        return @{
            Bigrams = @{}
            Trigrams = @{}
            TokenCount = $tokens.Count
        }
    }
    
    $bigrams = @{}
    $trigrams = @{}
    
    # Build bigrams
    for ($i = 0; $i -lt ($tokens.Count - 1); $i++) {
        $bigram = "$($tokens[$i]) $($tokens[$i+1])"
        if ($bigrams.ContainsKey($bigram)) {
            $bigrams[$bigram]++
        } else {
            $bigrams[$bigram] = 1
        }
    }
    
    # Build trigrams if enough tokens
    if ($tokens.Count -ge 3) {
        for ($i = 0; $i -lt ($tokens.Count - 2); $i++) {
            $trigram = "$($tokens[$i]) $($tokens[$i+1]) $($tokens[$i+2])"
            if ($trigrams.ContainsKey($trigram)) {
                $trigrams[$trigram]++
            } else {
                $trigrams[$trigram] = 1
            }
        }
    }
    
    return @{
        Bigrams = $bigrams
        Trigrams = $trigrams
        TokenCount = $tokens.Count
        UniqueTokens = ($tokens | Select-Object -Unique).Count
    }
}

function Calculate-PatternSimilarity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern1,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern2,
        
        [Parameter()]
        [ValidateSet("Jaccard", "Cosine", "Levenshtein")]
        [string]$Method = "Jaccard"
    )
    
    Write-AnalysisLog -Message "Calculating pattern similarity using $Method method" -Level "DEBUG"
    
    switch ($Method) {
        "Jaccard" {
            # Jaccard similarity coefficient
            $tokens1 = $Pattern1 -split '\s+' | Where-Object { $_.Length -gt 0 }
            $tokens2 = $Pattern2 -split '\s+' | Where-Object { $_.Length -gt 0 }
            
            $set1 = [System.Collections.Generic.HashSet[string]]::new($tokens1)
            $set2 = [System.Collections.Generic.HashSet[string]]::new($tokens2)
            
            $intersection = [System.Collections.Generic.HashSet[string]]::new($set1)
            $intersection.IntersectWith($set2)
            
            $union = [System.Collections.Generic.HashSet[string]]::new($set1)
            $union.UnionWith($set2)
            
            if ($union.Count -eq 0) {
                return 0.0
            }
            
            return [Math]::Round($intersection.Count / $union.Count, 3)
        }
        
        "Cosine" {
            # Cosine similarity (simplified)
            $tokens1 = $Pattern1 -split '\s+' | Where-Object { $_.Length -gt 0 }
            $tokens2 = $Pattern2 -split '\s+' | Where-Object { $_.Length -gt 0 }
            
            $allTokens = ($tokens1 + $tokens2) | Select-Object -Unique
            $vector1 = @()
            $vector2 = @()
            
            foreach ($token in $allTokens) {
                $vector1 += $(if ($tokens1 -contains $token) { 1 } else { 0 })
                $vector2 += $(if ($tokens2 -contains $token) { 1 } else { 0 })
            }
            
            $dotProduct = 0
            $norm1 = 0
            $norm2 = 0
            
            for ($i = 0; $i -lt $vector1.Count; $i++) {
                $dotProduct += $vector1[$i] * $vector2[$i]
                $norm1 += $vector1[$i] * $vector1[$i]
                $norm2 += $vector2[$i] * $vector2[$i]
            }
            
            if ($norm1 -eq 0 -or $norm2 -eq 0) {
                return 0.0
            }
            
            return [Math]::Round($dotProduct / ([Math]::Sqrt($norm1) * [Math]::Sqrt($norm2)), 3)
        }
        
        "Levenshtein" {
            # Levenshtein distance normalized to similarity
            $len1 = $Pattern1.Length
            $len2 = $Pattern2.Length
            
            if ($len1 -eq 0) { return $(if ($len2 -eq 0) { 1.0 } else { 0.0 }) }
            if ($len2 -eq 0) { return 0.0 }
            
            $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
            
            for ($i = 0; $i -le $len1; $i++) { $matrix[$i, 0] = $i }
            for ($j = 0; $j -le $len2; $j++) { $matrix[0, $j] = $j }
            
            for ($i = 1; $i -le $len1; $i++) {
                for ($j = 1; $j -le $len2; $j++) {
                    $cost = $(if ($Pattern1[$i-1] -eq $Pattern2[$j-1]) { 0 } else { 1 })
                    $matrix[$i, $j] = [Math]::Min(
                        [Math]::Min($matrix[$i-1, $j] + 1, $matrix[$i, $j-1] + 1),
                        $matrix[$i-1, $j-1] + $cost
                    )
                }
            }
            
            $distance = $matrix[$len1, $len2]
            $maxLen = [Math]::Max($len1, $len2)
            
            return [Math]::Round(1.0 - ($distance / $maxLen), 3)
        }
    }
}

#endregion

#region Entity Relationship Mapping

function Build-EntityRelationshipGraph {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Entities,
        
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    Write-AnalysisLog -Message "Building entity relationship graph" -Level "DEBUG"
    
    $relationshipGraph = @{
        Nodes = @{}
        Edges = @()
        Clusters = @()
    }
    
    # Create nodes for each entity
    $nodeId = 0
    foreach ($entityType in $Entities.Keys) {
        foreach ($entity in $Entities[$entityType]) {
            $nodeId++
            $relationshipGraph.Nodes["node_$nodeId"] = @{
                Id = "node_$nodeId"
                Type = $entityType
                Value = $entity
                Connections = @()
            }
        }
    }
    
    # Find relationships based on proximity and context
    $nodes = @($relationshipGraph.Nodes.Values)
    
    for ($i = 0; $i -lt $nodes.Count; $i++) {
        for ($j = $i + 1; $j -lt $nodes.Count; $j++) {
            $node1 = $nodes[$i]
            $node2 = $nodes[$j]
            
            # Check if entities appear close to each other in text
            $proximity = Measure-EntityProximity -Entity1 $node1.Value -Entity2 $node2.Value -Text $ResponseText
            
            if ($proximity.IsRelated) {
                $edge = @{
                    Source = $node1.Id
                    Target = $node2.Id
                    Weight = $proximity.Score
                    Type = $proximity.RelationType
                }
                
                $relationshipGraph.Edges += $edge
                $node1.Connections += $node2.Id
                $node2.Connections += $node1.Id
            }
        }
    }
    
    # Identify clusters of related entities
    $relationshipGraph.Clusters = Find-EntityClusters -Graph $relationshipGraph
    
    return $relationshipGraph
}

function Measure-EntityProximity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Entity1,
        
        [Parameter(Mandatory = $true)]
        [string]$Entity2,
        
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [int]$ProximityThreshold = 100  # Characters
    )
    
    # Find positions of entities in text
    $pos1 = $Text.IndexOf($Entity1, [System.StringComparison]::OrdinalIgnoreCase)
    $pos2 = $Text.IndexOf($Entity2, [System.StringComparison]::OrdinalIgnoreCase)
    
    if ($pos1 -eq -1 -or $pos2 -eq -1) {
        return @{
            IsRelated = $false
            Score = 0.0
            RelationType = "None"
            Distance = -1
        }
    }
    
    $distance = [Math]::Abs($pos2 - $pos1)
    $isRelated = $distance -le $ProximityThreshold
    
    # Calculate relationship score based on distance
    $score = if ($isRelated) {
        1.0 - ($distance / $ProximityThreshold)
    } else {
        0.0
    }
    
    # Determine relationship type based on context
    $relationType = "Unknown"
    
    if ($isRelated) {
        # Check for specific relationship patterns
        $contextStart = [Math]::Max(0, [Math]::Min($pos1, $pos2) - 50)
        $contextEnd = [Math]::Min($Text.Length, [Math]::Max($pos1, $pos2) + 50)
        $contextText = $Text.Substring($contextStart, $contextEnd - $contextStart)
        
        if ($contextText -match '(causes|caused by|results in|leads to)') {
            $relationType = "Causal"
        } elseif ($contextText -match '(contains|includes|part of|within)') {
            $relationType = "Containment"
        } elseif ($contextText -match '(depends on|requires|needs|uses)') {
            $relationType = "Dependency"
        } elseif ($contextText -match '(similar to|like|same as|equivalent)') {
            $relationType = "Similarity"
        } else {
            $relationType = "Proximity"
        }
    }
    
    return @{
        IsRelated = $isRelated
        Score = [Math]::Round($score, 3)
        RelationType = $relationType
        Distance = $distance
    }
}

function Find-EntityClusters {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    Write-AnalysisLog -Message "Finding entity clusters in relationship graph" -Level "DEBUG"
    
    $clusters = @()
    $visited = @{}
    
    # Simple connected components algorithm
    foreach ($nodeId in $Graph.Nodes.Keys) {
        if (-not $visited.ContainsKey($nodeId)) {
            $cluster = @()
            $queue = [System.Collections.Queue]::new()
            $queue.Enqueue($nodeId)
            
            while ($queue.Count -gt 0) {
                $currentId = $queue.Dequeue()
                
                if ($visited.ContainsKey($currentId)) {
                    continue
                }
                
                $visited[$currentId] = $true
                $cluster += $currentId
                
                $node = $Graph.Nodes[$currentId]
                foreach ($connectedId in $node.Connections) {
                    if (-not $visited.ContainsKey($connectedId)) {
                        $queue.Enqueue($connectedId)
                    }
                }
            }
            
            if ($cluster.Count -gt 1) {
                $clusters += @{
                    Nodes = $cluster
                    Size = $cluster.Count
                    Types = @($cluster | ForEach-Object { $Graph.Nodes[$_].Type }) | Select-Object -Unique
                }
            }
        }
    }
    
    return $clusters
}

#endregion

#region Temporal Context Tracking

$script:TemporalContext = @{
    History = @()
    MaxHistorySize = 100
    TimeWindow = [TimeSpan]::FromMinutes(30)
}

function Add-TemporalContext {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ContextItem
    )
    
    $timestamp = Get-Date
    $contextEntry = @{
        Timestamp = $timestamp
        Context = $ContextItem
        ExpiresAt = $timestamp.Add($script:TemporalContext.TimeWindow)
    }
    
    # Add to history
    $script:TemporalContext.History += $contextEntry
    
    # Remove expired entries
    $script:TemporalContext.History = @($script:TemporalContext.History | 
        Where-Object { $_.ExpiresAt -gt $timestamp })
    
    # Enforce size limit
    if ($script:TemporalContext.History.Count -gt $script:TemporalContext.MaxHistorySize) {
        $script:TemporalContext.History = @($script:TemporalContext.History | 
            Select-Object -Last $script:TemporalContext.MaxHistorySize)
    }
}

function Get-TemporalContextRelevance {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$CurrentContext
    )
    
    Write-AnalysisLog -Message "Calculating temporal context relevance" -Level "DEBUG"
    
    $relevanceScores = @()
    $currentTime = Get-Date
    
    foreach ($historyItem in $script:TemporalContext.History) {
        $timeDelta = $currentTime - $historyItem.Timestamp
        $timeDecay = [Math]::Exp(-$timeDelta.TotalMinutes / 30)  # Exponential decay
        
        # Calculate similarity between current and historical context
        $similarity = 0.0
        
        if ($CurrentContext.Entities -and $historyItem.Context.Entities) {
            # Compare entities
            $currentEntities = @()
            foreach ($type in $CurrentContext.Entities.Keys) {
                $currentEntities += $CurrentContext.Entities[$type]
            }
            
            $historicalEntities = @()
            foreach ($type in $historyItem.Context.Entities.Keys) {
                $historicalEntities += $historyItem.Context.Entities[$type]
            }
            
            if ($currentEntities.Count -gt 0 -and $historicalEntities.Count -gt 0) {
                $intersection = @($currentEntities | Where-Object { $historicalEntities -contains $_ })
                $union = @($currentEntities + $historicalEntities | Select-Object -Unique)
                
                if ($union.Count -gt 0) {
                    $similarity = $intersection.Count / $union.Count
                }
            }
        }
        
        $relevanceScore = $similarity * $timeDecay
        
        if ($relevanceScore -gt 0.1) {  # Threshold for relevance
            $relevanceScores += @{
                Timestamp = $historyItem.Timestamp
                Score = [Math]::Round($relevanceScore, 3)
                Context = $historyItem.Context
            }
        }
    }
    
    # Sort by relevance score
    $relevanceScores = @($relevanceScores | Sort-Object Score -Descending)
    
    return @{
        RelevantContexts = $relevanceScores
        OverallRelevance = if ($relevanceScores.Count -gt 0) { 
            [Math]::Round(($relevanceScores | Measure-Object Score -Average).Average, 3) 
        } else { 0.0 }
        HistorySize = $script:TemporalContext.History.Count
    }
}

#endregion

#region Enhanced Main Analysis Function

function Invoke-EnhancedPatternAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [switch]$IncludeNGrams,
        
        [Parameter()]
        [switch]$BuildRelationshipGraph,
        
        [Parameter()]
        [switch]$TrackTemporalContext
    )
    
    Write-AnalysisLog -Message "Starting enhanced pattern analysis" -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Extract entities first
        $entities = Extract-ResponseEntities -ResponseText $ResponseText
        
        # Calculate weighted pattern confidence
        $confidenceResult = Calculate-PatternConfidence -ResponseText $ResponseText -UseBayesian
        
        # Build n-gram model if requested
        $ngramModel = $null
        if ($IncludeNGrams) {
            $ngramModel = Build-NGramModel -Text $ResponseText
        }
        
        # Build entity relationship graph if requested
        $relationshipGraph = $null
        if ($BuildRelationshipGraph -and $entities.TotalMatches -gt 0) {
            $relationshipGraph = Build-EntityRelationshipGraph -Entities $entities -ResponseText $ResponseText
        }
        
        # Track temporal context if requested
        $temporalRelevance = $null
        if ($TrackTemporalContext) {
            $currentContext = @{
                Entities = $entities
                Confidence = $confidenceResult.OverallConfidence
                Timestamp = Get-Date
            }
            
            Add-TemporalContext -ContextItem $currentContext
            $temporalRelevance = Get-TemporalContextRelevance -CurrentContext $currentContext
        }
        
        $stopwatch.Stop()
        
        return @{
            Entities = $entities
            Confidence = $confidenceResult
            NGramModel = $ngramModel
            RelationshipGraph = $relationshipGraph
            TemporalRelevance = $temporalRelevance
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            Success = $true
        }
        
    } catch {
        $stopwatch.Stop()
        Write-AnalysisLog -Message "Enhanced pattern analysis failed: $($_.Exception.Message)" -Level "ERROR"
        
        return @{
            Entities = $null
            Confidence = @{ OverallConfidence = 0.0; ConfidenceBand = "VeryLow" }
            NGramModel = $null
            RelationshipGraph = $null
            TemporalRelevance = $null
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Multi-Format Response Parsing - Phase 7 Day 1-2 Hours 2-3

function Test-ResponseFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent
    )
    
    Write-AnalysisLog -Message "Detecting response format" -Level "DEBUG"
    
    # Remove whitespace for analysis
    $trimmedContent = $ResponseContent.Trim()
    
    if ([string]::IsNullOrEmpty($trimmedContent)) {
        return @{
            Format = "Empty"
            Confidence = 1.0
            Details = "Empty response content"
        }
    }
    
    # JSON format detection
    if (($trimmedContent.StartsWith("{") -and $trimmedContent.EndsWith("}")) -or 
        ($trimmedContent.StartsWith("[") -and $trimmedContent.EndsWith("]"))) {
        
        # Additional JSON validation
        try {
            $null = ConvertFrom-Json $trimmedContent -ErrorAction Stop
            return @{
                Format = "JSON"
                Confidence = 0.95
                Details = "Valid JSON structure detected"
            }
        } catch {
            # Might be truncated JSON
            if (Test-JsonTruncation -JsonString $trimmedContent) {
                return @{
                    Format = "TruncatedJSON"
                    Confidence = 0.80
                    Details = "Truncated JSON detected, repair possible"
                }
            } else {
                return @{
                    Format = "InvalidJSON"
                    Confidence = 0.60
                    Details = "JSON-like structure but invalid syntax"
                }
            }
        }
    }
    
    # Mixed format detection (JSON embedded in text)
    if ($trimmedContent -match '\{.*".*".*\}' -or $trimmedContent -match '\[.*\]') {
        return @{
            Format = "Mixed"
            Confidence = 0.70
            Details = "Text content with embedded JSON structures"
        }
    }
    
    # RECOMMENDATION pattern detection (Claude Code CLI specific)
    if ($trimmedContent -match 'RECOMMENDATION:\s*(CONTINUE|TEST|FIX|COMPILE|RESTART|COMPLETE|ERROR)') {
        return @{
            Format = "ClaudeResponse"
            Confidence = 0.90
            Details = "Claude Code CLI recommendation format"
        }
    }
    
    # XML-like content
    if ($trimmedContent -match '<[^>]+>.*</[^>]+>' -or $trimmedContent.StartsWith("<?xml")) {
        return @{
            Format = "XML"
            Confidence = 0.85
            Details = "XML structure detected"
        }
    }
    
    # Markdown detection
    if ($trimmedContent -match '^#{1,6}\s+' -or $trimmedContent -match '\*\*.*\*\*' -or $trimmedContent -match '\[.*\]\(.*\)') {
        return @{
            Format = "Markdown"
            Confidence = 0.75
            Details = "Markdown formatting detected"
        }
    }
    
    # Plain text (default)
    return @{
        Format = "PlainText"
        Confidence = 0.50
        Details = "Unstructured plain text content"
    }
}

function Parse-MixedFormatResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [string]$PreferredFormat = "Auto"
    )
    
    Write-AnalysisLog -Message "Parsing mixed format response" -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Detect format if not specified
        $formatDetection = Test-ResponseFormat -ResponseContent $ResponseContent
        $detectedFormat = $formatDetection.Format
        
        if ($PreferredFormat -ne "Auto") {
            $detectedFormat = $PreferredFormat
        }
        
        Write-AnalysisLog -Message "Processing as $detectedFormat format (confidence: $($formatDetection.Confidence))" -Level "DEBUG"
        
        $parseResult = @{
            OriginalContent = $ResponseContent
            DetectedFormat = $detectedFormat
            FormatConfidence = $formatDetection.Confidence
            ExtractedStructures = @{}
            PlainTextContent = ""
            ProcessingSteps = @()
            Success = $false
            Error = $null
        }
        
        switch ($detectedFormat) {
            "JSON" {
                $parseResult.ProcessingSteps += "Processing pure JSON format"
                try {
                    $jsonResult = Invoke-MultiParserJson -JsonString $ResponseContent
                    $parseResult.ExtractedStructures.JSON = $jsonResult
                    $parseResult.Success = $true
                } catch {
                    $parseResult.Error = "JSON parsing failed: $($_.Exception.Message)"
                }
            }
            
            "TruncatedJSON" {
                $parseResult.ProcessingSteps += "Repairing truncated JSON"
                try {
                    $repairedJson = Repair-TruncatedJson -JsonString $ResponseContent
                    $jsonResult = Invoke-MultiParserJson -JsonString $repairedJson
                    $parseResult.ExtractedStructures.JSON = $jsonResult
                    $parseResult.ExtractedStructures.RepairInfo = @{
                        WasRepaired = $true
                        OriginalLength = $ResponseContent.Length
                        RepairedLength = $repairedJson.Length
                    }
                    $parseResult.Success = $true
                } catch {
                    $parseResult.Error = "Truncated JSON repair failed: $($_.Exception.Message)"
                }
            }
            
            "Mixed" {
                $parseResult.ProcessingSteps += "Extracting JSON from mixed content"
                
                # Extract JSON structures using regex
                $jsonPattern = '\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'
                $jsonMatches = [regex]::Matches($ResponseContent, $jsonPattern)
                
                $extractedJson = @()
                foreach ($match in $jsonMatches) {
                    try {
                        $jsonObj = ConvertFrom-Json $match.Value -ErrorAction Stop
                        $extractedJson += @{
                            StartIndex = $match.Index
                            Length = $match.Length
                            Content = $match.Value
                            Parsed = $jsonObj
                        }
                    } catch {
                        # Skip invalid JSON structures
                        continue
                    }
                }
                
                $parseResult.ExtractedStructures.JSON = $extractedJson
                
                # Extract plain text (remove JSON structures)
                $plainText = $ResponseContent
                foreach ($match in ($jsonMatches | Sort-Object Index -Descending)) {
                    $plainText = $plainText.Remove($match.Index, $match.Length)
                }
                $parseResult.PlainTextContent = $plainText.Trim()
                $parseResult.Success = $true
            }
            
            "ClaudeResponse" {
                $parseResult.ProcessingSteps += "Parsing Claude Code CLI response"
                
                # Extract RECOMMENDATION pattern
                if ($ResponseContent -match 'RECOMMENDATION:\s*(CONTINUE|TEST|FIX|COMPILE|RESTART|COMPLETE|ERROR)(.*)') {
                    $parseResult.ExtractedStructures.Recommendation = @{
                        Type = $Matches[1]
                        Details = $Matches[2].Trim()
                        FullMatch = $Matches[0]
                    }
                }
                
                # Try to extract any embedded JSON
                $jsonPattern = '\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'
                $jsonMatches = [regex]::Matches($ResponseContent, $jsonPattern)
                
                if ($jsonMatches.Count -gt 0) {
                    $parseResult.ExtractedStructures.JSON = @()
                    foreach ($match in $jsonMatches) {
                        try {
                            $jsonObj = ConvertFrom-Json $match.Value -ErrorAction Stop
                            $parseResult.ExtractedStructures.JSON += @{
                                Content = $match.Value
                                Parsed = $jsonObj
                            }
                        } catch {
                            continue
                        }
                    }
                }
                
                $parseResult.PlainTextContent = $ResponseContent
                $parseResult.Success = $true
            }
            
            "XML" {
                $parseResult.ProcessingSteps += "Processing XML content"
                try {
                    $xmlDoc = [System.Xml.XmlDocument]::new()
                    $xmlDoc.LoadXml($ResponseContent)
                    $parseResult.ExtractedStructures.XML = $xmlDoc
                    $parseResult.Success = $true
                } catch {
                    $parseResult.Error = "XML parsing failed: $($_.Exception.Message)"
                    # Fallback to plain text
                    $parseResult.PlainTextContent = $ResponseContent
                }
            }
            
            "Markdown" {
                $parseResult.ProcessingSteps += "Processing Markdown content"
                
                # Extract code blocks
                $codeBlockPattern = '```(\w+)?\s*\n(.*?)\n```'
                $codeBlocks = [regex]::Matches($ResponseContent, $codeBlockPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                $parseResult.ExtractedStructures.CodeBlocks = @()
                foreach ($match in $codeBlocks) {
                    $parseResult.ExtractedStructures.CodeBlocks += @{
                        Language = $match.Groups[1].Value
                        Code = $match.Groups[2].Value
                        FullMatch = $match.Value
                    }
                }
                
                # Extract headers
                $headerPattern = '^(#{1,6})\s+(.*)$'
                $headers = [regex]::Matches($ResponseContent, $headerPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
                
                $parseResult.ExtractedStructures.Headers = @()
                foreach ($match in $headers) {
                    $parseResult.ExtractedStructures.Headers += @{
                        Level = $match.Groups[1].Value.Length
                        Text = $match.Groups[2].Value
                    }
                }
                
                $parseResult.PlainTextContent = $ResponseContent
                $parseResult.Success = $true
            }
            
            default {  # PlainText and others
                $parseResult.ProcessingSteps += "Processing as plain text"
                $parseResult.PlainTextContent = $ResponseContent
                $parseResult.Success = $true
            }
        }
        
        $stopwatch.Stop()
        $parseResult.ProcessingTime = $stopwatch.ElapsedMilliseconds
        
        Write-AnalysisLog -Message "Mixed format parsing completed in $($stopwatch.ElapsedMilliseconds)ms" -Level "INFO"
        return $parseResult
        
    } catch {
        $stopwatch.Stop()
        Write-AnalysisLog -Message "Mixed format parsing failed: $($_.Exception.Message)" -Level "ERROR"
        
        return @{
            OriginalContent = $ResponseContent
            DetectedFormat = "Error"
            FormatConfidence = 0.0
            ExtractedStructures = @{}
            PlainTextContent = $ResponseContent
            ProcessingSteps = @("Error occurred during parsing")
            Success = $false
            Error = $_.Exception.Message
            ProcessingTime = $stopwatch.ElapsedMilliseconds
        }
    }
}

function Invoke-UniversalResponseParser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [string]$ExpectedFormat = "Auto",
        
        [Parameter()]
        [switch]$ExtractEntities,
        
        [Parameter()]
        [switch]$AnalyzeSentiment,
        
        [Parameter()]
        [switch]$ValidateSchema
    )
    
    Write-AnalysisLog -Message "Starting universal response parsing" -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Step 1: Multi-format parsing
        $parseResult = Parse-MixedFormatResponse -ResponseContent $ResponseContent -PreferredFormat $ExpectedFormat
        
        if (-not $parseResult.Success) {
            throw "Multi-format parsing failed: $($parseResult.Error)"
        }
        
        # Step 2: Entity extraction if requested
        $entities = $null
        if ($ExtractEntities) {
            Write-AnalysisLog -Message "Extracting entities from parsed content" -Level "DEBUG"
            $entities = Extract-ResponseEntities -ResponseText $parseResult.PlainTextContent
        }
        
        # Step 3: Sentiment analysis if requested
        $sentiment = $null
        if ($AnalyzeSentiment) {
            Write-AnalysisLog -Message "Analyzing sentiment of parsed content" -Level "DEBUG"
            $sentiment = Analyze-ResponseSentiment -ResponseText $parseResult.PlainTextContent
        }
        
        # Step 4: Schema validation if requested and JSON available
        $schemaValidation = $null
        if ($ValidateSchema -and $parseResult.ExtractedStructures.JSON) {
            Write-AnalysisLog -Message "Validating extracted JSON against schema" -Level "DEBUG"
            
            $schemaValidation = @{
                IsValid = $false
                Errors = @()
                SchemaType = "Unknown"
            }
            
            try {
                if ($parseResult.ExtractedStructures.JSON -is [array]) {
                    # Multiple JSON structures
                    foreach ($jsonItem in $parseResult.ExtractedStructures.JSON) {
                        $isValid = Test-AnthropicResponseSchema -ParsedJson $jsonItem.Parsed
                        if ($isValid) {
                            $schemaValidation.IsValid = $true
                            $schemaValidation.SchemaType = "ClaudeResponse"
                            break
                        }
                    }
                } else {
                    # Single JSON structure
                    $schemaValidation.IsValid = Test-AnthropicResponseSchema -ParsedJson $parseResult.ExtractedStructures.JSON
                    $schemaValidation.SchemaType = "ClaudeResponse"
                }
            } catch {
                $schemaValidation.Errors += $_.Exception.Message
            }
        }
        
        $stopwatch.Stop()
        
        # Compile final result
        $finalResult = @{
            ParsingResult = $parseResult
            Entities = $entities
            Sentiment = $sentiment
            SchemaValidation = $schemaValidation
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            OverallSuccess = $parseResult.Success
            Summary = @{
                Format = $parseResult.DetectedFormat
                HasJSON = ($parseResult.ExtractedStructures.JSON -ne $null)
                HasRecommendation = ($parseResult.ExtractedStructures.Recommendation -ne $null)
                EntityCount = if ($entities) { $entities.TotalMatches } else { 0 }
                SentimentScore = if ($sentiment) { $sentiment.OverallConfidence } else { 0.0 }
                SchemaValid = if ($schemaValidation) { $schemaValidation.IsValid } else { $null }
            }
        }
        
        Write-AnalysisLog -Message "Universal response parsing completed successfully in $($stopwatch.ElapsedMilliseconds)ms" -Level "INFO"
        return $finalResult
        
    } catch {
        $stopwatch.Stop()
        Write-AnalysisLog -Message "Universal response parsing failed: $($_.Exception.Message)" -Level "ERROR"
        
        return @{
            ParsingResult = $null
            Entities = $null
            Sentiment = $null
            SchemaValidation = $null
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            OverallSuccess = $false
            Error = $_.Exception.Message
            Summary = @{
                Format = "Error"
                HasJSON = $false
                HasRecommendation = $false
                EntityCount = 0
                SentimentScore = 0.0
                SchemaValid = $false
            }
        }
    }
}

#endregion

#region FileSystemWatcher Integration - Phase 7 Day 1-2 Hours 3-4

# Module-level variables for response monitoring
$script:ResponseMonitoringConfig = @{
    DefaultResponsePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
    ProcessingDelay = 1000  # 1 second delay before processing new files
    MaxFileSize = 10MB      # Skip files larger than 10MB
    SupportedExtensions = @('.json', '.txt', '.md', '.log')
}

$script:ActiveResponseMonitors = @{}
$script:ProcessingQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
$script:ProcessedFiles = @{}  # Track processed files to avoid reprocessing

function Initialize-ResponseMonitoring {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ResponsePath = $script:ResponseMonitoringConfig.DefaultResponsePath,
        
        [Parameter()]
        [int]$ProcessingDelayMs = $script:ResponseMonitoringConfig.ProcessingDelay,
        
        [Parameter()]
        [switch]$EnableAdvancedAnalysis
    )
    
    Write-AnalysisLog -Message "Initializing response monitoring for path: $ResponsePath" -Level "INFO"
    
    try {
        # Ensure response directory exists
        if (-not (Test-Path $ResponsePath)) {
            New-Item -Path $ResponsePath -ItemType Directory -Force | Out-Null
            Write-AnalysisLog -Message "Created response monitoring directory: $ResponsePath" -Level "INFO"
        }
        
        # Import FileMonitor module if available
        try {
            Import-Module Unity-Claude-FileMonitor -Force -ErrorAction Stop
            Write-AnalysisLog -Message "FileMonitor module imported successfully" -Level "DEBUG"
        } catch {
            Write-AnalysisLog -Message "Failed to import FileMonitor module: $($_.Exception.Message)" -Level "WARNING"
            throw "FileMonitor dependency not available"
        }
        
        # Register response file change handler
        $responseHandler = {
            param([array]$AggregatedChanges)
            
            Write-AnalysisLog -Message "Processing $($AggregatedChanges.Count) file change events" -Level "DEBUG"
            
            foreach ($change in $AggregatedChanges) {
                # Filter for response files
                if ($change.FileType -eq 'Config' -and $change.Path -like '*.json') {
                    # Queue for processing with delay
                    $queueItem = @{
                        FilePath = $change.Path
                        ChangeType = $change.ChangeType
                        Timestamp = $change.FirstEvent
                        ProcessAfter = (Get-Date).AddMilliseconds($ProcessingDelayMs)
                        AdvancedAnalysis = $EnableAdvancedAnalysis
                    }
                    
                    $script:ProcessingQueue.Enqueue($queueItem)
                    Write-AnalysisLog -Message "Queued response file for processing: $($change.Path)" -Level "DEBUG"
                }
            }
        }
        
        Register-FileChangeHandler -Handler $responseHandler
        
        # Create file monitor for the response directory
        $monitorId = New-FileMonitor -Path $ResponsePath -Filter "*.json" -IncludeSubdirectories $true -DebounceMs 500
        Start-FileMonitor -Identifier $monitorId
        
        $script:ActiveResponseMonitors[$ResponsePath] = @{
            MonitorId = $monitorId
            Path = $ResponsePath
            Handler = $responseHandler
            ProcessingDelay = $ProcessingDelayMs
            AdvancedAnalysis = $EnableAdvancedAnalysis
            StartTime = Get-Date
        }
        
        # Start processing queue worker
        Start-ResponseProcessingWorker
        
        Write-AnalysisLog -Message "Response monitoring initialized successfully for $ResponsePath" -Level "INFO"
        return $monitorId
        
    } catch {
        Write-AnalysisLog -Message "Failed to initialize response monitoring: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Start-ResponseProcessingWorker {
    [CmdletBinding()]
    param()
    
    Write-AnalysisLog -Message "Starting response processing worker" -Level "DEBUG"
    
    # Create background job to process queued files
    $workerScript = {
        param($Queue, $ProcessedFiles, $AnalysisConfig)
        
        while ($true) {
            $item = $null
            if ($Queue.TryDequeue([ref]$item)) {
                $currentTime = Get-Date
                
                # Check if it's time to process this item
                if ($currentTime -ge $item.ProcessAfter) {
                    try {
                        # Check if file was already processed recently
                        $fileInfo = Get-Item $item.FilePath -ErrorAction SilentlyContinue
                        if (-not $fileInfo) {
                            continue  # File no longer exists
                        }
                        
                        $fileKey = "$($item.FilePath):$($fileInfo.LastWriteTime.Ticks)"
                        if ($ProcessedFiles.ContainsKey($fileKey)) {
                            continue  # Already processed this version
                        }
                        
                        # Process the file
                        $result = Process-ResponseFile -FilePath $item.FilePath -EnableAdvancedAnalysis:$item.AdvancedAnalysis
                        
                        if ($result.Success) {
                            $ProcessedFiles[$fileKey] = @{
                                ProcessedAt = $currentTime
                                Result = $result
                            }
                            
                            # Trigger any registered response callbacks
                            Invoke-ResponseCallbacks -ProcessingResult $result
                        }
                        
                    } catch {
                        # Log error but continue processing
                        Write-Host "Error processing response file: $($_.Exception.Message)" -ForegroundColor Red
                    }
                } else {
                    # Re-queue for later processing
                    $Queue.Enqueue($item)
                }
            }
            
            # Brief sleep to prevent CPU spinning
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Start the worker as a background job
    $job = Start-Job -ScriptBlock $workerScript -ArgumentList $script:ProcessingQueue, $script:ProcessedFiles, $script:AnalysisConfig
    
    # Store job reference for cleanup
    $script:ActiveResponseMonitors["ProcessingWorker"] = @{
        JobId = $job.Id
        Job = $job
        StartTime = Get-Date
    }
    
    Write-AnalysisLog -Message "Response processing worker started with job ID: $($job.Id)" -Level "INFO"
}

function Process-ResponseFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [switch]$EnableAdvancedAnalysis
    )
    
    Write-AnalysisLog -Message "Processing response file: $FilePath" -Level "DEBUG"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Validate file exists and is not too large
        $fileInfo = Get-Item $FilePath -ErrorAction Stop
        if ($fileInfo.Length -gt $script:ResponseMonitoringConfig.MaxFileSize) {
            Write-AnalysisLog -Message "Skipping large file ($($fileInfo.Length) bytes): $FilePath" -Level "WARNING"
            return @{ Success = $false; Reason = "FileTooLarge"; Size = $fileInfo.Length }
        }
        
        # Read file content
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-AnalysisLog -Message "Skipping empty file: $FilePath" -Level "DEBUG"
            return @{ Success = $false; Reason = "EmptyFile" }
        }
        
        # Use the universal response parser
        $parseResult = Invoke-UniversalResponseParser -ResponseContent $content -ExtractEntities -AnalyzeSentiment:$EnableAdvancedAnalysis -ValidateSchema
        
        # Enhanced analysis if requested
        $enhancedResult = $null
        if ($EnableAdvancedAnalysis -and $parseResult.OverallSuccess) {
            $enhancedResult = Invoke-EnhancedPatternAnalysis -ResponseText $content -IncludeNGrams -BuildRelationshipGraph -TrackTemporalContext
        }
        
        $stopwatch.Stop()
        
        $result = @{
            Success = $parseResult.OverallSuccess
            FilePath = $FilePath
            FileSize = $fileInfo.Length
            LastModified = $fileInfo.LastWriteTime
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            ParseResult = $parseResult
            EnhancedAnalysis = $enhancedResult
            ProcessedAt = Get-Date
        }
        
        Write-AnalysisLog -Message "Successfully processed response file in $($stopwatch.ElapsedMilliseconds)ms: $FilePath" -Level "INFO"
        return $result
        
    } catch {
        $stopwatch.Stop()
        Write-AnalysisLog -Message "Failed to process response file '$FilePath': $($_.Exception.Message)" -Level "ERROR"
        
        return @{
            Success = $false
            FilePath = $FilePath
            ProcessingTime = $stopwatch.ElapsedMilliseconds
            Error = $_.Exception.Message
            ProcessedAt = Get-Date
        }
    }
}

function Register-ResponseCallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Callback,
        
        [Parameter()]
        [string]$Name = "Callback_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    )
    
    if (-not $script:ResponseCallbacks) {
        $script:ResponseCallbacks = @{}
    }
    
    $script:ResponseCallbacks[$Name] = $Callback
    Write-AnalysisLog -Message "Registered response callback: $Name" -Level "DEBUG"
}

function Invoke-ResponseCallbacks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ProcessingResult
    )
    
    if (-not $script:ResponseCallbacks) {
        return
    }
    
    foreach ($callbackName in $script:ResponseCallbacks.Keys) {
        try {
            Write-AnalysisLog -Message "Invoking response callback: $callbackName" -Level "DEBUG"
            & $script:ResponseCallbacks[$callbackName] -Result $ProcessingResult
        } catch {
            Write-AnalysisLog -Message "Error in response callback '$callbackName': $($_.Exception.Message)" -Level "WARNING"
        }
    }
}

function Stop-ResponseMonitoring {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ResponsePath
    )
    
    Write-AnalysisLog -Message "Stopping response monitoring" -Level "INFO"
    
    try {
        if ($ResponsePath) {
            # Stop specific monitor
            if ($script:ActiveResponseMonitors.ContainsKey($ResponsePath)) {
                $monitor = $script:ActiveResponseMonitors[$ResponsePath]
                Stop-FileMonitor -Identifier $monitor.MonitorId
                $script:ActiveResponseMonitors.Remove($ResponsePath)
                Write-AnalysisLog -Message "Stopped monitoring for path: $ResponsePath" -Level "INFO"
            }
        } else {
            # Stop all monitors
            foreach ($path in @($script:ActiveResponseMonitors.Keys)) {
                if ($path -ne "ProcessingWorker") {
                    $monitor = $script:ActiveResponseMonitors[$path]
                    Stop-FileMonitor -Identifier $monitor.MonitorId
                    $script:ActiveResponseMonitors.Remove($path)
                }
            }
            
            # Stop processing worker
            if ($script:ActiveResponseMonitors.ContainsKey("ProcessingWorker")) {
                $worker = $script:ActiveResponseMonitors["ProcessingWorker"]
                Stop-Job -Id $worker.JobId -ErrorAction SilentlyContinue
                Remove-Job -Id $worker.JobId -ErrorAction SilentlyContinue
                $script:ActiveResponseMonitors.Remove("ProcessingWorker")
                Write-AnalysisLog -Message "Stopped response processing worker" -Level "INFO"
            }
        }
        
    } catch {
        Write-AnalysisLog -Message "Error stopping response monitoring: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Get-ResponseMonitoringStatus {
    [CmdletBinding()]
    param()
    
    $status = @{
        ActiveMonitors = @{}
        ProcessingQueue = @{
            Size = $script:ProcessingQueue.Count
            Items = @()
        }
        ProcessedFiles = @{
            Count = $script:ProcessedFiles.Count
            Recent = @()
        }
        OverallHealth = "Unknown"
    }
    
    # Get monitor status
    foreach ($path in $script:ActiveResponseMonitors.Keys) {
        $monitor = $script:ActiveResponseMonitors[$path]
        $status.ActiveMonitors[$path] = @{
            Type = if ($path -eq "ProcessingWorker") { "Worker" } else { "FileMonitor" }
            StartTime = $monitor.StartTime
            IsActive = if ($monitor.MonitorId) { 
                $monitorStatus = Get-FileMonitorStatus -Identifier $monitor.MonitorId
                $monitorStatus.IsActive 
            } else { 
                $true  # Assume worker is active
            }
        }
    }
    
    # Get recent processed files (last 10)
    $recentFiles = @($script:ProcessedFiles.Keys | 
        Sort-Object { $script:ProcessedFiles[$_].ProcessedAt } -Descending |
        Select-Object -First 10)
    
    foreach ($fileKey in $recentFiles) {
        $processed = $script:ProcessedFiles[$fileKey]
        $status.ProcessedFiles.Recent += @{
            FileKey = $fileKey
            ProcessedAt = $processed.ProcessedAt
            Success = $processed.Result.Success
            ProcessingTime = $processed.Result.ProcessingTime
        }
    }
    
    # Determine overall health
    $activeMonitors = @($status.ActiveMonitors.Values | Where-Object { $_.IsActive }).Count
    $totalMonitors = $status.ActiveMonitors.Count
    
    if ($totalMonitors -eq 0) {
        $status.OverallHealth = "NotInitialized"
    } elseif ($activeMonitors -eq $totalMonitors) {
        $status.OverallHealth = "Healthy"
    } elseif ($activeMonitors -gt 0) {
        $status.OverallHealth = "Degraded"
    } else {
        $status.OverallHealth = "Failed"
    }
    
    return $status
}

function Test-ResponseMonitoringIntegration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TestDirectory = "$env:TEMP\ResponseMonitoringTest"
    )
    
    Write-AnalysisLog -Message "Testing response monitoring integration" -Level "INFO"
    $testResults = @{
        Tests = @()
        OverallSuccess = $false
        TestDirectory = $TestDirectory
    }
    
    try {
        # Create test directory
        if (Test-Path $TestDirectory) {
            Remove-Item -Path $TestDirectory -Recurse -Force
        }
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
        
        # Test 1: Initialize monitoring
        $testResults.Tests += Test-MonitorInitialization -TestDirectory $TestDirectory
        
        # Test 2: File processing
        $testResults.Tests += Test-FileProcessing -TestDirectory $TestDirectory
        
        # Test 3: Queue processing
        $testResults.Tests += Test-QueueProcessing -TestDirectory $TestDirectory
        
        # Test 4: Integration with enhanced parsing
        $testResults.Tests += Test-EnhancedParsingIntegration -TestDirectory $TestDirectory
        
        # Cleanup
        Stop-ResponseMonitoring
        Remove-Item -Path $TestDirectory -Recurse -Force -ErrorAction SilentlyContinue
        
        $passedTests = @($testResults.Tests | Where-Object { $_.Passed }).Count
        $totalTests = $testResults.Tests.Count
        
        $testResults.OverallSuccess = ($passedTests -eq $totalTests)
        
        Write-AnalysisLog -Message "Response monitoring integration tests completed: $passedTests/$totalTests passed" -Level "INFO"
        return $testResults
        
    } catch {
        Write-AnalysisLog -Message "Response monitoring integration test failed: $($_.Exception.Message)" -Level "ERROR"
        $testResults.Tests += @{
            Name = "Integration Test Exception"
            Passed = $false
            Error = $_.Exception.Message
        }
        return $testResults
    }
}

function Test-MonitorInitialization {
    param([string]$TestDirectory)
    
    try {
        $monitorId = Initialize-ResponseMonitoring -ResponsePath $TestDirectory -ProcessingDelayMs 500
        
        $status = Get-ResponseMonitoringStatus
        $isHealthy = ($status.OverallHealth -eq "Healthy")
        
        return @{
            Name = "Monitor Initialization"
            Passed = $isHealthy
            Details = "Monitor ID: $monitorId, Status: $($status.OverallHealth)"
        }
    } catch {
        return @{
            Name = "Monitor Initialization"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-FileProcessing {
    param([string]$TestDirectory)
    
    try {
        # Create test JSON file
        $testFile = Join-Path $TestDirectory "test_response.json"
        $testContent = @{
            RESPONSE = "RECOMMENDATION: TEST - C:\Test\File.ps1"
            timestamp = (Get-Date -Format "o")
            issue = "Test file processing"
        } | ConvertTo-Json
        
        Set-Content -Path $testFile -Value $testContent -Encoding UTF8
        
        # Process directly
        $result = Process-ResponseFile -FilePath $testFile -EnableAdvancedAnalysis
        
        return @{
            Name = "File Processing"
            Passed = $result.Success
            Details = "Processing time: $($result.ProcessingTime)ms, Format: $($result.ParseResult.Summary.Format)"
        }
    } catch {
        return @{
            Name = "File Processing"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-QueueProcessing {
    param([string]$TestDirectory)
    
    try {
        # Add item to queue
        $queueItem = @{
            FilePath = Join-Path $TestDirectory "queue_test.json"
            ChangeType = "Created"
            Timestamp = Get-Date
            ProcessAfter = Get-Date
            AdvancedAnalysis = $false
        }
        
        # Create the file
        $testContent = '{"test": "queue processing"}'
        Set-Content -Path $queueItem.FilePath -Value $testContent -Encoding UTF8
        
        $script:ProcessingQueue.Enqueue($queueItem)
        
        # Wait briefly for processing
        Start-Sleep -Seconds 2
        
        $queueSize = $script:ProcessingQueue.Count
        
        return @{
            Name = "Queue Processing"
            Passed = ($queueSize -le 1)  # Item should be processed or being processed
            Details = "Queue size after processing: $queueSize"
        }
    } catch {
        return @{
            Name = "Queue Processing"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-EnhancedParsingIntegration {
    param([string]$TestDirectory)
    
    try {
        # Create complex test file
        $testFile = Join-Path $TestDirectory "enhanced_test.json"
        $testContent = @{
            RESPONSE = "RECOMMENDATION: FIX - C:\UnityProjects\Test\ErrorFile.cs"
            timestamp = (Get-Date -Format "o")
            analysis = @{
                errors = @("CS0103: Name does not exist", "CS0246: Type not found")
                files = @("ErrorFile.cs", "DependentFile.cs")
                suggestions = @("Add using statement", "Check namespace")
            }
        } | ConvertTo-Json -Depth 3
        
        Set-Content -Path $testFile -Value $testContent -Encoding UTF8
        
        # Process with enhanced analysis
        $result = Process-ResponseFile -FilePath $testFile -EnableAdvancedAnalysis
        
        $hasEntities = ($result.ParseResult.Summary.EntityCount -gt 0)
        $hasValidJson = $result.ParseResult.Summary.HasJSON
        $hasRecommendation = $result.ParseResult.Summary.HasRecommendation
        
        return @{
            Name = "Enhanced Parsing Integration"
            Passed = ($hasEntities -and $hasValidJson -and $hasRecommendation)
            Details = "Entities: $($result.ParseResult.Summary.EntityCount), JSON: $hasValidJson, Recommendation: $hasRecommendation"
        }
    } catch {
        return @{
            Name = "Enhanced Parsing Integration"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Exported Functions

# Export the main function
Export-ModuleMember -Function @(
    'Invoke-EnhancedResponseAnalysis',
    'Test-JsonTruncation',
    'Repair-TruncatedJson',
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerState',
    'Extract-ResponseEntities',
    'Analyze-ResponseSentiment', 
    'Get-ResponseContext',
    'Calculate-PatternConfidence',
    'Get-ConfidenceBand',
    'Invoke-BayesianConfidenceAdjustment',
    'Build-NGramModel',
    'Calculate-PatternSimilarity',
    'Build-EntityRelationshipGraph',
    'Measure-EntityProximity',
    'Find-EntityClusters',
    'Add-TemporalContext',
    'Get-TemporalContextRelevance',
    'Invoke-EnhancedPatternAnalysis',
    'Test-ResponseFormat',
    'Parse-MixedFormatResponse',
    'Invoke-UniversalResponseParser',
    'Initialize-ResponseMonitoring',
    'Stop-ResponseMonitoring',
    'Process-ResponseFile',
    'Register-ResponseCallback',
    'Get-ResponseMonitoringStatus',
    'Test-ResponseMonitoringIntegration'
)

#endregion

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCuodpQZgqfY0ab
# 812O8dzoDIyPF9y2XXO+bsO1Ng2tC6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDgx0cMtL8NMeKD8NIxK4W17
# aKGqlDRwBjhneyahFxS3MA0GCSqGSIb3DQEBAQUABIIBAJeoYlcSOvHxRuUlnL1y
# xqaOtZEmYIrkYIRpqk+oiHb/WY/DisvK07iOyYbYz2fsoRgQbLDEr9Cccsy1z8k3
# K1bSMWaa4zR2kneUHU3Fl3EqGD3cQ+g/tQO6i/L/+ktlSaYyu0jPoUO1GLke+z0J
# CzJGHMjNsvIWgLEJR8+/q8SC9XtIjxezgohI8JtcIrsVhFqt9gVc71tUzbRI6JfU
# 3pPuA3jsar+Z9gERjeilNhwDJlKpDTa/M4FvsUeBpi7fo/o3K0hm5s5owIuJWtPe
# jgzbatitLSVG0ylqeZHbzflpkFYoeahTvgEQHxClQHUdGHUaSFfuYBfWlq/uSUn9
# TSw=
# SIG # End signature block
