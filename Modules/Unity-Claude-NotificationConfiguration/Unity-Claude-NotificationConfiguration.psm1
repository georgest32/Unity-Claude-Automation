# Unity-Claude-NotificationConfiguration Module
# Purpose: Configuration management for notification settings
# Created: 2025-08-22
# Week 6 Day 5 Implementation - Hour 1-4

# Module Variables
$script:ConfigPath = Join-Path $PSScriptRoot "..\..\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
$script:BackupPath = Join-Path $PSScriptRoot "..\..\Backups\NotificationConfig"
$script:ConfigCache = $null
$script:ConfigCacheTime = $null
$script:CacheDuration = 300 # 5 minutes

# Initialize backup directory
if (-not (Test-Path $script:BackupPath)) {
    New-Item -Path $script:BackupPath -ItemType Directory -Force | Out-Null
    Write-Host "[NotificationConfiguration] Created backup directory: $script:BackupPath" -ForegroundColor Gray
}

# Load Public Functions
$publicFunctions = @(
    'Get-NotificationConfig',
    'Set-NotificationConfig',
    'Test-NotificationConfig',
    'Reset-NotificationConfig',
    'Backup-NotificationConfig',
    'Restore-NotificationConfig',
    'Get-ConfigBackupHistory',
    'Start-NotificationConfigWizard',
    'Export-NotificationConfig',
    'Import-NotificationConfig',
    'Compare-NotificationConfig',
    'Get-ConfigurationReport'
)

$publicPath = Join-Path $PSScriptRoot "Public"
foreach ($file in Get-ChildItem -Path $publicPath -Filter "*.ps1" -ErrorAction SilentlyContinue) {
    try {
        . $file.FullName
        Write-Debug "[NotificationConfiguration] Loaded public function: $($file.BaseName)"
    } catch {
        Write-Warning "[NotificationConfiguration] Failed to load public function $($file.BaseName): $_"
    }
}

# Load Private Functions
$privatePath = Join-Path $PSScriptRoot "Private"
foreach ($file in Get-ChildItem -Path $privatePath -Filter "*.ps1" -ErrorAction SilentlyContinue) {
    try {
        . $file.FullName
        Write-Debug "[NotificationConfiguration] Loaded private function: $($file.BaseName)"
    } catch {
        Write-Warning "[NotificationConfiguration] Failed to load private function $($file.BaseName): $_"
    }
}

# Module initialization
Write-Host "[NotificationConfiguration] Module loaded successfully" -ForegroundColor Green
Write-Debug "[NotificationConfiguration] Config path: $script:ConfigPath"
Write-Debug "[NotificationConfiguration] Backup path: $script:BackupPath"

# Export module members
Export-ModuleMember -Function $publicFunctions