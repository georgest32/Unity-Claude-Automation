# AutoGenerationTriggers.psm1
# File change triggers, commit hook integration, scheduled generation, and manual trigger API
# Part of Unity-Claude-Enhanced-DocumentationGenerators system

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Management.Automation

# Global variables for trigger management
$Script:FileWatchers = @{}
$Script:TriggerConfig = @{}
$Script:ActiveTriggers = @{}

# Initialize trigger configuration
function Initialize-DocumentationTriggers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$PSScriptRoot\..\Config\trigger-config.json"
    )
    
    try {
        if (Test-Path $ConfigPath) {
            $Script:TriggerConfig = Get-Content $ConfigPath | ConvertFrom-Json
        } else {
            # Default configuration
            $Script:TriggerConfig = @{
                FileWatcher = @{
                    Enabled = $true
                    WatchPaths = @(".\")
                    FileExtensions = @('.ps1', '.psm1', '.py', '.cs', '.js', '.ts')
                    IncludeSubdirectories = $true
                    NotifyFilters = @('LastWrite', 'CreationTime', 'FileName')
                    BufferSize = 8192
                    ThrottleSeconds = 5
                }
                GitHooks = @{
                    Enabled = $true
                    PreCommit = $true
                    PostCommit = $false
                    PrePush = $false
                    HooksPath = ".git\hooks"
                }
                Scheduled = @{
                    Enabled = $false
                    IntervalMinutes = 60
                    RunOnStartup = $false
                }
                Manual = @{
                    Enabled = $true
                    LogActivity = $true
                    OutputPath = ".\Documentation\Generated"
                }
            }
            
            # Create config directory if it doesn't exist
            $configDir = Split-Path $ConfigPath -Parent
            if (-not (Test-Path $configDir)) {
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            }
            
            # Save default configuration
            $Script:TriggerConfig | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
        }
        
        Write-Verbose "Documentation triggers initialized successfully"
        return $true
    }
    catch {
        Write-Error "Failed to initialize documentation triggers: $_"
        return $false
    }
}

# File system watcher implementation
function Start-FileWatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WatchPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FileExtensions = @('.ps1', '.psm1', '.py', '.cs', '.js', '.ts'),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubdirectories,
        
        [Parameter(Mandatory = $false)]
        [int]$ThrottleSeconds = 5
    )
    
    try {
        $resolvedPath = Resolve-Path $WatchPath -ErrorAction Stop
        $watcherKey = $resolvedPath.Path
        
        # Stop existing watcher for this path
        if ($Script:FileWatchers.ContainsKey($watcherKey)) {
            Stop-FileWatcher -WatchPath $watcherKey
        }
        
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $resolvedPath.Path
        $watcher.IncludeSubdirectories = $IncludeSubdirectories.IsPresent
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::CreationTime -bor [System.IO.NotifyFilters]::FileName
        
        # Create filter for file extensions
        $extensionFilter = $FileExtensions -join '|'
        $watcher.Filter = "*.*"
        
        # Throttling mechanism
        $lastTrigger = @{}
        
        # Event handler
        $action = {
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $fileName = Split-Path $path -Leaf
            $extension = [System.IO.Path]::GetExtension($path).ToLower()
            
            # Check if file extension matches our filter
            if ($extension -notin $FileExtensions) {
                return
            }
            
            # Throttling check
            $now = Get-Date
            if ($lastTrigger.ContainsKey($path)) {
                $timeDiff = ($now - $lastTrigger[$path]).TotalSeconds
                if ($timeDiff -lt $ThrottleSeconds) {
                    return
                }
            }
            $lastTrigger[$path] = $now
            
            Write-Verbose "File change detected: $path ($changeType)"
            
            # Trigger documentation generation
            try {
                Invoke-DocumentationGeneration -FilePath $path -Trigger "FileWatcher" -ChangeType $changeType
            }
            catch {
                Write-Warning "Failed to generate documentation for $path`: $_"
            }
        }
        
        # Register event handlers
        Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action | Out-Null
        Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action | Out-Null
        Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $action | Out-Null
        
        # Start watching
        $watcher.EnableRaisingEvents = $true
        
        # Store watcher reference
        $Script:FileWatchers[$watcherKey] = @{
            Watcher = $watcher
            Extensions = $FileExtensions
            ThrottleSeconds = $ThrottleSeconds
            StartTime = Get-Date
        }
        
        Write-Information "File watcher started for: $watcherKey" -InformationAction Continue
        return $true
    }
    catch {
        Write-Error "Failed to start file watcher for '$WatchPath': $_"
        return $false
    }
}

