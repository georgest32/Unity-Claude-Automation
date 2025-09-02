#
# Unity-Claude-LLM.psm1
# Local LLM integration module for Unity-Claude-Automation using Ollama
# Provides documentation generation and code analysis capabilities
#

# Module configuration
$script:DefaultLLMConfig = @{
    Model = 'codellama:34b'
    BaseUrl = 'http://localhost:11434'
    Timeout = 120
    MaxRetries = 3
    RetryDelay = 5
    Stream = $false
    Temperature = 0.3
    MaxTokens = 4096
}

$script:LLMConfig = $script:DefaultLLMConfig.Clone()

#
# Core Ollama interaction functions
#

function Test-OllamaConnection {
    [CmdletBinding()]
    param(
        [string]$BaseUrl = $script:LLMConfig.BaseUrl
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/tags" -Method Get -TimeoutSec 10
        return @{
            Available = $true
            Models = $response.models
            Message = "Connected to Ollama at $BaseUrl"
        }
    }
    catch {
        return @{
            Available = $false
            Models = @()
            Message = "Failed to connect to Ollama: $($_.Exception.Message)"
        }
    }
}

function Get-OllamaModels {
    [CmdletBinding()]
    param(
        [string]$BaseUrl = $script:LLMConfig.BaseUrl
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/tags" -Method Get -TimeoutSec 10
        return $response.models | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.name
                Size = $_.size
                ModifiedAt = $_.modified_at
                Digest = $_.digest
            }
        }
    }
    catch {
        Write-Error "Failed to get Ollama models: $($_.Exception.Message)"
        return @()
    }
}

function Invoke-OllamaGenerate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$Model = $script:LLMConfig.Model,
        [string]$BaseUrl = $script:LLMConfig.BaseUrl,
        [double]$Temperature = $script:LLMConfig.Temperature,
        [int]$MaxTokens = $script:LLMConfig.MaxTokens,
        [bool]$Stream = $script:LLMConfig.Stream,
        [int]$TimeoutSec = $script:LLMConfig.Timeout
    )
    
    $requestBody = @{
        model = $Model
        prompt = $Prompt
        stream = $Stream
        options = @{
            temperature = $Temperature
            num_predict = $MaxTokens
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/generate" -Method Post -Body $requestBody -ContentType 'application/json' -TimeoutSec $TimeoutSec
        
        return [PSCustomObject]@{
            Success = $true
            Response = $response.response
            Model = $response.model
            Done = $response.done
            TotalDuration = $response.total_duration
            LoadDuration = $response.load_duration
            PromptEvalCount = $response.prompt_eval_count
            PromptEvalDuration = $response.prompt_eval_duration
            EvalCount = $response.eval_count
            EvalDuration = $response.eval_duration
        }
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Response = ""
            Error = $_.Exception.Message
        }
    }
}

#
# Documentation generation functions
#

function New-DocumentationPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Function', 'Module', 'Class', 'Script', 'API', 'Architecture')]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Code,
        
        [string]$Context = "",
        [string]$ExistingDocs = "",
        [string[]]$Requirements = @()
    )
    
    $basePrompt = @"
You are a technical documentation expert. Generate comprehensive, accurate documentation for the provided $Type.

Requirements:
- Use clear, professional language
- Include practical examples where applicable
- Follow PowerShell documentation conventions
- Be concise but thorough
- Include parameter descriptions and return values
- Add usage examples
"@

    if ($Requirements.Count -gt 0) {
        $basePrompt += "`n- " + ($Requirements -join "`n- ")
    }

    $codeSection = @"

CODE TO DOCUMENT:
```powershell
$Code
```
"@

    if ($Context) {
        $contextSection = "`n`nCONTEXT:`n$Context"
    } else {
        $contextSection = ""
    }

    if ($ExistingDocs) {
        $existingSection = "`n`nEXISTING DOCUMENTATION (to enhance/update):`n$ExistingDocs"
    } else {
        $existingSection = ""
    }

    $finalPrompt = $basePrompt + $codeSection + $contextSection + $existingSection + "`n`nGenerate the documentation:"

    return $finalPrompt
}

