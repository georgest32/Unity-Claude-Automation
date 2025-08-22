# Process-UnityErrorWithLearning-Clean.ps1
# Main integration script that connects Phase 1 (Core), Phase 2 (IPC/API), and Phase 3 (Learning)
# Date: 2025-08-17
# ASCII-only version to avoid encoding issues

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProjectPath = (Get-Location).Path,
    
    [Parameter()]
    [string]$UnityExe = 'C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe',
    
    [Parameter()]
    [switch]$UseAPI,
    
    [Parameter()]
    [string]$APIKey = $env:ANTHROPIC_API_KEY,
    
    [Parameter()]
    [switch]$AutoFix,
    
    [Parameter()]
    [switch]$EnableLearning = $true,
    
    [Parameter()]
    [int]$MinSimilarity = 65
)

$ErrorActionPreference = 'Stop'

Write-Host "`n=== Unity-Claude Automation with Learning System ===" -ForegroundColor Cyan
Write-Host "Version: 3.0 - Full Integration" -ForegroundColor Gray
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

#region Module Loading

Write-Host "`nInitializing modules..." -ForegroundColor Yellow

# Setup module paths
$modulePath = Join-Path $PSScriptRoot 'Modules'
$pathSeparator = [System.IO.Path]::PathSeparator
$paths = ($env:PSModulePath -split [regex]::Escape($pathSeparator)) | Where-Object { $_ }
$normalizedPath = [System.IO.Path]::GetFullPath($modulePath)

if (-not ($paths | ForEach-Object { [System.IO.Path]::GetFullPath($_) } | Where-Object { $_ -eq $normalizedPath })) {
    $env:PSModulePath = "$modulePath$pathSeparator$env:PSModulePath"
}

# Load required modules
$requiredModules = @('Unity-Claude-Learning-Simple')
if ($UseAPI) {
    $requiredModules += 'Unity-Claude-IPC'
}

$loadedModules = @()
foreach ($module in $requiredModules) {
    try {
        Import-Module $module -Force -ErrorAction Stop
        $loadedModules += $module
        Write-Host "  [OK] Loaded: $module" -ForegroundColor Green
    }
    catch {
        Write-Host "  [X] Failed to load: $module" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor DarkGray
    }
}

#endregion

#region Initialization

Write-Host "`nInitializing systems..." -ForegroundColor Yellow

# Initialize Learning system
if ($EnableLearning) {
    try {
        Initialize-LearningStorage | Out-Null
        $config = Get-LearningConfig
        $patternCount = 0
        
        if (Test-Path $config.PatternsFile) {
            $jsonContent = Get-Content $config.PatternsFile -Raw | ConvertFrom-Json
            $patternCount = ($jsonContent | Get-Member -MemberType NoteProperty).Count
        }
        
        Write-Host "  [OK] Learning system initialized ($patternCount patterns)" -ForegroundColor Green
    }
    catch {
        Write-Host "  [!] Learning system initialization failed (continuing without)" -ForegroundColor Yellow
        $EnableLearning = $false
    }
}

#endregion

#region Main Processing Function