# Stop file system watcher
function Stop-FileWatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WatchPath
    )
    
    try {
        $resolvedPath = Resolve-Path $WatchPath -ErrorAction SilentlyContinue
        $watcherKey = if ($resolvedPath) { $resolvedPath.Path } else { $WatchPath }
        
        if ($Script:FileWatchers.ContainsKey($watcherKey)) {
            $watcherInfo = $Script:FileWatchers[$watcherKey]
            $watcher = $watcherInfo.Watcher
            
            # Stop watching and dispose
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
            
            # Remove event handlers
            Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher } | Unregister-Event
            
            # Remove from collection
            $Script:FileWatchers.Remove($watcherKey)
            
            Write-Information "File watcher stopped for: $watcherKey" -InformationAction Continue
            return $true
        }
        else {
            Write-Warning "No file watcher found for path: $watcherKey"
            return $false
        }
    }
    catch {
        Write-Error "Failed to stop file watcher for '$WatchPath': $_"
        return $false
    }
}

# Git hooks integration
function Install-GitHooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath = ".",
        
        [Parameter(Mandatory = $false)]
        [switch]$PreCommit,
        
        [Parameter(Mandatory = $false)]
        [switch]$PostCommit,
        
        [Parameter(Mandatory = $false)]
        [switch]$PrePush,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        $gitDir = Join-Path $RepositoryPath ".git"
        if (-not (Test-Path $gitDir)) {
            throw "Not a git repository: $RepositoryPath"
        }
        
        $hooksDir = Join-Path $gitDir "hooks"
        if (-not (Test-Path $hooksDir)) {
            New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
        }
        
        $installed = @()
        
        # Pre-commit hook
        if ($PreCommit) {
            $hookPath = Join-Path $hooksDir "pre-commit"
            $psHookPath = Join-Path $hooksDir "pre-commit.ps1"
            
            if ((Test-Path $hookPath) -and -not $Force) {
                Write-Warning "Pre-commit hook already exists. Use -Force to overwrite."
            }
            else {
                # Create PowerShell script
                $psScript = @"
# Pre-commit hook for documentation generation
param([string[]]`$StagedFiles)

try {
    Import-Module "$PSScriptRoot\..\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Unity-Claude-Enhanced-DocumentationGenerators.psd1" -Force
    
    # Get staged files
    if (-not `$StagedFiles) {
        `$StagedFiles = git diff --cached --name-only --diff-filter=ACM
    }
    
    `$needsCommit = `$false
    foreach (`$file in `$StagedFiles) {
        if (Test-Path `$file) {
            `$ext = [System.IO.Path]::GetExtension(`$file).ToLower()
            if (`$ext -in @('.ps1', '.psm1', '.py', '.cs', '.js', '.ts')) {
                Write-Host "Generating documentation for: `$file"
                `$result = Invoke-DocumentationGeneration -FilePath `$file -Trigger "GitHook" -UpdateStagedFiles
                if (`$result.DocumentationUpdated) {
                    `$needsCommit = `$true
                }
            }
        }
    }
    
    if (`$needsCommit) {
        Write-Host "Documentation updated. Please review and commit again."
        exit 1
    }
    
    exit 0
}
catch {
    Write-Error "Pre-commit hook failed: `$_"
    exit 1
}
"@
                
                Set-Content -Path $psHookPath -Value $psScript -Encoding UTF8
                
                # Create shell wrapper
                $shellScript = @"
#!/bin/sh
# Pre-commit hook wrapper for PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "`$(dirname "`$0")/pre-commit.ps1"
exit `$?
"@
                
                Set-Content -Path $hookPath -Value $shellScript -Encoding UTF8
                
                # Make executable (if on Unix-like system)
                if ($IsLinux -or $IsMacOS) {
                    chmod +x $hookPath
                }
                
                $installed += "pre-commit"
            }
        }
        
        # Post-commit hook
        if ($PostCommit) {
            $hookPath = Join-Path $hooksDir "post-commit"
            $psHookPath = Join-Path $hooksDir "post-commit.ps1"
            
            if ((Test-Path $hookPath) -and -not $Force) {
                Write-Warning "Post-commit hook already exists. Use -Force to overwrite."
            }
            else {
                # Create PowerShell script
                $psScript = @"
# Post-commit hook for documentation generation
try {
    Import-Module "$PSScriptRoot\..\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Unity-Claude-Enhanced-DocumentationGenerators.psd1" -Force
    
    # Get files from last commit
    `$changedFiles = git diff-tree --no-commit-id --name-only -r HEAD
    
    foreach (`$file in `$changedFiles) {
        if (Test-Path `$file) {
            `$ext = [System.IO.Path]::GetExtension(`$file).ToLower()
            if (`$ext -in @('.ps1', '.psm1', '.py', '.cs', '.js', '.ts')) {
                Write-Host "Post-commit documentation generation for: `$file"
                Invoke-DocumentationGeneration -FilePath `$file -Trigger "PostCommit"
            }
        }
    }
    
    exit 0
}
catch {
    Write-Warning "Post-commit hook failed: `$_"
    exit 0
}
"@
                
                Set-Content -Path $psHookPath -Value $psScript -Encoding UTF8
                
                # Create shell wrapper
                $shellScript = @"
#!/bin/sh
# Post-commit hook wrapper for PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "`$(dirname "`$0")/post-commit.ps1"
"@
                
                Set-Content -Path $hookPath -Value $shellScript -Encoding UTF8
                
                # Make executable (if on Unix-like system)
                if ($IsLinux -or $IsMacOS) {
                    chmod +x $hookPath
                }
                
                $installed += "post-commit"
            }
        }
        
        # Pre-push hook
        if ($PrePush) {
            $hookPath = Join-Path $hooksDir "pre-push"
            $psHookPath = Join-Path $hooksDir "pre-push.ps1"
            
            if ((Test-Path $hookPath) -and -not $Force) {
                Write-Warning "Pre-push hook already exists. Use -Force to overwrite."
            }
            else {
                # Create PowerShell script
                $psScript = @"
# Pre-push hook for documentation validation
param([string]`$RemoteName, [string]`$RemoteUrl)

try {
    Import-Module "$PSScriptRoot\..\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Unity-Claude-Enhanced-DocumentationGenerators.psd1" -Force
    
    Write-Host "Validating documentation before push to `$RemoteName..."
    
    # Run documentation validation
    `$validationResult = Test-DocumentationIntegrity
    
    if (-not `$validationResult.IsValid) {
        Write-Error "Documentation validation failed. Push aborted."
        Write-Host "Issues found:"
        `$validationResult.Issues | ForEach-Object { Write-Host "  - `$_" }
        exit 1
    }
    
    Write-Host "Documentation validation passed."
    exit 0
}
catch {
    Write-Error "Pre-push hook failed: `$_"
    exit 1
}
"@
                
                Set-Content -Path $psHookPath -Value $psScript -Encoding UTF8
                
                # Create shell wrapper
                $shellScript = @"
#!/bin/sh
# Pre-push hook wrapper for PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "`$(dirname "`$0")/pre-push.ps1" "`$1" "`$2"
exit `$?
"@
                
                Set-Content -Path $hookPath -Value $shellScript -Encoding UTF8
                
                # Make executable (if on Unix-like system)
                if ($IsLinux -or $IsMacOS) {
                    chmod +x $hookPath
                }
                
                $installed += "pre-push"
            }
        }
        
        if ($installed.Count -gt 0) {
            Write-Information "Git hooks installed: $($installed -join ', ')" -InformationAction Continue
        }
        
        return $installed
    }
    catch {
        Write-Error "Failed to install git hooks: $_"
        return @()
    }
}

# Remove git hooks
function Uninstall-GitHooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath = ".",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('pre-commit', 'post-commit', 'pre-push', 'all')]
        [string]$HookType = 'all'
    )
    
    try {
        $gitDir = Join-Path $RepositoryPath ".git"
        if (-not (Test-Path $gitDir)) {
            throw "Not a git repository: $RepositoryPath"
        }
        
        $hooksDir = Join-Path $gitDir "hooks"
        $removed = @()
        
        $hooksToRemove = if ($HookType -eq 'all') {
            @('pre-commit', 'post-commit', 'pre-push')
        } else {
            @($HookType)
        }
        
        foreach ($hook in $hooksToRemove) {
            $hookPath = Join-Path $hooksDir $hook
            $psHookPath = Join-Path $hooksDir "$hook.ps1"
            
            if (Test-Path $hookPath) {
                Remove-Item $hookPath -Force
                $removed += $hook
            }
            
            if (Test-Path $psHookPath) {
                Remove-Item $psHookPath -Force
            }
        }
        
        if ($removed.Count -gt 0) {
            Write-Information "Git hooks removed: $($removed -join ', ')" -InformationAction Continue
        }
        
        return $removed
    }
    catch {
        Write-Error "Failed to uninstall git hooks: $_"
        return @()
    }
}

# Manual documentation generation trigger
function Invoke-DocumentationGeneration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Manual', 'FileWatcher', 'GitHook', 'PostCommit', 'Scheduled')]
        [string]$Trigger = 'Manual',
        
        [Parameter(Mandatory = $false)]
        [string]$ChangeType = 'Unknown',
        
        [Parameter(Mandatory = $false)]
        [switch]$UpdateStagedFiles,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        $result = @{
            FilePath = $FilePath
            Trigger = $Trigger
            ChangeType = $ChangeType
            Timestamp = Get-Date
            Success = $false
            DocumentationUpdated = $false
            OutputFiles = @()
            Errors = @()
        }
        
        # Validate file exists
        if (-not (Test-Path $FilePath)) {
            $result.Errors += "File not found: $FilePath"
            return $result
        }
        
        # Get language from file extension
        $language = Get-LanguageFromExtension -FilePath $FilePath
        if ($language -eq 'Unknown') {
            $result.Errors += "Unsupported file type: $FilePath"
            return $result
        }
        
        Write-Verbose "Processing $FilePath ($language) - Trigger: $Trigger"
        
        # Import required modules
        if (-not (Get-Module "Templates-PerLanguage")) {
            Import-Module "$PSScriptRoot\Templates-PerLanguage.psm1" -Force
        }
        
        # Log activity if configured
        if ($Script:TriggerConfig.Manual.LogActivity) {
            $logEntry = @{
                Timestamp = Get-Date
                Trigger = $Trigger
                FilePath = $FilePath
                Language = $language
                ChangeType = $ChangeType
            }
            
            Add-TriggerActivity -LogEntry $logEntry
        }
        
        # Generate documentation based on language
        switch ($language) {
            'PowerShell' {
                $docResult = New-PowerShellDocumentation -FilePath $FilePath -Force:$Force
            }
            'Python' {
                $docResult = New-PythonDocumentation -FilePath $FilePath -Force:$Force
            }
            'CSharp' {
                $docResult = New-CSharpDocumentation -FilePath $FilePath -Force:$Force
            }
            { $_ -in @('JavaScript', 'TypeScript') } {
                $docResult = New-JavaScriptDocumentation -FilePath $FilePath -Force:$Force
            }
        }
        
        if ($docResult) {
            $result.Success = $true
            $result.DocumentationUpdated = $docResult.Updated
            $result.OutputFiles = $docResult.OutputFiles
            
            # Add to git staging area if requested
            if ($UpdateStagedFiles -and $result.DocumentationUpdated) {
                foreach ($outputFile in $result.OutputFiles) {
                    if (Test-Path $outputFile) {
                        git add $outputFile
                        Write-Verbose "Added to staging: $outputFile"
                    }
                }
            }
        }
        
        return $result
    }
    catch {
        $result.Errors += "Exception: $_"
        Write-Error "Documentation generation failed for '$FilePath': $_"
        return $result
    }
}

# Scheduled documentation generation
function Start-ScheduledDocumentationGeneration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 60,
        
        [Parameter(Mandatory = $false)]
        [string[]]$WatchPaths = @("."),
        
        [Parameter(Mandatory = $false)]
        [string[]]$FileExtensions = @('.ps1', '.psm1', '.py', '.cs', '.js', '.ts')
    )
    
    try {
        # Create scheduled task for documentation generation
        $taskName = "Unity-Claude-DocumentationGeneration"
        $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"Import-Module '$PSScriptRoot\..\Unity-Claude-Enhanced-DocumentationGenerators.psd1'; Invoke-ScheduledDocumentationScan`""
        $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
        
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        $task = New-ScheduledTask -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Description "Automated documentation generation for Unity-Claude-Automation"
        
        Register-ScheduledTask -TaskName $taskName -InputObject $task -Force
        
        Write-Information "Scheduled documentation generation started (every $IntervalMinutes minutes)" -InformationAction Continue
        return $true
    }
    catch {
        Write-Error "Failed to start scheduled documentation generation: $_"
        return $false
    }
}

# Stop scheduled documentation generation
function Stop-ScheduledDocumentationGeneration {
    [CmdletBinding()]
    param()
    
    try {
        $taskName = "Unity-Claude-DocumentationGeneration"
        
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Information "Scheduled documentation generation stopped" -InformationAction Continue
            return $true
        }
        else {
            Write-Warning "Scheduled task not found: $taskName"
            return $false
        }
    }
    catch {
        Write-Error "Failed to stop scheduled documentation generation: $_"
        return $false
    }
}