function Invoke-DocumentationGeneration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [ValidateSet('Function', 'Module', 'Class', 'Script', 'API', 'Architecture')]
        [string]$Type = 'Script',
        
        [string]$OutputPath,
        [string]$Context = "",
        [string[]]$Requirements = @(),
        [switch]$UpdateExisting
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }
    
    $code = Get-Content $FilePath -Raw
    $existingDocs = ""
    
    if ($UpdateExisting -and $OutputPath -and (Test-Path $OutputPath)) {
        $existingDocs = Get-Content $OutputPath -Raw
    }
    
    $prompt = New-DocumentationPrompt -Type $Type -Code $code -Context $Context -ExistingDocs $existingDocs -Requirements $Requirements
    
    Write-Verbose "Generating documentation for $FilePath using LLM..."
    $result = Invoke-OllamaGenerate -Prompt $prompt
    
    if ($result.Success) {
        $documentation = @{
            GeneratedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            SourceFile = $FilePath
            Type = $Type
            Model = $script:LLMConfig.Model
            Content = $result.Response
            Metrics = @{
                TotalDurationMs = [math]::Round($result.TotalDuration / 1000000, 2)
                EvaluationCount = $result.EvalCount
                PromptTokens = $result.PromptEvalCount
            }
        }
        
        if ($OutputPath) {
            $documentation.Content | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "Documentation generated: $OutputPath" -ForegroundColor Green
        }
        
        return $documentation
    }
    else {
        Write-Error "Documentation generation failed: $($result.Error)"
        return $null
    }
}

#
# Code analysis functions
#

function New-CodeAnalysisPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Quality', 'Security', 'Performance', 'Architecture', 'Maintainability', 'Complexity')]
        [string]$AnalysisType,
        
        [Parameter(Mandatory=$true)]
        [string]$Code,
        
        [string]$Context = "",
        [string[]]$FocusAreas = @()
    )
    
    $analysisPrompts = @{
        'Quality' = @"
Analyze the code quality of this PowerShell code. Focus on:
- Code structure and organization
- Naming conventions
- Error handling practices
- Input validation
- Code reusability
- Best practices adherence
"@
        'Security' = @"
Perform a security analysis of this PowerShell code. Look for:
- Potential security vulnerabilities
- Unsafe operations or commands
- Input sanitization issues
- Credential handling problems
- File system security risks
- Execution policy considerations
"@
        'Performance' = @"
Analyze the performance characteristics of this PowerShell code. Examine:
- Algorithmic efficiency
- Memory usage patterns
- I/O operations optimization
- Loop efficiency
- Pipeline usage
- Potential bottlenecks
"@
        'Architecture' = @"
Review the architectural design of this PowerShell code. Consider:
- Module structure and dependencies
- Separation of concerns
- Code organization patterns
- Interface design
- Extensibility and maintainability
- Design pattern usage
"@
        'Maintainability' = @"
Evaluate the maintainability of this PowerShell code. Assess:
- Code readability and clarity
- Documentation quality
- Modular design
- Testing considerations
- Change impact analysis
- Technical debt indicators
"@
        'Complexity' = @"
Analyze the complexity of this PowerShell code. Measure:
- Cyclomatic complexity
- Cognitive load
- Nesting levels
- Function length and responsibility
- Parameter complexity
- Control flow complexity
"@
    }
    
    $basePrompt = $analysisPrompts[$AnalysisType]
    
    if ($FocusAreas.Count -gt 0) {
        $basePrompt += "`n`nPay special attention to: " + ($FocusAreas -join ", ")
    }
    
    $codeSection = @"

CODE TO ANALYZE:
```powershell
$Code
```
"@
    
    if ($Context) {
        $contextSection = "`n`nCONTEXT:`n$Context"
    } else {
        $contextSection = ""
    }
    
    $instructionSection = @"

Provide a detailed analysis with:
1. Executive summary
2. Specific findings with line references
3. Recommendations for improvement
4. Risk assessment (High/Medium/Low)
5. Actionable next steps
"@
    
    return $basePrompt + $codeSection + $contextSection + $instructionSection
}