function Process-UnityError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [Parameter()]
        [string]$ErrorType = "",
        
        [Parameter()]
        [string]$FilePath = "",
        
        [Parameter()]
        [int]$LineNumber = 0
    )
    
    Write-Host "`n--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Processing Error: $ErrorMessage" -ForegroundColor Yellow
    
    $fixApplied = $false
    $fixSource = "None"
    $suggestedFix = ""
    
    # Step 1: Try Learning System
    if ($EnableLearning) {
        Write-Host "  -> Checking pattern database..." -ForegroundColor Gray
        
        $fixes = Get-SuggestedFixes -ErrorMessage $ErrorMessage -MinSimilarity $MinSimilarity
        
        if ($fixes -and $fixes.Count -gt 0) {
            $bestFix = $fixes | Select-Object -First 1
            Write-Host "  [OK] Found pattern match!" -ForegroundColor Green
            Write-Host "    Pattern ID: $($bestFix.PatternId)" -ForegroundColor DarkGray
            Write-Host "    Similarity: $([Math]::Round($bestFix.Similarity, 2))%" -ForegroundColor DarkGray
            Write-Host "    Fix: $($bestFix.Fix)" -ForegroundColor Cyan
            
            $suggestedFix = $bestFix.Fix
            $fixSource = "Pattern"
            
            if ($AutoFix -and $FilePath) {
                Write-Host "  -> Attempting auto-fix..." -ForegroundColor Gray
                # Here you would apply the fix to the file
                # For safety, we'll just log it for now
                Write-Host "    [DRY RUN] Would apply fix to: $FilePath" -ForegroundColor DarkYellow
                $fixApplied = $false  # Set to true when actually applying
            }
        }
        else {
            Write-Host "  [X] No pattern match found" -ForegroundColor DarkGray
        }
    }
    
    # Step 2: If no pattern match, try Claude API
    if (-not $suggestedFix -and $UseAPI -and $APIKey) {
        Write-Host "  -> Consulting Claude API..." -ForegroundColor Gray
        
        try {
            # Prepare the prompt
            $prompt = @"
Unity compilation error in C# code:
Error: $ErrorMessage
$(if ($ErrorType) { "Type: $ErrorType" })
$(if ($FilePath) { "File: $FilePath" })
$(if ($LineNumber) { "Line: $LineNumber" })

Please provide a concise fix for this Unity compilation error. Return only the fix code or instruction, no explanation.
"@
            
            # Call Claude API (simplified for example)
            $headers = @{
                'x-api-key' = $APIKey
                'anthropic-version' = '2023-06-01'
                'content-type' = 'application/json'
            }
            
            $body = @{
                model = 'claude-3-haiku-20240307'
                max_tokens = 200
                messages = @(
                    @{
                        role = 'user'
                        content = $prompt
                    }
                )
            } | ConvertTo-Json
            
            Write-Verbose "Calling Claude API..."
            $response = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' `
                -Method Post -Headers $headers -Body $body
            
            if ($response.content) {
                $suggestedFix = $response.content[0].text
                Write-Host "  [OK] Claude provided solution!" -ForegroundColor Green
                Write-Host "    Fix: $suggestedFix" -ForegroundColor Cyan
                $fixSource = "Claude"
                
                # Learn from Claude's response
                if ($EnableLearning) {
                    Write-Host "  -> Learning from Claude's solution..." -ForegroundColor Gray
                    $patternId = Add-ErrorPattern -ErrorMessage $ErrorMessage `
                        -ErrorType $ErrorType -Fix $suggestedFix -Source "Claude"
                    Write-Host "    [OK] Pattern saved: $patternId" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Host "  [X] Claude API call failed: $_" -ForegroundColor Red
        }
    }
    
    # Step 3: Manual fallback
    if (-not $suggestedFix) {
        Write-Host "  [!] No automatic fix available" -ForegroundColor Yellow
        Write-Host "    Manual intervention required" -ForegroundColor DarkGray
        $fixSource = "Manual"
    }
    
    # Step 4: Update success metrics if fix was applied
    if ($fixApplied -and $EnableLearning -and $bestFix) {
        Update-FixSuccess -PatternId $bestFix.PatternId -Success $true
        Write-Host "  [OK] Pattern success rate updated" -ForegroundColor Green
    }
    
    return @{
        ErrorMessage = $ErrorMessage
        SuggestedFix = $suggestedFix
        FixSource = $fixSource
        FixApplied = $fixApplied
    }
}

#endregion

#region Error Detection and Processing

Write-Host "`nStarting error detection..." -ForegroundColor Yellow

# Get Unity compilation errors
$errors = @()

# Method 1: Run Export-UnityCompilationErrors.ps1 to get comprehensive error detection
$exportScript = Join-Path $PSScriptRoot 'Export-UnityCompilationErrors.ps1'
if (Test-Path $exportScript) {
    Write-Host "  Running comprehensive error detection..." -ForegroundColor Gray
    
    # Run the export script silently
    $exportResult = & $exportScript 2>$null
    
    # Check Unity Editor log with comprehensive patterns
    $editorLog = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'
    if (Test-Path $editorLog) {
        # Read entire log for better detection
        $logContent = Get-Content $editorLog -Raw
        
        # Use comprehensive pattern from Export-UnityCompilationErrors
        $pattern = '(?m)^(.+\.cs)\((\d+),(\d+)\): (error )?(CS\d{4}): (.+)$'
        $matches = [regex]::Matches($logContent, $pattern)
        
        $uniqueErrors = @{}
        foreach ($match in $matches) {
            $errorKey = $match.Value
            if (-not $uniqueErrors.ContainsKey($errorKey)) {
                $uniqueErrors[$errorKey] = $true
                if ($match.Value -match '(.+\.cs)\((\d+),(\d+)\): (?:error )?(CS\d{4}): (.+)') {
                    $errors += @{
                        FilePath = $Matches[1]
                        Line = [int]$Matches[2]
                        Column = [int]$Matches[3]
                        ErrorType = $Matches[4]
                        Message = $Matches[5]
                        FullLine = $match.Value
                    }
                }
            }
        }
    }
}

# Method 2: Check for exported error file
$errorFile = Join-Path $PSScriptRoot 'Logs\unity_errors_latest.txt'
if ((Test-Path $errorFile) -and $errors.Count -eq 0) {
    Write-Host "  Checking exported errors..." -ForegroundColor Gray
    
    $exportedErrors = Get-Content $errorFile
    $exportedErrors | ForEach-Object {
        if ($_ -match '^(.+): (.+)$') {
            $errors += @{
                ErrorType = $Matches[1]
                Message = $Matches[2]
                FullLine = $_
            }
        }
    }
}

Write-Host "  Found $($errors.Count) error(s)" -ForegroundColor $(if ($errors.Count -eq 0) { "Green" } else { "Yellow" })

#endregion

#region Process Errors

if ($errors.Count -gt 0) {
    Write-Host "`nProcessing errors..." -ForegroundColor Yellow
    
    $results = @()
    $fixedCount = 0
    $patternCount = 0
    $claudeCount = 0
    
    foreach ($error in $errors) {
        $result = Process-UnityError `
            -ErrorMessage $error.Message `
            -ErrorType $error.ErrorType `
            -FilePath $error.FilePath `
            -LineNumber $error.Line
        
        $results += $result
        
        if ($result.FixApplied) { $fixedCount++ }
        if ($result.FixSource -eq "Pattern") { $patternCount++ }
        if ($result.FixSource -eq "Claude") { $claudeCount++ }
    }
    
    # Summary
    Write-Host "`n--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Processing Complete!" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total Errors: $($errors.Count)" -ForegroundColor Gray
    Write-Host "  Fixed Automatically: $fixedCount" -ForegroundColor $(if ($fixedCount -gt 0) { "Green" } else { "Gray" })
    Write-Host "  Pattern Matches: $patternCount" -ForegroundColor $(if ($patternCount -gt 0) { "Green" } else { "Gray" })
    Write-Host "  Claude Solutions: $claudeCount" -ForegroundColor $(if ($claudeCount -gt 0) { "Green" } else { "Gray" })
    Write-Host "  Manual Required: $($errors.Count - $fixedCount)" -ForegroundColor $(if ($errors.Count - $fixedCount -gt 0) { "Yellow" } else { "Gray" })
    
    # Show learning metrics
    if ($EnableLearning) {
        $metrics = Get-LearningMetrics
        if ($metrics) {
            Write-Host "`nLearning Metrics:" -ForegroundColor Cyan
            Write-Host "  Total Patterns: $($metrics.TotalPatterns)" -ForegroundColor Gray
            Write-Host "  Success Rate: $([Math]::Round($metrics.OverallSuccessRate, 2))%" -ForegroundColor Gray
            Write-Host "  Patterns Used: $($metrics.PatternsUsed)" -ForegroundColor Gray
        }
    }
}
else {
    Write-Host "`n[OK] No errors detected!" -ForegroundColor Green
    Write-Host "Your Unity project compiled successfully." -ForegroundColor Gray
}

#endregion

Write-Host "`n=== Unity-Claude Automation Complete ===" -ForegroundColor Green
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/w1dlDrfJmAQ4m/NFxyffuQa
# mkOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU35etb7SFn2evW/N8vfIh2h4nBS0wDQYJKoZIhvcNAQEBBQAEggEAAjx/
# 2LlU/AdmHJh1pL3MHrodcBmXfirC+8K1+WUz/P8nE3ljubIV6LvSUM27KEiLzjpG
# yta3sQTdrpWeLduEdQ+jnW7C+F3WnyYW5VG7m5t5FnQdA7vWE4E3xhKArHB1hxL8
# nqbQ1mWjhY6ao1pNaDhqzhtPucSUnbIX6LrJTg4Zk2Y2zF0sDK/KWsJmsbmv97hb
# Qorbk1cApMPn5rXL7jWkpx20vVjWXF9i6tqW6nO4OyzUEmzaCBFgCB2RWrp1mGbX
# G8hyy4/4vzoTTPfeaceIgI/vRYL7ZMRH1b3cuH1pUFarA4KCuaVuonEligK2kFiY
# w8Cm2HS5JggwJ7XuIw==
# SIG # End signature block