# Activity logging
function Add-TriggerActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$LogEntry
    )
    
    try {
        $logPath = "$PSScriptRoot\..\Logs\trigger-activity.json"
        $logDir = Split-Path $logPath -Parent
        
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        $logs = @()
        if (Test-Path $logPath) {
            $logs = Get-Content $logPath | ConvertFrom-Json
        }
        
        $logs += $LogEntry
        
        # Keep only last 1000 entries
        if ($logs.Count -gt 1000) {
            $logs = $logs[-1000..-1]
        }
        
        $logs | ConvertTo-Json -Depth 5 | Set-Content $logPath
    }
    catch {
        Write-Warning "Failed to log trigger activity: $_"
    }
}

# Get trigger activity log
function Get-TriggerActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Last = 50,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Manual', 'FileWatcher', 'GitHook', 'PostCommit', 'Scheduled')]
        [string]$TriggerType
    )
    
    try {
        $logPath = "$PSScriptRoot\..\Logs\trigger-activity.json"
        
        if (-not (Test-Path $logPath)) {
            return @()
        }
        
        $logs = Get-Content $logPath | ConvertFrom-Json
        
        if ($TriggerType) {
            $logs = $logs | Where-Object { $_.Trigger -eq $TriggerType }
        }
        
        return $logs | Select-Object -Last $Last
    }
    catch {
        Write-Error "Failed to get trigger activity: $_"
        return @()
    }
}

# Cleanup resources on module removal
function Remove-AllTriggers {
    [CmdletBinding()]
    param()
    
    try {
        # Stop all file watchers
        foreach ($watcherKey in $Script:FileWatchers.Keys) {
            Stop-FileWatcher -WatchPath $watcherKey
        }
        
        # Stop scheduled generation
        Stop-ScheduledDocumentationGeneration
        
        Write-Information "All documentation generation triggers have been stopped" -InformationAction Continue
    }
    catch {
        Write-Error "Failed to cleanup triggers: $_"
    }
}

# Module initialization
if (-not $Script:TriggerConfig.Count) {
    Initialize-DocumentationTriggers
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-DocumentationTriggers',
    'Start-FileWatcher',
    'Stop-FileWatcher',
    'Install-GitHooks',
    'Uninstall-GitHooks',
    'Invoke-DocumentationGeneration',
    'Start-ScheduledDocumentationGeneration',
    'Stop-ScheduledDocumentationGeneration',
    'Add-TriggerActivity',
    'Get-TriggerActivity',
    'Remove-AllTriggers'
)

# Register module removal handler
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-AllTriggers
}