# Unity-Claude-Ollama PowerShell Module
# Week 1 Day 3 Hour 1-2: Ollama Local AI Integration
# AI-Enhanced Documentation Generation with Local Models

#region Module Variables and Configuration

# Module-level configuration
$script:OllamaConfig = @{
    BaseUrl = "http://localhost:11434"
    DefaultModel = "codellama:34b"
    ContextWindow = 32768
    MaxRetries = 5
    RetryDelay = 10
    RequestTimeout = 300  # Extended to 5 minutes for CodeLlama 13B
    StreamingEnabled = $true
    KeepAlive = "30m"     # Keep model loaded for 30 minutes
    ModelPreloaded = $false
}

# Performance tracking
$script:OllamaMetrics = @{
    RequestCount = 0
    SuccessCount = 0
    ErrorCount = 0
    AverageResponseTime = 0
    LastRequestTime = $null
}

# Connection state
$script:OllamaConnection = @{
    IsConnected = $false
    LastHealthCheck = $null
    ServiceStatus = "Unknown"
}

Write-Host "[Unity-Claude-Ollama] Module loading - Local AI integration v1.0.0" -ForegroundColor Green

#endregion

#region Core Service Management Functions

function Start-OllamaService {
    <#
    .SYNOPSIS
    Starts the Ollama service and validates operational status
    
    .DESCRIPTION
    Manages Ollama service startup, health checks, and readiness validation for local AI operations
    
    .EXAMPLE
    Start-OllamaService
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[OllamaService] Starting Ollama service..." -ForegroundColor Cyan
    
    try {
        # Check if service is already running
        $healthCheck = Test-OllamaConnectivity -Silent
        if ($healthCheck.IsConnected) {
            Write-Host "[OllamaService] Service already running and responsive" -ForegroundColor Green
            return $healthCheck
        }
        
        # Start Ollama service in background
        Write-Host "[OllamaService] Launching Ollama service..." -ForegroundColor Yellow
        $process = Start-Process "ollama" -ArgumentList "serve" -PassThru -WindowStyle Hidden
        
        # Wait for service to become responsive
        $timeout = 30 # seconds
        $elapsed = 0
        
        do {
            Start-Sleep -Seconds 2
            $elapsed += 2
            $healthCheck = Test-OllamaConnectivity -Silent
            
            Write-Host "[OllamaService] Waiting for service... ($elapsed/$timeout seconds)" -ForegroundColor Gray
            
        } while (-not $healthCheck.IsConnected -and $elapsed -lt $timeout)
        
        if ($healthCheck.IsConnected) {
            Write-Host "[OllamaService] Service started successfully on $($script:OllamaConfig.BaseUrl)" -ForegroundColor Green
            $script:OllamaConnection.ServiceStatus = "Running"
            return $healthCheck
        } else {
            throw "Service failed to start within $timeout seconds"
        }
    }
    catch {
        Write-Error "[OllamaService] Failed to start service: $($_.Exception.Message)"
        $script:OllamaConnection.ServiceStatus = "Failed"
        return @{ IsConnected = $false; Error = $_.Exception.Message }
    }
}