function Invoke-CodeAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [ValidateSet('Quality', 'Security', 'Performance', 'Architecture', 'Maintainability', 'Complexity')]
        [string[]]$AnalysisTypes = @('Quality'),
        
        [string]$OutputPath,
        [string]$Context = "",
        [string[]]$FocusAreas = @()
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }
    
    $code = Get-Content $FilePath -Raw
    $analysisResults = @{
        AnalyzedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SourceFile = $FilePath
        Model = $script:LLMConfig.Model
        Analyses = @{}
    }
    
    foreach ($analysisType in $AnalysisTypes) {
        Write-Verbose "Performing $analysisType analysis on $FilePath..."
        
        $prompt = New-CodeAnalysisPrompt -AnalysisType $analysisType -Code $code -Context $Context -FocusAreas $FocusAreas
        $result = Invoke-OllamaGenerate -Prompt $prompt
        
        if ($result.Success) {
            $analysisResults.Analyses[$analysisType] = @{
                Content = $result.Response
                Metrics = @{
                    TotalDurationMs = [math]::Round($result.TotalDuration / 1000000, 2)
                    EvaluationCount = $result.EvalCount
                    PromptTokens = $result.PromptEvalCount
                }
            }
            Write-Host "$analysisType analysis completed" -ForegroundColor Green
        }
        else {
            Write-Warning "$analysisType analysis failed: $($result.Error)"
            $analysisResults.Analyses[$analysisType] = @{
                Content = "Analysis failed: $($result.Error)"
                Error = $result.Error
            }
        }
    }
    
    if ($OutputPath) {
        $analysisResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "Analysis results saved: $OutputPath" -ForegroundColor Green
    }
    
    return $analysisResults
}

#
# Configuration management functions
#

function Get-LLMConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:LLMConfig.Clone()
}

function Set-LLMConfiguration {
    [CmdletBinding()]
    param(
        [string]$Model,
        [string]$BaseUrl,
        [int]$Timeout,
        [int]$MaxRetries,
        [int]$RetryDelay,
        [bool]$Stream,
        [double]$Temperature,
        [int]$MaxTokens
    )
    
    if ($Model) { $script:LLMConfig.Model = $Model }
    if ($BaseUrl) { $script:LLMConfig.BaseUrl = $BaseUrl }
    if ($Timeout) { $script:LLMConfig.Timeout = $Timeout }
    if ($MaxRetries) { $script:LLMConfig.MaxRetries = $MaxRetries }
    if ($RetryDelay) { $script:LLMConfig.RetryDelay = $RetryDelay }
    if ($PSBoundParameters.ContainsKey('Stream')) { $script:LLMConfig.Stream = $Stream }
    if ($Temperature) { $script:LLMConfig.Temperature = $Temperature }
    if ($MaxTokens) { $script:LLMConfig.MaxTokens = $MaxTokens }
    
    Write-Host "LLM configuration updated" -ForegroundColor Green
}

function Test-LLMAvailability {
    [CmdletBinding()]
    param()
    
    Write-Host "Testing LLM availability..." -ForegroundColor Cyan
    
    $connectionTest = Test-OllamaConnection
    
    if ($connectionTest.Available) {
        Write-Host "[PASS] Ollama connection successful" -ForegroundColor Green
        Write-Host "  Available models: $($connectionTest.Models.Count)" -ForegroundColor Gray
        
        # Test generation with small prompt
        $testResult = Invoke-OllamaGenerate -Prompt "Hello, respond with just 'Test successful'" -MaxTokens 10
        
        if ($testResult.Success) {
            Write-Host "[PASS] LLM generation test successful" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[FAIL] LLM generation test failed: $($testResult.Error)" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "[FAIL] Ollama connection failed: $($connectionTest.Message)" -ForegroundColor Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-OllamaGenerate',
    'Get-OllamaModels',
    'Test-OllamaConnection',
    'New-DocumentationPrompt',
    'Invoke-DocumentationGeneration',
    'New-CodeAnalysisPrompt',
    'Invoke-CodeAnalysis',
    'Get-LLMConfiguration',
    'Set-LLMConfiguration',
    'Test-LLMAvailability'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBU/e2tpP1XxTah
# s6pySjreeDmxfd3tgaR+8e9/JIhCPKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFJTjkpHFHIkMV5ElOiiyqZn
# yVQpXqNKIyFJOyMUOP7bMA0GCSqGSIb3DQEBAQUABIIBAJy5U968bVWI2Htyttm1
# oDXIOEpWOFeGrr7wLkr/vCNlfbMNAPLkyjQTetYocSqVU9CX6Jp5QIlXFfaSgXMz
# B6PFE3rOP8GDaH8vGXhY27pIxlnPUsvMWV6oSIFf4DlGr7v/5OkBk46lAgI4C9vH
# V+qhgyJ4iS2L1Nl1FHAVmfjhesWcT5NuaN6r5fLAaFTSMY9gonsF6FjK2nvxeO94
# yYjD3rl08G2HrjsQtTR9jCMKxyDjT6my9xYMij+o/+QLWsgIjVMf/NqbMaQQIawG
# /DmAbZJ2WQmtWHWWzI/8RvKS3w/w9GUEQsH80w8FsMvfgVS8vqgYTO/KoXdAGnig
# qb8=
# SIG # End signature block

