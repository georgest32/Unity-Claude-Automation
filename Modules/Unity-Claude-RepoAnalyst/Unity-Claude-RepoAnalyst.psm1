# Unity-Claude-RepoAnalyst Module
# Multi-agent repository analysis and documentation system

# Module initialization - Fix for $ModuleRoot issue
if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:ModuleName = "Unity-Claude-RepoAnalyst"
$script:ModuleRoot = $PSScriptRoot
$script:ConfigPath = Join-Path $script:ModuleRoot "Config"
$script:MCPServers = @{}
$script:AgentStatus = @{}
$script:PythonBridge = $null
$script:LogFile = $null

# Create required directories if they don't exist
$directories = @(
    $script:ConfigPath,
    (Join-Path $script:ModuleRoot "Public"),
    (Join-Path $script:ModuleRoot "Private"),
    (Join-Path $script:ModuleRoot "Logs")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Initialize logging
function Initialize-RepoAnalystLogging {
    [CmdletBinding()]
    param()
    
    $logPath = Join-Path $script:ModuleRoot "Logs"
    if (-not (Test-Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    
    $script:LogFile = Join-Path $logPath "RepoAnalyst_$(Get-Date -Format 'yyyyMMdd').log"
    
    Write-RepoAnalystLog "Unity-Claude-RepoAnalyst module initialized" -Level "INFO"
}

# Logging function
function Write-RepoAnalystLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color coding
    switch ($Level) {
        'DEBUG'   { Write-Host $logEntry -ForegroundColor Gray }
        'INFO'    { Write-Host $logEntry -ForegroundColor White }
        'WARNING' { Write-Host $logEntry -ForegroundColor Yellow }
        'ERROR'   { Write-Host $logEntry -ForegroundColor Red }
    }
    
    # Write to log file if initialized
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $logEntry -Encoding UTF8
    }
    
    # Also write to central Unity-Claude automation log
    $projectRoot = Split-Path (Split-Path $script:ModuleRoot -Parent) -Parent
    $centralLog = Join-Path $projectRoot "unity_claude_automation.log"
    if (Test-Path $projectRoot) {
        Add-Content -Path $centralLog -Value "[$script:ModuleName] $logEntry" -Encoding UTF8
    }
}

# Main initialization function
function Initialize-RepoAnalyst {
    [CmdletBinding()]
    param()
    
    Write-RepoAnalystLog "Initializing Unity-Claude-RepoAnalyst module" -Level "INFO"
    
    # Check for required tools
    $requiredTools = @{
        'ripgrep' = 'rg --version'
        'ctags' = 'ctags --version'
        'git' = 'git --version'
    }
    
    foreach ($tool in $requiredTools.GetEnumerator()) {
        try {
            $null = Invoke-Expression $tool.Value 2>&1
            Write-RepoAnalystLog "$($tool.Key) found and accessible" -Level "DEBUG"
        }
        catch {
            Write-RepoAnalystLog "$($tool.Key) not found. Please install using Install-RepoAnalystTools.ps1" -Level "WARNING"
        }
    }
    
    Write-RepoAnalystLog "Initialization complete" -Level "INFO"
}

# Ripgrep search wrapper
function Invoke-RipgrepSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter()]
        [string]$Path = ".",
        
        [Parameter()]
        [string]$FileType,
        
        [Parameter()]
        [switch]$CaseSensitive,
        
        [Parameter()]
        [switch]$FilesWithMatches
    )
    
    Write-RepoAnalystLog "Starting ripgrep search for pattern: $Pattern" -Level "DEBUG"
    
    $rgArgs = @()
    
    if ($CaseSensitive) {
        $rgArgs += "-s"
    } else {
        $rgArgs += "-i"
    }
    
    if ($FilesWithMatches) {
        $rgArgs += "-l"
    }
    
    if ($FileType) {
        $rgArgs += "-t", $FileType
    }
    
    $rgArgs += $Pattern, $Path
    
    try {
        $results = rg @rgArgs 2>&1
        Write-RepoAnalystLog "Ripgrep search completed successfully" -Level "DEBUG"
        return $results
    }
    catch {
        Write-RepoAnalystLog "Ripgrep search failed: $_" -Level "ERROR"
        throw
    }
}

