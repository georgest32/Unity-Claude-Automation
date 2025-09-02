function Invoke-StaticAnalysis {
    <#
    .SYNOPSIS
    Unified static analysis function supporting multiple linters and security scanners
    
    .DESCRIPTION
    Orchestrates static analysis across multiple tools (ESLint, Pylint, PSScriptAnalyzer, 
    Bandit, Semgrep) with unified configuration, SARIF-compliant output, and performance optimization
    
    .PARAMETER Path
    Path to analyze (file or directory)
    
    .PARAMETER Linters
    Array of linters to run. Options: ESLint, Pylint, PSScriptAnalyzer, Bandit, Semgrep, All
    
    .PARAMETER ConfigPath
    Path to configuration file (PSD1, JSON, or YAML)
    
    .PARAMETER OutputFormat
    Output format: SARIF, JSON, HTML
    
    .PARAMETER ParallelExecution
    Enable parallel execution of linters for performance
    
    .PARAMETER ThrottleLimit
    Maximum concurrent linter processes (default: 4)
    
    .PARAMETER ExcludePatterns
    Array of glob patterns to exclude from analysis
    
    .PARAMETER Severity
    Minimum severity level: Info, Warning, Error
    
    .EXAMPLE
    Invoke-StaticAnalysis -Path "src/" -Linters @("ESLint", "PSScriptAnalyzer") -OutputFormat SARIF
    
    .EXAMPLE
    Invoke-StaticAnalysis -Path . -Linters All -ParallelExecution -ConfigPath "StaticAnalysisConfig.psd1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet('ESLint', 'Pylint', 'PSScriptAnalyzer', 'Bandit', 'Semgrep', 'All')]
        [string[]]$Linters = @('All'),
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [ValidateSet('SARIF', 'JSON', 'HTML')]
        [string]$OutputFormat = 'SARIF',
        
        [Parameter()]
        [switch]$ParallelExecution,
        
        [Parameter()]
        [int]$ThrottleLimit = 4,
        
        [Parameter()]
        [string[]]$ExcludePatterns = @(),
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Severity = 'Warning'
    )
    
    begin {
        Write-Verbose "Starting static analysis for path: $Path"
        
        # Load configuration if provided
        $config = @{}
        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            try {
                $config = Import-PowerShellDataFile -Path $ConfigPath
                Write-Verbose "Loaded configuration from: $ConfigPath"
            } catch {
                Write-Warning "Failed to load configuration from $ConfigPath : $_"
            }
        }
        
        # Expand 'All' linters to specific list
        if ($Linters -contains 'All') {
            $Linters = @('ESLint', 'Pylint', 'PSScriptAnalyzer', 'Bandit', 'Semgrep')
        }
        
        # Initialize result structure (SARIF 2.1.0 compatible)
        $sarifResult = [PSCustomObject]@{
            '$schema' = 'https://json.schemastore.org/sarif-2.1.0.json'
            version = '2.1.0'
            runs = @()
        }
        
        # Performance tracking
        $analysisStartTime = Get-Date
        $linterResults = [System.Collections.ArrayList]::new()
    }
    
    process {
        try {
            Write-Verbose "Executing $($Linters.Count) linters with parallel execution: $ParallelExecution"
            
            # Create linter execution tasks
            $linterTasks = @()
            
            foreach ($linter in $Linters) {
                $linterTasks += [PSCustomObject]@{
                    Name = $linter
                    Path = $Path
                    Config = $config
                    ExcludePatterns = $ExcludePatterns
                    Severity = $Severity
                }
            }
            
            # Execute linters (parallel or sequential)
            if ($ParallelExecution -and $PSVersionTable.PSVersion.Major -ge 7) {
                # Use ForEach-Object -Parallel for PowerShell 7+
                Write-Verbose "Using ForEach-Object -Parallel execution"
                
                $results = $linterTasks | ForEach-Object -Parallel {
                    $task = $_
                    $linterName = $task.Name
                    
                    # Import required module in parallel scope
                    Import-Module "Unity-Claude-RepoAnalyst" -Force
                    
                    try {
                        switch ($linterName) {
                            'ESLint' { 
                                if (Get-Command 'eslint' -ErrorAction SilentlyContinue) {
                                    Invoke-ESLintAnalysis -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "ESLint not found in PATH"
                                    $null
                                }
                            }
                            'Pylint' { 
                                if (Get-Command 'pylint' -ErrorAction SilentlyContinue) {
                                    Invoke-PylintAnalysis -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "Pylint not found in PATH"
                                    $null
                                }
                            }
                            'PSScriptAnalyzer' {
                                Invoke-PSScriptAnalyzerEnhanced -Path $task.Path -Config $task.Config
                            }
                            'Bandit' {
                                if (Get-Command 'bandit' -ErrorAction SilentlyContinue) {
                                    Invoke-BanditScan -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "Bandit not found in PATH"
                                    $null
                                }
                            }
                            'Semgrep' {
                                if (Get-Command 'semgrep' -ErrorAction SilentlyContinue) {
                                    Invoke-SemgrepScan -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "Semgrep not found in PATH" 
                                    $null
                                }
                            }
                        }
                    } catch {
                        Write-Error "Failed to execute $linterName : $_"
                        $null
                    }
                } -ThrottleLimit $ThrottleLimit
                
                # Filter out null results
                $results = $results | Where-Object { $_ -ne $null }
                
            } else {
                # Sequential execution for PowerShell 5.1 compatibility
                Write-Verbose "Using sequential execution"
                
                $results = foreach ($task in $linterTasks) {
                    $linterName = $task.Name
                    Write-Verbose "Executing linter: $linterName"
                    
                    try {
                        switch ($linterName) {
                            'ESLint' { 
                                if (Get-Command 'eslint' -ErrorAction SilentlyContinue) {
                                    Invoke-ESLintAnalysis -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "ESLint not found in PATH"
                                }
                            }
                            'Pylint' { 
                                if (Get-Command 'pylint' -ErrorAction SilentlyContinue) {
                                    Invoke-PylintAnalysis -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "Pylint not found in PATH"
                                }
                            }
                            'PSScriptAnalyzer' {
                                Invoke-PSScriptAnalyzerEnhanced -Path $task.Path -Config $task.Config
                            }
                            'Bandit' {
                                if (Get-Command 'bandit' -ErrorAction SilentlyContinue) {
                                    Invoke-BanditScan -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "Bandit not found in PATH"
                                }
                            }
                            'Semgrep' {
                                if (Get-Command 'semgrep' -ErrorAction SilentlyContinue) {
                                    Invoke-SemgrepScan -Path $task.Path -Config $task.Config
                                } else {
                                    Write-Warning "Semgrep not found in PATH"
                                }
                            }
                        }
                    } catch {
                        Write-Error "Failed to execute $linterName : $_"
                    }
                }
                
                # Filter out null/empty results
                $results = $results | Where-Object { $_ -ne $null }
            }
            
            # Aggregate results into SARIF format
            if ($results) {
                foreach ($result in $results) {
                    if ($result.runs) {
                        $sarifResult.runs += $result.runs
                    }
                }
            }
            
            # Calculate performance metrics
            $analysisEndTime = Get-Date
            $executionTime = ($analysisEndTime - $analysisStartTime).TotalSeconds
            
            Write-Verbose "Static analysis completed in $executionTime seconds"
            
            # Add metadata to SARIF result
            if ($sarifResult.runs.Count -eq 0) {
                # Create empty run if no results
                $sarifResult.runs = @([PSCustomObject]@{
                    tool = [PSCustomObject]@{
                        driver = [PSCustomObject]@{
                            name = 'Unity-Claude-RepoAnalyst'
                            version = '1.0.0'
                        }
                    }
                    results = @()
                })
            }
            
            # Add execution metadata
            $sarifResult | Add-Member -NotePropertyName 'executionMetrics' -NotePropertyValue ([PSCustomObject]@{
                executionTimeSeconds = $executionTime
                lintersExecuted = $Linters
                analysisTimestamp = $analysisStartTime.ToString('o')
                parallelExecution = $ParallelExecution
                throttleLimit = $ThrottleLimit
            })
            
            # Return in requested format
            switch ($OutputFormat) {
                'SARIF' { return $sarifResult }
                'JSON' { return ($sarifResult | ConvertTo-Json -Depth 10) }
                'HTML' { return (ConvertTo-AnalysisReport -SarifData $sarifResult) }
                default { return $sarifResult }
            }
            
        } catch {
            Write-Error "Static analysis failed: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Static analysis orchestration completed"
    }
}

