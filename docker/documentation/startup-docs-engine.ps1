# Enhanced Documentation System - Documentation Engine Startup Script
# Phase 3 Day 5: Production Integration & Advanced Features
# Version: 2025-08-25

[CmdletBinding()]
param()

# Configure PowerShell for container environment
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = if ($env:LOG_LEVEL -eq 'Verbose') { 'Continue' } else { 'SilentlyContinue' }

# Logging function
function Write-DocEngineLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLevel = switch ($Level) {
        'Info' { 'INFO' }
        'Warning' { 'WARN' }
        'Error' { 'ERROR' }
        'Success' { 'SUCCESS' }
    }
    
    $logMessage = "[$timestamp] [$logLevel] DocEngine: $Message"
    Write-Host $logMessage
    
    # Also write to log file
    $logMessage | Out-File -FilePath '/docs/generated/docs-engine.log' -Append -Encoding UTF8
}

# Initialize documentation engine
function Initialize-DocumentationEngine {
    Write-DocEngineLog "Initializing Enhanced Documentation System..." -Level Info
    
    try {
        # Set up module path to include our modules
        $env:PSModulePath = "/app/modules;$env:PSModulePath"
        
        # Import core modules
        $coreModules = @(
            'Unity-Claude-CPG',
            'Unity-Claude-SemanticAnalysis', 
            'Unity-Claude-LLM',
            'Unity-Claude-Cache',
            'Unity-Claude-APIDocumentation',
            'Unity-Claude-CodeQL'
        )
        
        foreach ($module in $coreModules) {
            try {
                $modulePath = "/app/modules/$module/$module.psd1"
                if (Test-Path $modulePath) {
                    Import-Module $modulePath -Force -Global
                    Write-DocEngineLog "Successfully imported module: $module" -Level Success
                } else {
                    Write-DocEngineLog "Module manifest not found: $modulePath" -Level Warning
                }
            } catch {
                Write-DocEngineLog "Failed to import module ${module}: $_" -Level Error
                throw
            }
        }
        
        # Initialize documentation cache
        Write-DocEngineLog "Initializing documentation cache..." -Level Info
        if (Get-Command Initialize-CacheSystem -ErrorAction SilentlyContinue) {
            Initialize-CacheSystem -CachePath '/docs/cache' -MaxSize 1GB -DefaultTTL 3600
            Write-DocEngineLog "Cache system initialized successfully" -Level Success
        }
        
        # Initialize CodeQL if enabled
        if ($env:ENABLE_CODEQL -eq 'true') {
            Write-DocEngineLog "Initializing CodeQL integration..." -Level Info
            if (Get-Command Test-CodeQLInstallation -ErrorAction SilentlyContinue) {
                $codeqlStatus = Test-CodeQLInstallation
                if ($codeqlStatus.IsInstalled) {
                    Write-DocEngineLog "CodeQL CLI operational: $($codeqlStatus.Version)" -Level Success
                } else {
                    Write-DocEngineLog "CodeQL CLI not properly installed" -Level Warning
                }
            }
        }
        
        # Create initial health status
        $healthStatus = @{
            status = 'initializing'
            timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
            modules_loaded = (Get-Module Unity-Claude* | Measure-Object).Count
            cache_enabled = (Get-Command Initialize-CacheSystem -ErrorAction SilentlyContinue) -ne $null
            codeql_enabled = $env:ENABLE_CODEQL -eq 'true'
        }
        $healthStatus | ConvertTo-Json -Depth 3 | Out-File '/docs/generated/health.json' -Encoding UTF8
        
        Write-DocEngineLog "Documentation engine initialization complete" -Level Success
        return $true
        
    } catch {
        Write-DocEngineLog "Initialization failed: $_" -Level Error
        return $false
    }
}