# Code graph generation function
function New-CodeGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    Write-RepoAnalystLog "Generating code graph for: $ProjectPath" -Level "INFO"
    
    if (-not $OutputPath) {
        $OutputPath = Join-Path $ProjectPath ".ai\cache\codegraph.json"
    }
    
    # Ensure output directory exists
    $outputDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    $codeGraph = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        projectPath = $ProjectPath
        files = @()
        relationships = @()
    }
    
    # TODO: Implement actual code graph generation
    # This is a placeholder structure
    
    $codeGraph | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8
    
    Write-RepoAnalystLog "Code graph saved to: $OutputPath" -Level "INFO"
    
    return $OutputPath
}

# MCP Server management
function Start-MCPServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName,
        
        [Parameter()]
        [string]$ConfigPath
    )
    
    Write-RepoAnalystLog "Starting MCP server: $ServerName" -Level "INFO"
    
    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $script:ConfigPath "$ServerName.json"
    }
    
    if (-not (Test-Path $ConfigPath)) {
        Write-RepoAnalystLog "MCP server config not found: $ConfigPath" -Level "ERROR"
        throw "Configuration file not found"
    }
    
    # TODO: Implement actual MCP server startup
    $script:MCPServers[$ServerName] = @{
        Status = "Running"
        StartTime = Get-Date
        ConfigPath = $ConfigPath
    }
    
    Write-RepoAnalystLog "MCP server started: $ServerName" -Level "INFO"
    
    return $true
}

function Stop-MCPServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName
    )
    
    Write-RepoAnalystLog "Stopping MCP server: $ServerName" -Level "INFO"
    
    if ($script:MCPServers.ContainsKey($ServerName)) {
        $script:MCPServers[$ServerName].Status = "Stopped"
        Write-RepoAnalystLog "MCP server stopped: $ServerName" -Level "INFO"
        return $true
    }
    else {
        Write-RepoAnalystLog "MCP server not found: $ServerName" -Level "WARNING"
        return $false
    }
}

function Get-MCPServerStatus {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ServerName
    )
    
    if ($ServerName) {
        return $script:MCPServers[$ServerName]
    }
    else {
        return $script:MCPServers
    }
}

# Python bridge functions
function Start-PythonBridge {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PipeName = "UnityClaudeRepoPipe"
    )
    
    Write-RepoAnalystLog "Starting Python bridge with pipe: $PipeName" -Level "INFO"
    
    # TODO: Implement actual Python bridge startup
    $script:PythonBridge = @{
        Status = "Running"
        PipeName = $PipeName
        StartTime = Get-Date
    }
    
    Write-RepoAnalystLog "Python bridge started" -Level "INFO"
    
    return $true
}

function Invoke-PythonScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter()]
        [hashtable]$Arguments
    )
    
    Write-RepoAnalystLog "Invoking Python script: $ScriptPath" -Level "DEBUG"
    
    # TODO: Implement actual Python script invocation
    
    return @{
        Status = "Success"
        Result = "Placeholder result"
    }
}

function Get-PythonBridgeStatus {
    [CmdletBinding()]
    param()
    
    return $script:PythonBridge
}

# Placeholder functions for other exports
function Get-CtagsIndex { Write-RepoAnalystLog "Get-CtagsIndex not yet implemented" -Level "WARNING" }
function Get-PowerShellAST { Write-RepoAnalystLog "Get-PowerShellAST not yet implemented" -Level "WARNING" }
function New-DocumentationUpdate { Write-RepoAnalystLog "New-DocumentationUpdate not yet implemented" -Level "WARNING" }
function Test-DocumentationDrift { Write-RepoAnalystLog "Test-DocumentationDrift not yet implemented" -Level "WARNING" }
function Invoke-DocGeneration { Write-RepoAnalystLog "Invoke-DocGeneration not yet implemented" -Level "WARNING" }
function Invoke-MCPTool { Write-RepoAnalystLog "Invoke-MCPTool not yet implemented" -Level "WARNING" }
function Start-RepoAnalystAgent { Write-RepoAnalystLog "Start-RepoAnalystAgent not yet implemented" -Level "WARNING" }
function Get-AgentStatus { Write-RepoAnalystLog "Get-AgentStatus not yet implemented" -Level "WARNING" }
function Send-AgentMessage { Write-RepoAnalystLog "Send-AgentMessage not yet implemented" -Level "WARNING" }