function ConvertTo-AnalysisReport {
    <#
    .SYNOPSIS
    Converts SARIF data to HTML report format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SarifData
    )
    
    # Simple HTML report generation (placeholder for full implementation)
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Static Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; }
        .summary { margin: 20px 0; }
        .findings { margin: 20px 0; }
        .error { color: #d32f2f; }
        .warning { color: #f57c00; }
        .info { color: #1976d2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Static Analysis Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="summary">
        <h2>Summary</h2>
        <p>Total runs: $($SarifData.runs.Count)</p>
    </div>
</body>
</html>
"@
    
    return $html
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBVXZHBlgm/BY3T
# JWT41XeFbNtKNt80g+u23OSey3NMlqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPQ58fSaX7+KMVzULtWUlvjk
# gnFbbiTn99D/DshGgSCPMA0GCSqGSIb3DQEBAQUABIIBACV3sSzBBhY6b4xScUen
# ZQhAZN49niZin3SgfqNd6w/vdIyl94Wz52Jx2pklAuxGGZIlXE2/wxzRwLfXEVXE
# +WTXbLZm5H2oRQCSd/ppGa0uERBiQj2SjO8QRe2gzN/wBwHTFL5VDPMUmckSPwAs
# 3ZN3eUjzkLRpZz2IXAcKP2rI1ylXvQUmvot9sYiyMTo1cB0fMlNLNrr37ww8b8tG
# prMGFJEF417v4lhLLA3NC0Me+7Q9v95GC3789+1EGbI7/sBExLtQ0ubkn5ZGOiUl
# /2bRgpEYVSaatzXSYf51v/fg0LiBi77lAqsDdLnt3j8WE1hi7qdc6i7Zem+hH3qr
# ilg=
# SIG # End signature block