function Stop-OllamaService {
    <#
    .SYNOPSIS
    Gracefully stops the Ollama service
    
    .DESCRIPTION
    Performs graceful shutdown of Ollama service with proper cleanup
    
    .EXAMPLE
    Stop-OllamaService
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[OllamaService] Stopping Ollama service..." -ForegroundColor Yellow
    
    try {
        # Find Ollama process
        $ollamaProcesses = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
        
        if ($ollamaProcesses) {
            Write-Host "[OllamaService] Found $($ollamaProcesses.Count) Ollama process(es)" -ForegroundColor Gray
            
            foreach ($process in $ollamaProcesses) {
                Write-Host "[OllamaService] Stopping process ID: $($process.Id)" -ForegroundColor Gray
                $process.CloseMainWindow()
                
                # Wait for graceful shutdown
                if (-not $process.WaitForExit(10000)) {
                    Write-Host "[OllamaService] Force stopping process ID: $($process.Id)" -ForegroundColor Red
                    $process.Kill()
                }
            }
            
            Write-Host "[OllamaService] Service stopped successfully" -ForegroundColor Green
            $script:OllamaConnection.ServiceStatus = "Stopped"
        } else {
            Write-Host "[OllamaService] No Ollama processes found" -ForegroundColor Gray
        }
        
        $script:OllamaConnection.IsConnected = $false
        return @{ Success = $true; Message = "Service stopped successfully" }
    }
    catch {
        Write-Error "[OllamaService] Error stopping service: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-OllamaConnectivity {
    <#
    .SYNOPSIS
    Tests connectivity to Ollama service
    
    .DESCRIPTION
    Performs comprehensive connectivity validation and health checks for Ollama service
    
    .PARAMETER Silent
    Suppresses console output for automated checks
    
    .EXAMPLE
    Test-OllamaConnectivity
    
    .EXAMPLE
    $health = Test-OllamaConnectivity -Silent
    #>
    [CmdletBinding()]
    param(
        [switch]$Silent
    )
    
    if (-not $Silent) {
        Write-Host "[OllamaConnectivity] Testing Ollama service connectivity..." -ForegroundColor Cyan
    }
    
    try {
        # Test basic HTTP connectivity
        $healthEndpoint = "$($script:OllamaConfig.BaseUrl)/api/tags"
        $response = Invoke-RestMethod -Uri $healthEndpoint -Method GET -TimeoutSec 5 -ErrorAction Stop
        
        $modelCount = ($response.models | Measure-Object).Count
        $isConnected = $modelCount -gt 0
        
        if (-not $Silent) {
            Write-Host "[OllamaConnectivity] Service responsive - $modelCount model(s) available" -ForegroundColor Green
        }
        
        $result = @{
            IsConnected = $isConnected
            ModelsAvailable = $modelCount
            Models = $response.models
            Endpoint = $script:OllamaConfig.BaseUrl
            Timestamp = Get-Date
        }
        
        $script:OllamaConnection.IsConnected = $isConnected
        $script:OllamaConnection.LastHealthCheck = Get-Date
        
        return $result
    }
    catch {
        if (-not $Silent) {
            Write-Host "[OllamaConnectivity] Service not responsive: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        $script:OllamaConnection.IsConnected = $false
        
        return @{
            IsConnected = $false
            Error = $_.Exception.Message
            Endpoint = $script:OllamaConfig.BaseUrl
            Timestamp = Get-Date
        }
    }
}

#endregion

#region Model Management Functions

function Get-OllamaModelInfo {
    <#
    .SYNOPSIS
    Retrieves information about available Ollama models
    
    .DESCRIPTION
    Provides detailed information about installed models, their capabilities, and status
    
    .PARAMETER ModelName
    Specific model to query, defaults to all models
    
    .EXAMPLE
    Get-OllamaModelInfo
    
    .EXAMPLE
    Get-OllamaModelInfo -ModelName "codellama:34b"
    #>
    [CmdletBinding()]
    param(
        [string]$ModelName
    )
    
    Write-Host "[OllamaModelInfo] Retrieving model information..." -ForegroundColor Cyan
    
    try {
        $connectivity = Test-OllamaConnectivity -Silent
        if (-not $connectivity.IsConnected) {
            throw "Ollama service not available"
        }
        
        $models = $connectivity.Models
        
        if ($ModelName) {
            $models = $models | Where-Object { $_.name -eq $ModelName }
            if (-not $models) {
                throw "Model '$ModelName' not found"
            }
        }
        
        Write-Host "[OllamaModelInfo] Found $(($models | Measure-Object).Count) model(s)" -ForegroundColor Green
        
        foreach ($model in $models) {
            Write-Host "  Model: $($model.name)" -ForegroundColor White
            Write-Host "  Size: $($model.size)" -ForegroundColor Gray
            Write-Host "  Modified: $($model.modified)" -ForegroundColor Gray
        }
        
        return $models
    }
    catch {
        Write-Error "[OllamaModelInfo] Error retrieving model info: $($_.Exception.Message)"
        return $null
    }
}

function Set-OllamaConfiguration {
    <#
    .SYNOPSIS
    Configures Ollama integration settings
    
    .DESCRIPTION
    Updates configuration for context window, timeouts, and performance optimization
    
    .PARAMETER ContextWindow
    Context window size in tokens (default: 32768)
    
    .PARAMETER RequestTimeout
    Request timeout in seconds (default: 30)
    
    .PARAMETER MaxRetries
    Maximum retry attempts (default: 3)
    
    .EXAMPLE
    Set-OllamaConfiguration -ContextWindow 65536 -RequestTimeout 60
    #>
    [CmdletBinding()]
    param(
        [int]$ContextWindow = 32768,
        [int]$RequestTimeout = 30,
        [int]$MaxRetries = 3,
        [string]$DefaultModel = "codellama:34b"
    )
    
    Write-Host "[OllamaConfig] Updating configuration..." -ForegroundColor Cyan
    
    $script:OllamaConfig.ContextWindow = $ContextWindow
    $script:OllamaConfig.RequestTimeout = $RequestTimeout
    $script:OllamaConfig.MaxRetries = $MaxRetries
    $script:OllamaConfig.DefaultModel = $DefaultModel
    
    Write-Host "[OllamaConfig] Configuration updated:" -ForegroundColor Green
    Write-Host "  Context Window: $ContextWindow tokens" -ForegroundColor Gray
    Write-Host "  Request Timeout: $RequestTimeout seconds" -ForegroundColor Gray
    Write-Host "  Max Retries: $MaxRetries attempts" -ForegroundColor Gray
    Write-Host "  Default Model: $DefaultModel" -ForegroundColor Gray
    
    return $script:OllamaConfig
}

#endregion

#region Core AI Documentation Functions

function Invoke-OllamaDocumentation {
    <#
    .SYNOPSIS
    Generates AI-enhanced documentation for PowerShell code
    
    .DESCRIPTION
    Uses Ollama local AI to generate comprehensive documentation, comments, and explanations
    
    .PARAMETER CodeContent
    PowerShell code content to document
    
    .PARAMETER DocumentationType
    Type of documentation to generate (Synopsis, Detailed, Comments, Examples)
    
    .PARAMETER FilePath
    Path to PowerShell file to document
    
    .EXAMPLE
    Invoke-OllamaDocumentation -CodeContent $code -DocumentationType "Detailed"
    
    .EXAMPLE
    Invoke-OllamaDocumentation -FilePath "MyScript.ps1" -DocumentationType "Comments"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Content")]
        [string]$CodeContent,
        
        [Parameter(Mandatory=$true, ParameterSetName="File")]
        [string]$FilePath,
        
        [ValidateSet("Synopsis", "Detailed", "Comments", "Examples", "Complete")]
        [string]$DocumentationType = "Detailed"
    )
    
    Write-Host "[OllamaDocumentation] Generating $DocumentationType documentation..." -ForegroundColor Cyan
    
    try {
        # Validate connectivity
        $connectivity = Test-OllamaConnectivity -Silent
        if (-not $connectivity.IsConnected) {
            throw "Ollama service not available"
        }
        
        # Get code content
        if ($PSCmdlet.ParameterSetName -eq "File") {
            if (-not (Test-Path $FilePath)) {
                throw "File not found: $FilePath"
            }
            $CodeContent = Get-Content $FilePath -Raw
            Write-Host "[OllamaDocumentation] Loaded file: $FilePath" -ForegroundColor Gray
        }
        
        # Format prompt based on documentation type
        $prompt = Format-DocumentationPrompt -CodeContent $CodeContent -DocumentationType $DocumentationType
        
        # Generate documentation with retry logic
        $documentation = Invoke-OllamaRetry -Prompt $prompt -Model $script:OllamaConfig.DefaultModel
        
        if ($documentation) {
            Write-Host "[OllamaDocumentation] Documentation generated successfully" -ForegroundColor Green
            Write-Host "[OllamaDocumentation] Length: $($documentation.Length) characters" -ForegroundColor Gray
            
            # Update metrics
            $script:OllamaMetrics.SuccessCount++
            
            return @{
                Documentation = $documentation
                DocumentationType = $DocumentationType
                CodeLength = $CodeContent.Length
                GeneratedLength = $documentation.Length
                Model = $script:OllamaConfig.DefaultModel
                Timestamp = Get-Date
            }
        } else {
            throw "Documentation generation failed"
        }
    }
    catch {
        Write-Error "[OllamaDocumentation] Error generating documentation: $($_.Exception.Message)"
        $script:OllamaMetrics.ErrorCount++
        return $null
    }
}

function Invoke-OllamaCodeAnalysis {
    <#
    .SYNOPSIS
    Performs AI-powered code analysis and generates improvement suggestions
    
    .DESCRIPTION
    Uses local AI to analyze PowerShell code for best practices, security, and optimization opportunities
    
    .PARAMETER CodeContent
    PowerShell code content to analyze
    
    .PARAMETER AnalysisType
    Type of analysis to perform (Security, Performance, BestPractices, Complete)
    
    .EXAMPLE
    Invoke-OllamaCodeAnalysis -CodeContent $code -AnalysisType "Security"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CodeContent,
        
        [ValidateSet("Security", "Performance", "BestPractices", "Complete")]
        [string]$AnalysisType = "Complete"
    )
    
    Write-Host "[OllamaCodeAnalysis] Performing $AnalysisType analysis..." -ForegroundColor Cyan
    
    try {
        $analysisPrompt = @"
Act as an expert PowerShell developer and code reviewer. Analyze the following PowerShell code for $AnalysisType concerns:

$CodeContent

Please provide:
1. Key findings and issues identified
2. Specific recommendations for improvement
3. Code examples for suggested fixes
4. Risk assessment and priority levels

Focus on actionable, specific feedback that improves code quality and maintainability.
"@
        
        $analysis = Invoke-OllamaRetry -Prompt $analysisPrompt -Model $script:OllamaConfig.DefaultModel
        
        if ($analysis) {
            Write-Host "[OllamaCodeAnalysis] Analysis completed successfully" -ForegroundColor Green
            return @{
                Analysis = $analysis
                AnalysisType = $AnalysisType
                CodeLength = $CodeContent.Length
                Model = $script:OllamaConfig.DefaultModel
                Timestamp = Get-Date
            }
        } else {
            throw "Code analysis generation failed"
        }
    }
    catch {
        Write-Error "[OllamaCodeAnalysis] Error performing analysis: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-OllamaExplanation {
    <#
    .SYNOPSIS
    Generates technical explanations for complex PowerShell code
    
    .DESCRIPTION
    Creates detailed explanations of PowerShell code logic, algorithms, and architectural decisions
    
    .PARAMETER CodeContent
    PowerShell code content to explain
    
    .PARAMETER ExplanationLevel
    Detail level for explanation (Basic, Intermediate, Advanced)
    
    .EXAMPLE
    Invoke-OllamaExplanation -CodeContent $complexCode -ExplanationLevel "Advanced"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CodeContent,
        
        [ValidateSet("Basic", "Intermediate", "Advanced")]
        [string]$ExplanationLevel = "Intermediate"
    )
    
    Write-Host "[OllamaExplanation] Generating $ExplanationLevel explanation..." -ForegroundColor Cyan
    
    try {
        $explanationPrompt = @"
Act as a technical writer explaining PowerShell code to a $ExplanationLevel audience.

Code to explain:
$CodeContent

Please provide:
1. High-level overview of what the code does
2. Step-by-step breakdown of the logic flow
3. Explanation of key PowerShell concepts used
4. Purpose and benefits of the implementation approach

Tailor the explanation to a $ExplanationLevel understanding level.
"@
        
        $explanation = Invoke-OllamaRetry -Prompt $explanationPrompt -Model $script:OllamaConfig.DefaultModel
        
        if ($explanation) {
            Write-Host "[OllamaExplanation] Explanation generated successfully" -ForegroundColor Green
            return @{
                Explanation = $explanation
                ExplanationLevel = $ExplanationLevel
                CodeLength = $CodeContent.Length
                Model = $script:OllamaConfig.DefaultModel
                Timestamp = Get-Date
            }
        } else {
            throw "Explanation generation failed"
        }
    }
    catch {
        Write-Error "[OllamaExplanation] Error generating explanation: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region Utility and Support Functions

function Start-ModelPreloading {
    <#
    .SYNOPSIS
    Preloads Ollama model into memory for faster subsequent requests
    
    .DESCRIPTION
    Warms up the specified model to eliminate cold start delays and improve response times
    
    .PARAMETER Model
    Model to preload (defaults to configured default model)
    
    .EXAMPLE
    Start-ModelPreloading -Model "codellama:34b"
    #>
    [CmdletBinding()]
    param(
        [string]$Model = $script:OllamaConfig.DefaultModel
    )
    
    Write-Host "[ModelPreloading] Preloading model: $Model..." -ForegroundColor Cyan
    
    try {
        # Check if model is already loaded
        $modelsLoaded = Invoke-RestMethod -Uri "$($script:OllamaConfig.BaseUrl)/api/ps" -Method GET -TimeoutSec 10 -ErrorAction Stop
        $modelLoaded = $modelsLoaded.models | Where-Object { $_.name -eq $Model }
        
        if ($modelLoaded) {
            Write-Host "[ModelPreloading] Model $Model already loaded in memory" -ForegroundColor Green
            $script:OllamaConfig.ModelPreloaded = $true
            return @{ Success = $true; AlreadyLoaded = $true; Model = $Model }
        }
        
        Write-Host "[ModelPreloading] Loading model into memory..." -ForegroundColor Yellow
        
        # Preload with empty prompt and keep_alive
        $preloadBody = @{
            model = $Model
            prompt = ""
            options = @{
                num_ctx = $script:OllamaConfig.ContextWindow
            }
            keep_alive = $script:OllamaConfig.KeepAlive
        } | ConvertTo-Json -Depth 5
        
        $preloadStart = Get-Date
        $response = Invoke-RestMethod -Uri "$($script:OllamaConfig.BaseUrl)/api/generate" `
                                      -Method POST `
                                      -Body $preloadBody `
                                      -ContentType "application/json" `
                                      -TimeoutSec 120 `
                                      -DisableKeepAlive
        
        $preloadDuration = (Get-Date) - $preloadStart
        Write-Host "[ModelPreloading] Model preloaded successfully in $($preloadDuration.TotalSeconds)s" -ForegroundColor Green
        
        $script:OllamaConfig.ModelPreloaded = $true
        return @{ 
            Success = $true 
            AlreadyLoaded = $false 
            Model = $Model 
            PreloadTime = $preloadDuration.TotalSeconds
        }
    }
    catch {
        Write-Host "[ModelPreloading] Failed to preload model: $($_.Exception.Message)" -ForegroundColor Red
        $script:OllamaConfig.ModelPreloaded = $false
        return @{ Success = $false; Error = $_.Exception.Message; Model = $Model }
    }
}

function Format-DocumentationPrompt {
    <#
    .SYNOPSIS
    Formats AI prompts for documentation generation
    
    .DESCRIPTION
    Creates optimized prompts for different documentation types using prompt engineering best practices
    
    .PARAMETER CodeContent
    PowerShell code content
    
    .PARAMETER DocumentationType
    Type of documentation to generate
    
    .EXAMPLE
    Format-DocumentationPrompt -CodeContent $code -DocumentationType "Synopsis"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CodeContent,
        
        [Parameter(Mandatory=$true)]
        [string]$DocumentationType
    )
    
    Write-Host "[DocumentationPrompt] Formatting prompt for $DocumentationType..." -ForegroundColor Gray
    
    $basePrompt = @"
Act as an expert PowerShell technical writer. You are documenting production PowerShell code for a professional development team.

Code to document:
$CodeContent

"@
    
    switch ($DocumentationType) {
        "Synopsis" {
            return $basePrompt + @"
Generate a concise synopsis including:
1. Purpose and primary function
2. Key parameters and return values  
3. Usage context and scenarios
4. Brief example

Keep it concise but comprehensive.
"@
        }
        
        "Detailed" {
            return $basePrompt + @"
Generate comprehensive documentation including:
1. Detailed description of functionality
2. Complete parameter documentation with examples
3. Return value specifications
4. Multiple usage scenarios with code examples
5. Best practices and considerations
6. Error handling and troubleshooting guidance

Provide thorough, production-ready documentation.
"@
        }
        
        "Comments" {
            return $basePrompt + @"
Generate inline code comments including:
1. Function and section header comments
2. Complex logic explanation comments
3. Variable purpose and scope documentation
4. Error handling and edge case comments
5. Performance considerations where relevant

Focus on clarity and maintainability.
"@
        }
        
        "Examples" {
            return $basePrompt + @"
Generate practical usage examples including:
1. Basic usage scenarios with expected output
2. Advanced use cases with complex parameters
3. Error handling examples
4. Integration examples with other functions
5. Real-world automation scenarios

Provide diverse, realistic examples.
"@
        }
        
        "Complete" {
            return $basePrompt + @"
Generate complete documentation package including:
1. Comprehensive function description
2. Full parameter documentation
3. Detailed examples and use cases
4. Best practices and optimization tips
5. Integration guidance
6. Troubleshooting information
7. Performance considerations

Create production-ready, comprehensive documentation.
"@
        }
        
        default {
            return $basePrompt + "Generate appropriate documentation for this PowerShell code."
        }
    }
}

function Invoke-OllamaRetry {
    <#
    .SYNOPSIS
    Executes Ollama requests with comprehensive retry logic
    
    .DESCRIPTION
    Handles Ollama API requests with exponential backoff, error handling, and performance monitoring
    
    .PARAMETER Prompt
    AI prompt to send to Ollama
    
    .PARAMETER Model
    Model to use for generation
    
    .EXAMPLE
    Invoke-OllamaRetry -Prompt $prompt -Model "codellama:34b"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$Model = $script:OllamaConfig.DefaultModel
    )
    
    Write-Host "[OllamaRetry] Executing request with retry logic..." -ForegroundColor Gray
    Write-Host "[OllamaRetry] Model: $Model, Timeout: $($script:OllamaConfig.RequestTimeout)s, Max Attempts: $($script:OllamaConfig.MaxRetries)" -ForegroundColor Gray
    
    # Preload model if not already done
    if (-not $script:OllamaConfig.ModelPreloaded) {
        Write-Host "[OllamaRetry] Model not preloaded, attempting preload..." -ForegroundColor Yellow
        $preloadResult = Start-ModelPreloading -Model $Model
        if (-not $preloadResult.Success) {
            Write-Host "[OllamaRetry] WARNING: Model preloading failed, proceeding with request" -ForegroundColor Yellow
        }
    }
    
    $attempt = 0
    $maxAttempts = $script:OllamaConfig.MaxRetries
    $startTime = Get-Date
    
    while ($attempt -lt $maxAttempts) {
        try {
            $attempt++
            $attemptStartTime = Get-Date
            Write-Host "[OllamaRetry] Attempt $attempt/$maxAttempts starting at $($attemptStartTime.ToString('HH:mm:ss.fff'))" -ForegroundColor Gray
            
            # Prepare request with comprehensive debugging
            $requestBody = @{
                model = $Model
                prompt = $Prompt
                options = @{
                    num_ctx = $script:OllamaConfig.ContextWindow
                }
                stream = $false
                keep_alive = $script:OllamaConfig.KeepAlive
            } | ConvertTo-Json -Depth 5
            
            Write-Host "[OllamaRetry] Request body size: $($requestBody.Length) characters" -ForegroundColor Gray
            Write-Host "[OllamaRetry] Prompt length: $($Prompt.Length) characters" -ForegroundColor Gray
            Write-Host "[OllamaRetry] Sending request to: $($script:OllamaConfig.BaseUrl)/api/generate" -ForegroundColor Gray
            
            # Execute request with timeout and DisableKeepAlive fixes
            $response = Invoke-RestMethod -Uri "$($script:OllamaConfig.BaseUrl)/api/generate" `
                                          -Method POST `
                                          -Body $requestBody `
                                          -ContentType "application/json" `
                                          -TimeoutSec $script:OllamaConfig.RequestTimeout `
                                          -DisableKeepAlive
            
            # Calculate performance metrics with comprehensive debugging
            $duration = (Get-Date) - $startTime
            $attemptDuration = (Get-Date) - $attemptStartTime
            
            Write-Host "[OllamaRetry] SUCCESS - Request completed successfully" -ForegroundColor Green
            Write-Host "[OllamaRetry] Total duration: $($duration.TotalSeconds)s, Attempt duration: $($attemptDuration.TotalSeconds)s" -ForegroundColor Gray
            Write-Host "[OllamaRetry] Response length: $($response.response.Length) characters" -ForegroundColor Gray
            Write-Host "[OllamaRetry] Model used: $($response.model)" -ForegroundColor Gray
            
            $script:OllamaMetrics.RequestCount++
            $script:OllamaMetrics.SuccessCount++
            $script:OllamaMetrics.LastRequestTime = $duration.TotalMilliseconds
            
            # Update average response time
            if ($script:OllamaMetrics.RequestCount -gt 0) {
                $script:OllamaMetrics.AverageResponseTime = (
                    ($script:OllamaMetrics.AverageResponseTime * ($script:OllamaMetrics.RequestCount - 1)) + 
                    $duration.TotalMilliseconds
                ) / $script:OllamaMetrics.RequestCount
            }
            
            Write-Host "[OllamaRetry] Request completed in $($duration.TotalMilliseconds)ms" -ForegroundColor Green
            
            return $response.response
        }
        catch {
            $attemptDuration = (Get-Date) - $attemptStartTime
            Write-Host "[OllamaRetry] FAILURE - Attempt $attempt failed after $($attemptDuration.TotalSeconds)s" -ForegroundColor Red
            Write-Host "[OllamaRetry] Error type: $($_.Exception.GetType().Name)" -ForegroundColor Red
            Write-Host "[OllamaRetry] Error message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "[OllamaRetry] Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
            
            # Comprehensive error classification for debugging
            $errorMessage = $_.Exception.Message
            $isRetryable = $false
            $errorCategory = "Unknown"
            
            if ($errorMessage -match "timed out|Timeout|aborted.*timeout") {
                $isRetryable = $true
                $errorCategory = "Timeout"
                Write-Host "[OllamaRetry] TIMEOUT DETECTED - Request exceeded $($script:OllamaConfig.RequestTimeout)s limit" -ForegroundColor Red
            }
            elseif ($errorMessage -match "503|Service Unavailable") {
                $isRetryable = $true  
                $errorCategory = "ServiceUnavailable"
                Write-Host "[OllamaRetry] SERVICE UNAVAILABLE - Ollama server overloaded" -ForegroundColor Red
            }
            elseif ($errorMessage -match "502|Bad Gateway") {
                $isRetryable = $true
                $errorCategory = "BadGateway"  
                Write-Host "[OllamaRetry] BAD GATEWAY - Network infrastructure issue" -ForegroundColor Red
            }
            elseif ($errorMessage -match "Connection.*refused|Connection.*reset") {
                $isRetryable = $true
                $errorCategory = "Connection"
                Write-Host "[OllamaRetry] CONNECTION ISSUE - Network connectivity problem" -ForegroundColor Red
            }
            else {
                $isRetryable = $false
                $errorCategory = "NonRetryable"
                Write-Host "[OllamaRetry] NON-RETRYABLE ERROR - $errorMessage" -ForegroundColor Red
            }
            
            Write-Host "[OllamaRetry] Error category: $errorCategory, Retryable: $isRetryable" -ForegroundColor Gray
            
            # Check if we should retry
            if ($attempt -lt $maxAttempts -and $isRetryable) {
                $delay = $script:OllamaConfig.RetryDelay * $attempt
                Write-Host "[OllamaRetry] RETRYING - Attempt $attempt/$maxAttempts failed, waiting $delay seconds before retry" -ForegroundColor Yellow
                Write-Host "[OllamaRetry] Retry strategy: Exponential backoff for $errorCategory error" -ForegroundColor Gray
                Start-Sleep -Seconds $delay
            } elseif (-not $isRetryable) {
                # Non-retryable error
                Write-Host "[OllamaRetry] ABORTING - Non-retryable $errorCategory error encountered" -ForegroundColor Red
                Write-Error "[OllamaRetry] Non-retryable error: $($_.Exception.Message)"
                $script:OllamaMetrics.ErrorCount++
                break
            } else {
                # Max retries exceeded
                Write-Host "[OllamaRetry] EXHAUSTED - Max retries ($maxAttempts) exceeded for $errorCategory error" -ForegroundColor Red
                Write-Error "[OllamaRetry] Max retries exceeded: $($_.Exception.Message)"
                $script:OllamaMetrics.ErrorCount++
                break
            }
        }
    }
    
    return $null
}

function Get-OllamaPerformanceMetrics {
    <#
    .SYNOPSIS
    Retrieves Ollama integration performance metrics
    
    .DESCRIPTION
    Provides detailed performance statistics for monitoring and optimization
    
    .EXAMPLE
    Get-OllamaPerformanceMetrics
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[OllamaMetrics] Current performance metrics:" -ForegroundColor Cyan
    Write-Host "  Total Requests: $($script:OllamaMetrics.RequestCount)" -ForegroundColor Gray
    Write-Host "  Successful: $($script:OllamaMetrics.SuccessCount)" -ForegroundColor Green
    Write-Host "  Errors: $($script:OllamaMetrics.ErrorCount)" -ForegroundColor Red
    Write-Host "  Success Rate: $(if ($script:OllamaMetrics.RequestCount -gt 0) { [math]::Round(($script:OllamaMetrics.SuccessCount / $script:OllamaMetrics.RequestCount) * 100, 2) } else { 0 })%" -ForegroundColor White
    Write-Host "  Average Response Time: $([math]::Round($script:OllamaMetrics.AverageResponseTime, 2))ms" -ForegroundColor Gray
    Write-Host "  Last Request: $($script:OllamaMetrics.LastRequestTime)ms" -ForegroundColor Gray
    
    return $script:OllamaMetrics
}

function Export-OllamaConfiguration {
    <#
    .SYNOPSIS
    Exports current Ollama configuration for backup or sharing
    
    .DESCRIPTION
    Saves current configuration, metrics, and connection state to JSON file
    
    .PARAMETER Path
    Output path for configuration file
    
    .EXAMPLE
    Export-OllamaConfiguration -Path "ollama-config.json"
    #>
    [CmdletBinding()]
    param(
        [string]$Path = "ollama-configuration-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    )
    
    Write-Host "[OllamaExport] Exporting configuration to: $Path" -ForegroundColor Cyan
    
    try {
        $exportData = @{
            Configuration = $script:OllamaConfig
            Metrics = $script:OllamaMetrics  
            Connection = $script:OllamaConnection
            ExportDate = Get-Date
            ModuleVersion = "1.0.0"
        }
        
        $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $Path -Encoding UTF8
        
        Write-Host "[OllamaExport] Configuration exported successfully" -ForegroundColor Green
        return @{ Success = $true; Path = $Path }
    }
    catch {
        Write-Error "[OllamaExport] Error exporting configuration: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

#endregion

#region Module Exports

# Export all public functions
Export-ModuleMember -Function @(
    'Start-OllamaService',
    'Stop-OllamaService', 
    'Test-OllamaConnectivity',
    'Get-OllamaModelInfo',
    'Set-OllamaConfiguration',
    'Invoke-OllamaDocumentation',
    'Invoke-OllamaCodeAnalysis',
    'Invoke-OllamaExplanation',
    'Start-ModelPreloading',
    'Format-DocumentationPrompt',
    'Invoke-OllamaRetry',
    'Get-OllamaPerformanceMetrics',
    'Export-OllamaConfiguration'
)

Write-Host "[Unity-Claude-Ollama] Module loaded successfully - 13 functions for AI-enhanced documentation" -ForegroundColor Green
Write-Host "[Unity-Claude-Ollama] Local AI integration ready - CodeLlama support operational" -ForegroundColor Green

#endregion