# Import any existing function files
$Public = @(Get-ChildItem -Path "$script:ModuleRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$script:ModuleRoot\Private\*.ps1" -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
        Write-Verbose "Imported $($import.Name)"
    }
    catch {
        Write-Error "Failed to import $($import.FullName): $_"
    }
}

# Initialize module on load
Initialize-RepoAnalystLogging
Initialize-RepoAnalyst

# Export public functions
$functionsToExport = @(
    # Core functions
    'Initialize-RepoAnalyst',
    'Write-RepoAnalystLog',
    
    # Ripgrep functions
    'Invoke-RipgrepSearch',
    'Get-CodeChanges',
    'Search-CodePattern',
    
    # CTags functions
    'Get-CtagsIndex',
    'Read-CtagsIndex',
    'Find-Symbol',
    'Update-CtagsIndex',
    
    # AST functions
    'Get-PowerShellAST',
    'Get-FunctionDependencies',
    'Find-ASTPattern',
    
    # Code Graph functions
    'New-CodeGraph',
    'Update-CodeGraph',
    'Get-FileLanguage',
    
    # Documentation functions
    'New-DocumentationUpdate',
    'Test-DocumentationDrift',
    'Invoke-DocGeneration',
    
    # MCP Server functions
    'Start-MCPServer',
    'Stop-MCPServer',
    'Get-MCPServerStatus',
    'Invoke-MCPServerCommand',
    
    # Agent functions
    'Start-RepoAnalystAgent',
    'Get-AgentStatus',
    'Send-AgentMessage',
    
    # Python Bridge functions
    'Start-PythonBridge',
    'Invoke-PythonBridgeCommand',
    'Test-PythonBridge',
    'Stop-PythonBridge',
    'Invoke-PythonScript',
    'Get-PythonBridgeStatus',
    
    # Static Analysis Functions - Phase 2 Integration
    'Invoke-StaticAnalysis',
    'Invoke-ESLintAnalysis',
    'Invoke-PylintAnalysis',
    'Invoke-PSScriptAnalyzerEnhanced',
    'Invoke-BanditAnalysis',
    'Invoke-SemgrepAnalysis',
    'Merge-SarifResults',
    
    # Analysis Reporting Functions - Phase 2 Complete
    'New-AnalysisTrendReport',
    'New-AnalysisSummaryReport'
)

# Export variables
$variablesToExport = @('ASTPatterns')

# Export aliases
$aliasesToExport = @('mcp')

Export-ModuleMember -Function $functionsToExport -Variable $variablesToExport -Alias $aliasesToExport
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCZp7CEzCfnY+0R
# Bsd303IuoV7uR2OWY+9b3yzqtRO996CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINvN/as3pntsAf4v7qiLVNAl
# 31unWQagmLqumgl1W5cLMA0GCSqGSIb3DQEBAQUABIIBAK45EUezrwDnjgmwPH1i
# L2oajjDSb8fnjyS7WuJNndYfw6bG8WRT3Jbgf89s1XWXx28oB7PJGRpmc8VadgQz
# BD00Q+gHXN97LWD92714zCOeIVg887cJxjY0uqq/h0mzBei4OSZgymCk2gi7xQUi
# j6vmBwjl7seB+4nPh+v2xMs2EMlVV4igHAlk7PGPPk9HOjE4mtR/RaaetsvJ+rV7
# tihCzSz25+aVhX/W0J3g/4RVfiRJpifvMDWpSRpZ+uJlv+v5d5+0qatJTLDeUQcx
# hEurUOMi3FPZ/GCkWmr+S7kHN4Qw61oH4v/Ra9kLFx4b2tFgl4/dbYCrA/PqlUH9
# iRQ=
# SIG # End signature block