# Main documentation generation loop
function Start-DocumentationLoop {
    Write-DocEngineLog "Starting documentation generation loop..." -Level Info
    
    $generationInterval = [int]($env:GENERATION_INTERVAL ?? 1800) # 30 minutes default
    $lastGeneration = [datetime]::MinValue
    
    while ($true) {
        try {
            $now = Get-Date
            
            # Check if it's time for a new generation cycle
            if (($now - $lastGeneration).TotalSeconds -ge $generationInterval) {
                Write-DocEngineLog "Starting documentation generation cycle..." -Level Info
                
                # Update health status
                $healthStatus = @{
                    status = 'generating'
                    timestamp = $now.ToString('yyyy-MM-ddTHH:mm:ss')
                    modules_loaded = (Get-Module Unity-Claude* | Measure-Object).Count
                    last_generation = $lastGeneration.ToString('yyyy-MM-ddTHH:mm:ss')
                    next_generation = $now.AddSeconds($generationInterval).ToString('yyyy-MM-ddTHH:mm:ss')
                }
                $healthStatus | ConvertTo-Json -Depth 3 | Out-File '/docs/generated/health.json' -Encoding UTF8
                
                # Generate documentation for all modules
                if (Get-Command New-ComprehensiveAPIDocs -ErrorAction SilentlyContinue) {
                    try {
                        $docParams = @{
                            ModulesPath = '/app/modules'
                            OutputPath = '/docs/generated'
                            IncludeExamples = $true
                            GenerateHTML = $true
                            EnableCache = $true
                        }
                        
                        New-ComprehensiveAPIDocs @docParams
                        Write-DocEngineLog "API documentation generated successfully" -Level Success
                    } catch {
                        Write-DocEngineLog "API documentation generation failed: $_" -Level Error
                    }
                }
                
                # Run security analysis if enabled
                if ($env:ENABLE_CODEQL -eq 'true' -and (Get-Command Invoke-PowerShellSecurityScan -ErrorAction SilentlyContinue)) {
                    try {
                        Write-DocEngineLog "Running CodeQL security scan..." -Level Info
                        $scanResults = Invoke-PowerShellSecurityScan -SourcePath '/docs/source' -OutputPath '/docs/generated/security'
                        Write-DocEngineLog "Security scan completed: $($scanResults.TotalFindings) findings" -Level Success
                    } catch {
                        Write-DocEngineLog "Security scan failed: $_" -Level Error
                    }
                }
                
                $lastGeneration = $now
                
                # Final health status update
                $healthStatus = @{
                    status = 'healthy'
                    timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
                    modules_loaded = (Get-Module Unity-Claude* | Measure-Object).Count
                    last_generation = $lastGeneration.ToString('yyyy-MM-ddTHH:mm:ss')
                    next_generation = $lastGeneration.AddSeconds($generationInterval).ToString('yyyy-MM-ddTHH:mm:ss')
                    generation_success = $true
                }
                $healthStatus | ConvertTo-Json -Depth 3 | Out-File '/docs/generated/health.json' -Encoding UTF8
                
                Write-DocEngineLog "Documentation generation cycle completed successfully" -Level Success
            }
            
            # Sleep for a short interval before checking again
            Start-Sleep -Seconds 30
            
        } catch {
            Write-DocEngineLog "Error in documentation loop: $_" -Level Error
            
            # Update health status to indicate error
            $errorStatus = @{
                status = 'error'
                timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
                error_message = $_.Exception.Message
                modules_loaded = (Get-Module Unity-Claude* | Measure-Object).Count
            }
            $errorStatus | ConvertTo-Json -Depth 3 | Out-File '/docs/generated/health.json' -Encoding UTF8
            
            Start-Sleep -Seconds 60 # Wait longer after error
        }
    }
}

# Main execution
try {
    Write-DocEngineLog "Enhanced Documentation System starting up..." -Level Info
    Write-DocEngineLog "Container environment: $(hostname)" -Level Info
    Write-DocEngineLog "PowerShell version: $($PSVersionTable.PSVersion)" -Level Info
    Write-DocEngineLog "Output path: $env:DOCS_OUTPUT_PATH" -Level Info
    Write-DocEngineLog "Cache path: $env:DOCS_CACHE_PATH" -Level Info
    Write-DocEngineLog "CodeQL enabled: $env:ENABLE_CODEQL" -Level Info
    
    # Initialize the documentation engine
    if (Initialize-DocumentationEngine) {
        Write-DocEngineLog "Starting main documentation generation loop..." -Level Success
        Start-DocumentationLoop
    } else {
        Write-DocEngineLog "Failed to initialize documentation engine" -Level Error
        exit 1
    }
    
} catch {
    Write-DocEngineLog "Fatal error during startup: $_" -Level Error
    Write-DocEngineLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
} finally {
    Write-DocEngineLog "Documentation engine shutting down..." -Level Info
}