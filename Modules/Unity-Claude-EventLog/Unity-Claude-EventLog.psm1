# Unity-Claude-EventLog Module
# Provides Windows Event Log integration for Unity-Claude Automation System
# Supports both PowerShell 5.1 and PowerShell 7+

# Module-level variables
$script:ModuleName = 'Unity-Claude-EventLog'
$script:ModuleVersion = '1.0.0'
$script:LogName = 'Unity-Claude-Automation'
$script:SourceName = 'Unity-Claude-Agent'
$script:IsPSCore = $PSVersionTable.PSEdition -eq 'Core'

# Debug logging
$script:DebugLogPath = Join-Path $PSScriptRoot "..\..\unity_claude_automation.log"

# Load module configuration from manifest
$script:ModuleConfig = $null
try {
    $manifestPath = Join-Path $PSScriptRoot "$ModuleName.psd1"
    if (Test-Path $manifestPath) {
        $manifestData = Import-PowerShellDataFile -Path $manifestPath
        $script:ModuleConfig = $manifestData.PrivateData.EventLogConfig
        
        # Update module variables from config
        if ($script:ModuleConfig) {
            $script:LogName = $script:ModuleConfig.LogName
            $script:SourceName = $script:ModuleConfig.SourceName
        }
    }
}
catch {
    Write-Warning "Failed to load module configuration: $_"
}

# Helper function for debug logging
function Write-UCDebugLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [$Level] [EventLog] $Message"
    
    try {
        Add-Content -Path $script:DebugLogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Silently fail if unable to write to debug log
    }
}

# Load all function files
$functionFolders = @('Core', 'Query', 'Setup')
foreach ($folder in $functionFolders) {
    $folderPath = Join-Path $PSScriptRoot $folder
    if (Test-Path $folderPath) {
        $files = Get-ChildItem -Path $folderPath -Filter '*.ps1' -File
        foreach ($file in $files) {
            try {
                Write-UCDebugLog "Loading function file: $($file.Name)"
                . $file.FullName
                Write-UCDebugLog "Successfully loaded: $($file.Name)"
            }
            catch {
                Write-Warning "Failed to load $($file.Name): $_"
                Write-UCDebugLog "ERROR loading $($file.Name): $_" -Level 'ERROR'
            }
        }
    }
}

# Module initialization
Write-UCDebugLog "Unity-Claude-EventLog module v$script:ModuleVersion loaded"
Write-UCDebugLog "PowerShell Edition: $($PSVersionTable.PSEdition)"
Write-UCDebugLog "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-UCDebugLog "Event Log Name: $script:LogName"
Write-UCDebugLog "Event Source: $script:SourceName"

# Export module members (defined in manifest)
Write-UCDebugLog "Module initialization complete"