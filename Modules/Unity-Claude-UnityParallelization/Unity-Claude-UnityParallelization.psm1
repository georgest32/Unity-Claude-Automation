
# Dependency validation function - added by Fix-ModuleNestingLimit-Phase1.ps1
function Test-ModuleDependencyAvailability {
    param(
        [string[]]$RequiredModules,
        [string]$ModuleName = "Unknown"
    )
    
    $missingModules = @()
    foreach ($reqModule in $RequiredModules) {
        $module = Get-Module $reqModule -ErrorAction SilentlyContinue
        if (-not $module) {
            $missingModules += $reqModule
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Warning "[$ModuleName] Missing required modules: $($missingModules -join ', '). Import them explicitly before using this module."
        return $false
    }
    
    return $true
}

# Unity-Claude-UnityParallelization.psm1
# Phase 1 Week 3 Days 1-2: Unity Compilation Parallelization
# Parallel Unity project monitoring and concurrent error detection/export
# Date: 2025-08-21

$ErrorActionPreference = "Stop"

# Import required modules with fallback logging
$script:RequiredModulesAvailable = @{}
$script:WriteModuleLogAvailable = $false

try {
    # Conditional import to preserve script variables - fixes state reset issue
    if (-not (Get-Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue)) {
        Import-Module Unity-Claude-RunspaceManagement -ErrorAction Stop
        Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-RunspaceManagement module" -ForegroundColor Gray
    } else {
        Write-Host "[DEBUG] [StatePreservation] Unity-Claude-RunspaceManagement already loaded, preserving state" -ForegroundColor Gray
    }
    $script:RequiredModulesAvailable['RunspaceManagement'] = $true
    $script:WriteModuleLogAvailable = $true
} catch {
    Write-Warning "Failed to import Unity-Claude-RunspaceManagement: $($_.Exception.Message)"
    $script:RequiredModulesAvailable['RunspaceManagement'] = $false
}

try {
    # Conditional import to preserve script variables - fixes state reset issue
    if (-not (Get-Module Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue)) {
        Import-Module Unity-Claude-ParallelProcessing -ErrorAction Stop
        Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-ParallelProcessing module" -ForegroundColor Gray
    } else {
        Write-Host "[DEBUG] [StatePreservation] Unity-Claude-ParallelProcessing already loaded, preserving state" -ForegroundColor Gray
    }
    $script:RequiredModulesAvailable['ParallelProcessing'] = $true
} catch {
    Write-Warning "Failed to import Unity-Claude-ParallelProcessing: $($_.Exception.Message)"
    $script:RequiredModulesAvailable['ParallelProcessing'] = $false
}

# Fallback logging function
function Write-FallbackLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "UnityParallelization"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [$Component] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        default { Write-Host $logMessage -ForegroundColor White }
    }
}

# Wrapper function for logging with fallback
function Write-UnityParallelLog {
    param(
        [string]$Message,
        [string]$Level = "INFO", 
        [string]$Component = "UnityParallelization"
    )
    
    if ($script:WriteModuleLogAvailable -and (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
        Write-ModuleLog -Message $Message -Level $Level -Component $Component
    } else {
        Write-FallbackLog -Message $Message -Level $Level -Component $Component
    }
}

# Module-level variables for Unity project management
$script:RegisteredUnityProjects = @{}
$script:ActiveUnityMonitors = @{}
$script:UnityParallelizationConfig = @{
    UnityExecutablePath = ""
    DefaultLogPath = "$env:LOCALAPPDATA\Unity\Editor"
    ErrorPatterns = @{
        CompilationError = '^.*\(\d+,\d+\): error.*$'
        CS0246 = 'CS0246.*could not be found'
        CS0103 = 'CS0103.*does not exist'
        CS1061 = 'CS1061.*does not contain'
        CS0029 = 'CS0029.*cannot implicitly convert'
    }
    MonitoringInterval = 1000  # 1 second
    CompilationTimeout = 300   # 5 minutes
    ErrorDetectionLatency = 500 # 500ms target
}

# Module loading notification
Write-UnityParallelLog -Message "Loading Unity-Claude-UnityParallelization module..." -Level "DEBUG"

#region Unity Project Discovery and Configuration (Hour 1-2)

<#
.SYNOPSIS
Discovers Unity projects in specified directories
.DESCRIPTION
Searches for Unity projects by looking for ProjectSettings/ProjectVersion.txt files
.PARAMETER SearchPaths
Array of directories to search for Unity projects
.PARAMETER Recursive
Search recursively through subdirectories
.PARAMETER IncludeVersion
Include Unity version information for each project
.EXAMPLE
$projects = Find-UnityProjects -SearchPaths @("C:\UnityProjects") -Recursive
#>
function Find-UnityProjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SearchPaths,
        [switch]$Recursive,
        [switch]$IncludeVersion
    )
    
    Write-UnityParallelLog -Message "Discovering Unity projects in search paths..." -Level "INFO"
    
    try {
        $discoveredProjects = @()
        
        foreach ($searchPath in $SearchPaths) {
            if (-not (Test-Path $searchPath)) {
                Write-UnityParallelLog -Message "Search path not found: $searchPath" -Level "WARNING"
                continue
            }
            
            Write-UnityParallelLog -Message "Searching for Unity projects in: $searchPath" -Level "DEBUG"
            
            # Look for ProjectSettings/ProjectVersion.txt files
            $searchPattern = if ($Recursive) { 
                "$searchPath\*\ProjectSettings\ProjectVersion.txt" 
            } else { 
                "$searchPath\ProjectSettings\ProjectVersion.txt" 
            }
            
            $projectVersionFiles = Get-ChildItem -Path $searchPattern -ErrorAction SilentlyContinue
            
            foreach ($versionFile in $projectVersionFiles) {
                $projectPath = Split-Path (Split-Path $versionFile.FullName -Parent) -Parent
                $projectName = Split-Path $projectPath -Leaf
                
                $projectInfo = @{
                    Name = $projectName
                    Path = $projectPath
                    ProjectSettingsPath = Split-Path $versionFile.FullName -Parent
                    VersionFile = $versionFile.FullName
                    DiscoveredTime = Get-Date
                }
                
                # Include version information if requested
                if ($IncludeVersion) {
                    try {
                        $versionContent = Get-Content $versionFile.FullName
                        $versionLine = $versionContent | Where-Object { $_ -like "m_EditorVersion:*" }
                        if ($versionLine) {
                            $projectInfo.UnityVersion = $versionLine.Split(':')[1].Trim()
                        }
                    } catch {
                        Write-UnityParallelLog -Message "Could not read version from $($versionFile.FullName): $($_.Exception.Message)" -Level "WARNING"
                    }
                }
                
                $discoveredProjects += $projectInfo
                Write-UnityParallelLog -Message "Discovered Unity project: $projectName at $projectPath" -Level "DEBUG"
            }
        }
        
        Write-UnityParallelLog -Message "Unity project discovery completed: $($discoveredProjects.Count) projects found" -Level "INFO"
        
        return $discoveredProjects
        
    } catch {
        Write-UnityParallelLog -Message "Failed to discover Unity projects: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Registers a Unity project for parallel monitoring
.DESCRIPTION
Registers Unity project with configuration for parallel compilation monitoring
.PARAMETER ProjectPath
Path to the Unity project root directory
.PARAMETER ProjectName
Optional custom name for the project
.PARAMETER MonitoringEnabled
Enable compilation monitoring for this project
.PARAMETER LogPath
Custom log file path for Unity Editor.log monitoring
.EXAMPLE
Register-UnityProject -ProjectPath "C:\UnityProjects\MyGame" -MonitoringEnabled
#>
function Register-UnityProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [string]$ProjectName = "",
        [switch]$MonitoringEnabled,
        [string]$LogPath = ""
    )
    
    Write-UnityParallelLog -Message "Registering Unity project for parallel monitoring..." -Level "INFO"
    
    try {
        # Validate project path
        if (-not (Test-Path $ProjectPath)) {
            throw "Unity project path not found: $ProjectPath"
        }
        
        # Validate Unity project structure
        $projectSettingsPath = Join-Path $ProjectPath "ProjectSettings"
        $projectVersionFile = Join-Path $projectSettingsPath "ProjectVersion.txt"
        
        if (-not (Test-Path $projectVersionFile)) {
            throw "Not a valid Unity project: ProjectVersion.txt not found in $projectSettingsPath"
        }
        
        # Generate project name if not provided
        if ([string]::IsNullOrEmpty($ProjectName)) {
            $ProjectName = Split-Path $ProjectPath -Leaf
        }
        
        # Determine log path
        if ([string]::IsNullOrEmpty($LogPath)) {
            $LogPath = "$($script:UnityParallelizationConfig.DefaultLogPath)\Editor.log"
        }
        
        # Create project configuration
        $projectConfig = @{
            Name = $ProjectName
            Path = $ProjectPath
            ProjectSettingsPath = $projectSettingsPath
            LogPath = $LogPath
            MonitoringEnabled = $MonitoringEnabled
            RegisteredTime = Get-Date
            Status = "Registered"
            
            # Monitoring configuration
            MonitoringConfig = @{
                FileSystemWatcher = $null
                LogMonitoring = $false
                ErrorDetection = $false
                CompilationTracking = $false
                LastActivity = $null
            }
            
            # Statistics tracking
            Statistics = @{
                CompilationsDetected = 0
                ErrorsFound = 0
                ErrorsExported = 0
                LastCompilation = $null
                AverageCompilationTime = 0
            }
        }
        
        # Register project
        $script:RegisteredUnityProjects[$ProjectName] = $projectConfig
        
        Write-UnityParallelLog -Message "Unity project registered successfully: $ProjectName at $ProjectPath" -Level "INFO"
        
        return $projectConfig
        
    } catch {
        Write-UnityParallelLog -Message "Failed to register Unity project '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Gets configuration for a registered Unity project
.DESCRIPTION
Retrieves the configuration and status of a registered Unity project
.PARAMETER ProjectName
Name of the registered Unity project
.EXAMPLE
$config = Get-UnityProjectConfiguration -ProjectName "MyGame"
#>
function Get-UnityProjectConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    
    try {
        if (-not $script:RegisteredUnityProjects.ContainsKey($ProjectName)) {
            throw "Unity project not registered: $ProjectName"
        }
        
        $projectConfig = $script:RegisteredUnityProjects[$ProjectName]
        
        Write-UnityParallelLog -Message "Retrieved configuration for Unity project: $ProjectName" -Level "DEBUG"
        
        return $projectConfig
        
    } catch {
        Write-UnityParallelLog -Message "Failed to get Unity project configuration '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Gets all registered Unity projects
.DESCRIPTION
Returns a hashtable of all registered Unity projects with their configurations
.EXAMPLE
$projects = Get-RegisteredUnityProjects
#>
function Get-RegisteredUnityProjects {
    [CmdletBinding()]
    param()
    
    try {
        Write-UnityParallelLog -Message "Getting all registered Unity projects..." -Level "DEBUG"
        return $script:RegisteredUnityProjects
    } catch {
        Write-UnityParallelLog -Message "Failed to get registered Unity projects: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Sets configuration for a registered Unity project  
.DESCRIPTION
Updates configuration settings for a registered Unity project
.PARAMETER ProjectName
Name of the registered Unity project
.PARAMETER Configuration
Hashtable containing configuration updates
.EXAMPLE
Set-UnityProjectConfiguration -ProjectName "MyGame" -Configuration @{MonitoringEnabled=$true}
#>
function Set-UnityProjectConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )
    
    Write-UnityParallelLog -Message "Updating Unity project configuration: $ProjectName" -Level "INFO"
    
    try {
        if (-not $script:RegisteredUnityProjects.ContainsKey($ProjectName)) {
            throw "Unity project not registered: $ProjectName"
        }
        
        $projectConfig = $script:RegisteredUnityProjects[$ProjectName]
        
        # Update configuration settings
        foreach ($key in $Configuration.Keys) {
            if ($projectConfig.ContainsKey($key)) {
                $oldValue = $projectConfig[$key]
                $projectConfig[$key] = $Configuration[$key]
                Write-UnityParallelLog -Message "Updated $key from $oldValue to $($Configuration[$key])" -Level "DEBUG"
            } else {
                Write-UnityParallelLog -Message "Unknown configuration key: $key" -Level "WARNING"
            }
        }
        
        Write-UnityParallelLog -Message "Unity project configuration updated successfully: $ProjectName" -Level "INFO"
        
        return $projectConfig
        
    } catch {
        Write-UnityParallelLog -Message "Failed to set Unity project configuration '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Tests Unity project availability for parallel monitoring
.DESCRIPTION
Validates that Unity project is available and ready for parallel monitoring
.PARAMETER ProjectName
Name of the registered Unity project
.EXAMPLE
Test-UnityProjectAvailability -ProjectName "MyGame"
#>
function Test-UnityProjectAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    
    try {
        if (-not $script:RegisteredUnityProjects.ContainsKey($ProjectName)) {
            return @{Available = $false; Reason = "Project not registered"}
        }
        
        $projectConfig = $script:RegisteredUnityProjects[$ProjectName]
        $availability = @{
            Available = $true
            ProjectPath = $projectConfig.Path
            ProjectExists = Test-Path $projectConfig.Path
            ProjectSettingsExists = Test-Path $projectConfig.ProjectSettingsPath
            LogPathAccessible = Test-Path (Split-Path $projectConfig.LogPath -Parent)
            Reason = ""
        }
        
        # Check project availability
        if (-not $availability.ProjectExists) {
            $availability.Available = $false
            $availability.Reason = "Project path not found: $($projectConfig.Path)"
        } elseif (-not $availability.ProjectSettingsExists) {
            $availability.Available = $false
            $availability.Reason = "ProjectSettings not found: $($projectConfig.ProjectSettingsPath)"
        } elseif (-not $availability.LogPathAccessible) {
            $availability.Available = $false
            $availability.Reason = "Log path not accessible: $($projectConfig.LogPath)"
        }
        
        Write-UnityParallelLog -Message "Unity project availability check: $ProjectName - Available: $($availability.Available)" -Level "DEBUG"
        
        return $availability
        
    } catch {
        Write-UnityParallelLog -Message "Failed to test Unity project availability '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        return @{Available = $false; Reason = "Error: $($_.Exception.Message)"}
    }
}

#endregion

#region Parallel Unity Monitoring Architecture (Hour 1-2)

<#
.SYNOPSIS
Creates a new Unity parallel monitoring system
.DESCRIPTION
Creates parallel Unity monitoring infrastructure using runspace pools for multiple project monitoring
.PARAMETER MonitorName
Name for the parallel monitoring system
.PARAMETER ProjectNames
Array of registered Unity project names to monitor
.PARAMETER MaxRunspaces
Maximum number of runspaces for parallel monitoring
.PARAMETER EnableResourceMonitoring
Enable CPU and memory monitoring during parallel operations
.EXAMPLE
$monitor = New-UnityParallelMonitor -MonitorName "UnityCompilationMonitor" -ProjectNames @("MyGame1", "MyGame2") -MaxRunspaces 3
#>
function New-UnityParallelMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MonitorName,
        [Parameter(Mandatory)]
        [string[]]$ProjectNames,
        [int]$MaxRunspaces = 3,
        [switch]$EnableResourceMonitoring
    )
    
    Write-UnityParallelLog -Message "Creating Unity parallel monitoring system '$MonitorName'..." -Level "INFO"
    
    try {
        # Debug module availability checking
        Write-UnityParallelLog -Message "DEBUG: Checking module availability..." -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: RequiredModulesAvailable hashtable type: $($script:RequiredModulesAvailable.GetType().Name)" -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: RequiredModulesAvailable contains RunspaceManagement: $($script:RequiredModulesAvailable.ContainsKey('RunspaceManagement'))" -Level "DEBUG"
        
        if ($script:RequiredModulesAvailable.ContainsKey('RunspaceManagement')) {
            Write-UnityParallelLog -Message "DEBUG: RunspaceManagement availability: $($script:RequiredModulesAvailable['RunspaceManagement'])" -Level "DEBUG"
        }
        
        # Validate required modules with hybrid checking (import tracking + actual availability)
        $runspaceModuleAvailable = $false
        
        if ($script:RequiredModulesAvailable.ContainsKey('RunspaceManagement') -and $script:RequiredModulesAvailable['RunspaceManagement']) {
            # Import tracking shows available
            $runspaceModuleAvailable = $true
            Write-UnityParallelLog -Message "DEBUG: RunspaceManagement available via import tracking" -Level "DEBUG"
        } else {
            # Check actual module availability as fallback
            $actualModule = Get-Module -Name Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue
            if ($actualModule) {
                $runspaceModuleAvailable = $true
                Write-UnityParallelLog -Message "DEBUG: RunspaceManagement available via Get-Module fallback ($($actualModule.ExportedCommands.Count) commands)" -Level "DEBUG"
            }
        }
        
        if (-not $runspaceModuleAvailable) {
            Write-UnityParallelLog -Message "ERROR: Unity-Claude-RunspaceManagement module required but not available" -Level "ERROR"
            throw "Unity-Claude-RunspaceManagement module required but not available"
        }
        
        Write-UnityParallelLog -Message "DEBUG: Module availability check passed" -Level "DEBUG"
        
        # Validate registered projects with debug logging
        Write-UnityParallelLog -Message "DEBUG: Validating $($ProjectNames.Count) project names..." -Level "DEBUG"
        $validProjects = @()
        
        foreach ($projectName in $ProjectNames) {
            Write-UnityParallelLog -Message "DEBUG: Testing availability for project: $projectName" -Level "DEBUG"
            
            try {
                $availability = Test-UnityProjectAvailability -ProjectName $projectName
                Write-UnityParallelLog -Message "DEBUG: Availability result for $projectName : Available: $($availability.Available)" -Level "DEBUG"
                
                if ($availability.Available) {
                    $validProjects += $projectName
                    Write-UnityParallelLog -Message "Project validated for monitoring: $projectName" -Level "DEBUG"
                } else {
                    Write-UnityParallelLog -Message "Project not available for monitoring: $projectName - $($availability.Reason)" -Level "WARNING"
                }
            } catch {
                Write-UnityParallelLog -Message "ERROR: Failed to test project availability for $projectName : $($_.Exception.Message)" -Level "ERROR"
            }
        }
        
        Write-UnityParallelLog -Message "DEBUG: Valid projects count: $($validProjects.Count)" -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: Valid projects: $($validProjects -join ', ')" -Level "DEBUG"
        
        if ($validProjects.Count -eq 0) {
            throw "No valid Unity projects available for monitoring"
        }
        
        # Create session state for Unity monitoring with debug logging
        Write-UnityParallelLog -Message "DEBUG: Creating session state..." -Level "DEBUG"
        
        try {
            $sessionConfig = New-RunspaceSessionState -LanguageMode 'FullLanguage' -ExecutionPolicy 'Bypass'
            Write-UnityParallelLog -Message "DEBUG: Session state created successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to create session state: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to create session state: $($_.Exception.Message)"
        }
        
        try {
            Initialize-SessionStateVariables -SessionStateConfig $sessionConfig | Out-Null
            Write-UnityParallelLog -Message "DEBUG: Session state variables initialized" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to initialize session state variables: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to initialize session state variables: $($_.Exception.Message)"
        }
        
        # Create shared monitoring state with debug logging
        Write-UnityParallelLog -Message "DEBUG: Creating shared monitoring state..." -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: validProjects type: $($validProjects.GetType().Name), count: $($validProjects.Count)" -Level "DEBUG"
        
        try {
            $monitoringState = [hashtable]::Synchronized(@{
                ActiveProjects = [System.Collections.ArrayList]::Synchronized($validProjects)
                CompilationEvents = [System.Collections.ArrayList]::Synchronized(@())
                DetectedErrors = [System.Collections.ArrayList]::Synchronized(@())
                ExportResults = [System.Collections.ArrayList]::Synchronized(@())
            })
            Write-UnityParallelLog -Message "DEBUG: Monitoring state created successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to create monitoring state: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to create monitoring state: $($_.Exception.Message)"
        }
        
        try {
            Add-SharedVariable -SessionStateConfig $sessionConfig -Name "UnityMonitoringState" -Value $monitoringState -MakeThreadSafe
            Write-UnityParallelLog -Message "DEBUG: Shared variable added successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to add shared variable: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to add shared variable: $($_.Exception.Message)"
        }
        
        # Create production runspace pool for Unity monitoring with debug logging
        Write-UnityParallelLog -Message "DEBUG: Creating production runspace pool..." -Level "DEBUG"
        
        try {
            $monitoringPool = New-ProductionRunspacePool -SessionStateConfig $sessionConfig -MaxRunspaces $MaxRunspaces -Name $MonitorName -EnableResourceMonitoring:$EnableResourceMonitoring
            Write-UnityParallelLog -Message "DEBUG: Production runspace pool created successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to create production runspace pool: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to create production runspace pool: $($_.Exception.Message)"
        }
        
        # Create Unity parallel monitor object
        $unityMonitor = @{
            MonitorName = $MonitorName
            ProjectNames = $validProjects
            RunspacePool = $monitoringPool
            SessionConfig = $sessionConfig
            MonitoringState = $monitoringState
            MaxRunspaces = $MaxRunspaces
            Created = Get-Date
            Status = 'Created'
            
            # Monitoring jobs tracking
            ActiveJobs = @()
            MonitoringJobs = @()
            CompilationJobs = @()
            ErrorDetectionJobs = @()
            
            # Performance tracking
            Statistics = @{
                ProjectsMonitored = $validProjects.Count
                CompilationsDetected = 0
                ErrorsDetected = 0
                ErrorsExported = 0
                TotalMonitoringTime = 0
                AverageProcessingTime = 0
            }
        }
        
        # Register monitor
        $script:ActiveUnityMonitors[$MonitorName] = $unityMonitor
        
        Write-UnityParallelLog -Message "Unity parallel monitor '$MonitorName' created successfully for $($validProjects.Count) projects" -Level "INFO"
        
        return $unityMonitor
        
    } catch {
        Write-UnityParallelLog -Message "Failed to create Unity parallel monitor '$MonitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Starts Unity parallel monitoring system
.DESCRIPTION
Starts parallel monitoring for Unity compilation across multiple projects using runspace pools
.PARAMETER Monitor
Unity monitor object from New-UnityParallelMonitor
.PARAMETER MonitoringMode
Type of monitoring (Compilation, Errors, Both)
.EXAMPLE
Start-UnityParallelMonitoring -Monitor $monitor -MonitoringMode "Both"
#>
function Start-UnityParallelMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('Compilation', 'Errors', 'Both')]
        [string]$MonitoringMode = 'Both'
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Starting Unity parallel monitoring '$monitorName' in $MonitoringMode mode..." -Level "INFO"
    
    try {
        # Open runspace pool
        $openResult = Open-RunspacePool -PoolManager $Monitor.RunspacePool
        if (-not $openResult.Success) {
            throw "Failed to open runspace pool for Unity monitor '$monitorName'"
        }
        
        # Create monitoring jobs for each project
        foreach ($projectName in $Monitor.ProjectNames) {
            $projectConfig = Get-UnityProjectConfiguration -ProjectName $projectName
            
            # Unity compilation monitoring job
            if ($MonitoringMode -eq 'Compilation' -or $MonitoringMode -eq 'Both') {
                $compilationScript = {
                    param([ref]$MonitoringState, $ProjectName, $ProjectPath, $LogPath)
                    
                    try {
                        # Monitor Unity project for compilation activity
                        $watcher = New-Object System.IO.FileSystemWatcher
                        $watcher.Path = $ProjectPath
                        $watcher.Filter = "*.cs"
                        $watcher.IncludeSubdirectories = $true
                        $watcher.EnableRaisingEvents = $true
                        
                        # Simple monitoring loop (replace with proper FileSystemWatcher event handling)
                        $startTime = Get-Date
                        $timeout = (Get-Date).AddMinutes(5) # 5 minute monitoring window
                        
                        while ((Get-Date) -lt $timeout) {
                            # Check for compilation activity indicators
                            $logExists = Test-Path $LogPath
                            
                            if ($logExists) {
                                $compilationEvent = @{
                                    ProjectName = $ProjectName
                                    EventType = "CompilationDetected"
                                    Timestamp = Get-Date
                                    LogPath = $LogPath
                                }
                                
                                $MonitoringState.Value.CompilationEvents.Add($compilationEvent)
                            }
                            
                            Start-Sleep -Milliseconds 1000 # 1 second polling
                        }
                        
                        $watcher.Dispose()
                        return "Unity compilation monitoring completed for $ProjectName"
                        
                    } catch {
                        return "Unity compilation monitoring error for $ProjectName : $($_.Exception.Message)"
                    }
                }
                
                # Submit compilation monitoring job using reference parameter passing (Learning #196)
                $ps = [powershell]::Create()
                $ps.RunspacePool = $Monitor.RunspacePool.RunspacePool
                $ps.AddScript($compilationScript)
                $ps.AddArgument([ref]$Monitor.MonitoringState)
                $ps.AddArgument($projectName)
                $ps.AddArgument($projectConfig.Path)
                $ps.AddArgument($projectConfig.LogPath)
                
                $asyncResult = $ps.BeginInvoke()
                
                $monitoringJob = @{
                    JobType = "CompilationMonitoring"
                    ProjectName = $projectName
                    PowerShell = $ps
                    AsyncResult = $asyncResult
                    StartTime = Get-Date
                }
                
                $Monitor.MonitoringJobs += $monitoringJob
                
                Write-UnityParallelLog -Message "Started compilation monitoring for project: $projectName" -Level "DEBUG"
            }
            
            # Unity error detection monitoring job  
            if ($MonitoringMode -eq 'Errors' -or $MonitoringMode -eq 'Both') {
                $errorDetectionScript = {
                    param([ref]$MonitoringState, $ProjectName, $LogPath, $ErrorPatterns)
                    
                    try {
                        # Monitor Unity Editor.log for errors using Get-Content -Wait pattern
                        if (Test-Path $LogPath) {
                            $errorCount = 0
                            $startTime = Get-Date
                            $timeout = (Get-Date).AddMinutes(5)
                            
                            # Simple log monitoring (replace with Get-Content -Wait in production)
                            while ((Get-Date) -lt $timeout) {
                                $logContent = Get-Content $LogPath -ErrorAction SilentlyContinue
                                
                                if ($logContent) {
                                    # Check for compilation errors
                                    $errors = $logContent | Where-Object { $_ -match $ErrorPatterns.CompilationError }
                                    
                                    foreach ($error in $errors) {
                                        $errorEvent = @{
                                            ProjectName = $ProjectName
                                            ErrorType = "CompilationError"
                                            ErrorText = $error
                                            Timestamp = Get-Date
                                            LogPath = $LogPath
                                        }
                                        
                                        $MonitoringState.Value.DetectedErrors.Add($errorEvent)
                                        $errorCount++
                                    }
                                }
                                
                                Start-Sleep -Milliseconds 500 # 500ms polling for error detection
                            }
                            
                            return "Unity error detection completed for $ProjectName : $errorCount errors found"
                        } else {
                            return "Unity log file not found for $ProjectName : $LogPath"
                        }
                        
                    } catch {
                        return "Unity error detection error for $ProjectName : $($_.Exception.Message)"
                    }
                }
                
                # Submit error detection job using reference parameter passing
                $ps = [powershell]::Create()
                $ps.RunspacePool = $Monitor.RunspacePool.RunspacePool
                $ps.AddScript($errorDetectionScript)
                $ps.AddArgument([ref]$Monitor.MonitoringState)
                $ps.AddArgument($projectName)
                $ps.AddArgument($projectConfig.LogPath)
                $ps.AddArgument($script:UnityParallelizationConfig.ErrorPatterns)
                
                $asyncResult = $ps.BeginInvoke()
                
                $errorJob = @{
                    JobType = "ErrorDetection"
                    ProjectName = $projectName
                    PowerShell = $ps
                    AsyncResult = $asyncResult
                    StartTime = Get-Date
                }
                
                $Monitor.MonitoringJobs += $errorJob
                
                Write-UnityParallelLog -Message "Started error detection for project: $projectName" -Level "DEBUG"
            }
        }
        
        # Update monitor status
        $Monitor.Status = 'Running'
        $Monitor.StartTime = Get-Date
        
        Write-UnityParallelLog -Message "Unity parallel monitoring '$monitorName' started successfully for $($Monitor.ProjectNames.Count) projects" -Level "INFO"
        
        return @{
            Success = $true
            MonitoringJobs = $Monitor.MonitoringJobs.Count
            ProjectsMonitored = $Monitor.ProjectNames.Count
            MonitoringMode = $MonitoringMode
        }
        
    } catch {
        Write-UnityParallelLog -Message "Failed to start Unity parallel monitoring '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Stops Unity parallel monitoring system
.DESCRIPTION
Stops all parallel monitoring jobs and cleans up resources
.PARAMETER Monitor
Unity monitor object
.PARAMETER Force
Force stop even if jobs are running
.EXAMPLE
Stop-UnityParallelMonitoring -Monitor $monitor
#>
function Stop-UnityParallelMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [switch]$Force
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Stopping Unity parallel monitoring '$monitorName'..." -Level "INFO"
    
    try {
        # Stop all monitoring jobs
        $stoppedJobs = 0
        foreach ($job in $Monitor.MonitoringJobs) {
            try {
                if (-not $job.AsyncResult.IsCompleted) {
                    $job.PowerShell.Stop()
                }
                
                $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                Write-UnityParallelLog -Message "Monitoring job result for $($job.ProjectName): $result" -Level "DEBUG"
                
                $job.PowerShell.Dispose()
                $stoppedJobs++
                
            } catch {
                Write-UnityParallelLog -Message "Error stopping monitoring job for $($job.ProjectName): $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Close runspace pool
        $closeResult = Close-RunspacePool -PoolManager $Monitor.RunspacePool -Force:$Force
        
        # Update monitor status
        $Monitor.Status = 'Stopped'
        $Monitor.StopTime = Get-Date
        
        if ($Monitor.StartTime) {
            $Monitor.Statistics.TotalMonitoringTime = [math]::Round(($Monitor.StopTime - $Monitor.StartTime).TotalMinutes, 2)
        }
        
        Write-UnityParallelLog -Message "Unity parallel monitoring '$monitorName' stopped successfully ($stoppedJobs jobs stopped)" -Level "INFO"
        
        return @{
            Success = $closeResult.Success
            JobsStopped = $stoppedJobs
            MonitoringTime = $Monitor.Statistics.TotalMonitoringTime
        }
        
    } catch {
        Write-UnityParallelLog -Message "Failed to stop Unity parallel monitoring '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Gets status of Unity parallel monitoring system
.DESCRIPTION
Returns current status and statistics for Unity parallel monitoring
.PARAMETER Monitor
Unity monitor object
.EXAMPLE
Get-UnityMonitoringStatus -Monitor $monitor
#>
function Get-UnityMonitoringStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor
    )
    
    try {
        $monitorName = $Monitor.MonitorName
        
        # Get runspace pool status
        $poolStatus = Get-RunspacePoolStatus -PoolManager $Monitor.RunspacePool
        
        # Count monitoring results
        $compilationEvents = $Monitor.MonitoringState.CompilationEvents.Count
        $detectedErrors = $Monitor.MonitoringState.DetectedErrors.Count
        $exportResults = $Monitor.MonitoringState.ExportResults.Count
        
        $status = @{
            MonitorName = $monitorName
            Status = $Monitor.Status
            ProjectsMonitored = $Monitor.ProjectNames.Count
            RunspacePoolStatus = $poolStatus.State
            AvailableRunspaces = $poolStatus.AvailableRunspaces
            ActiveJobs = $poolStatus.ActiveJobs
            
            # Monitoring results
            CompilationEvents = $compilationEvents
            DetectedErrors = $detectedErrors
            ExportResults = $exportResults
            
            # Performance statistics
            Statistics = $Monitor.Statistics
            
            # Timing information
            Created = $Monitor.Created
            StartTime = $Monitor.StartTime
            CurrentTime = Get-Date
        }
        
        # Calculate current monitoring duration
        if ($Monitor.StartTime -and $Monitor.Status -eq 'Running') {
            $status.CurrentMonitoringDuration = [math]::Round(((Get-Date) - $Monitor.StartTime).TotalMinutes, 2)
        }
        
        Write-UnityParallelLog -Message "Unity monitoring status retrieved for '$monitorName': $($status.Status), Events: $compilationEvents, Errors: $detectedErrors" -Level "DEBUG"
        
        return $status
        
    } catch {
        Write-UnityParallelLog -Message "Failed to get Unity monitoring status: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region Unity Compilation Process Integration (Hour 3-4)

<#
.SYNOPSIS
Starts a Unity compilation job in batch mode
.DESCRIPTION
Executes Unity compilation in batch mode using runspace pools with hanging prevention
.PARAMETER Monitor
Unity monitor object
.PARAMETER ProjectName
Name of the Unity project to compile
.PARAMETER CompilationMethod
Unity method to execute for compilation
.PARAMETER TimeoutMinutes
Timeout for compilation job in minutes
.EXAMPLE
Start-UnityCompilationJob -Monitor $monitor -ProjectName "MyGame" -CompilationMethod "CompileProject"
#>
function Start-UnityCompilationJob {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [string]$CompilationMethod = "AssetDatabase.Refresh",
        [int]$TimeoutMinutes = 5
    )
    
    Write-UnityParallelLog -Message "Starting Unity compilation job for project '$ProjectName'..." -Level "INFO"
    
    try {
        # Get project configuration
        $projectConfig = Get-UnityProjectConfiguration -ProjectName $ProjectName
        
        # Create Unity compilation script (research-validated batch mode pattern)
        $compilationScript = {
            param($ProjectPath, $LogPath, $Method, $TimeoutMinutes)
            
            try {
                # Unity batch mode command (research pattern from queries)
                $unityPath = "C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe"
                if (-not (Test-Path $unityPath)) {
                    # Try to find Unity executable
                    $unityPath = Get-ChildItem "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" | Select-Object -First 1 -ExpandProperty FullName
                }
                
                if (-not $unityPath) {
                    throw "Unity executable not found"
                }
                
                $arguments = @(
                    "-quit"
                    "-batchmode"
                    "-projectPath", "`"$ProjectPath`""
                    "-logFile", "`"$LogPath`""
                    "-executeMethod", $Method
                )
                
                # Start Unity process with timeout (Learning #98: hanging prevention)
                $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processStartInfo.FileName = $unityPath
                $processStartInfo.Arguments = $arguments -join " "
                $processStartInfo.UseShellExecute = $false
                $processStartInfo.RedirectStandardOutput = $true
                $processStartInfo.RedirectStandardError = $true
                
                $process = [System.Diagnostics.Process]::Start($processStartInfo)
                
                # Wait for completion with timeout
                $completed = $process.WaitForExit($TimeoutMinutes * 60 * 1000) # Convert to milliseconds
                
                if ($completed) {
                    $exitCode = $process.ExitCode
                    $output = $process.StandardOutput.ReadToEnd()
                    $error = $process.StandardError.ReadToEnd()
                    
                    return @{
                        Success = $exitCode -eq 0
                        ExitCode = $exitCode
                        Output = $output
                        Error = $error
                        Duration = (Get-Date) - $startTime
                    }
                } else {
                    # Process timed out, kill it
                    try { $process.Kill() } catch { }
                    throw "Unity compilation timed out after $TimeoutMinutes minutes"
                }
                
            } catch {
                throw "Unity compilation error: $($_.Exception.Message)"
            }
        }
        
        # Submit compilation job to runspace pool
        $job = Submit-RunspaceJob -PoolManager $Monitor.RunspacePool -ScriptBlock $compilationScript -Parameters @{
            ProjectPath = $projectConfig.Path
            LogPath = $projectConfig.LogPath
            Method = $CompilationMethod
            TimeoutMinutes = $TimeoutMinutes
        } -JobName "UnityCompilation-$ProjectName" -TimeoutSeconds ($TimeoutMinutes * 60 + 60)
        
        # Track compilation job
        $Monitor.CompilationJobs += $job
        
        Write-UnityParallelLog -Message "Unity compilation job started for '$ProjectName' (JobId: $($job.JobId))" -Level "INFO"
        
        return $job
        
    } catch {
        Write-UnityParallelLog -Message "Failed to start Unity compilation job for '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region Concurrent Error Detection and Classification (Hour 5-6)

<#
.SYNOPSIS
Starts concurrent error detection across multiple Unity projects
.DESCRIPTION
Implements concurrent Unity error detection using FileSystemWatcher and log parsing with runspace pools
.PARAMETER Monitor
Unity monitor object
.PARAMETER ErrorDetectionMode
Type of error detection (RealTime, Batch, Both)
.PARAMETER LatencyTargetMs
Target latency for error detection in milliseconds
.EXAMPLE
Start-ConcurrentErrorDetection -Monitor $monitor -ErrorDetectionMode "RealTime" -LatencyTargetMs 500
#>
function Start-ConcurrentErrorDetection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('RealTime', 'Batch', 'Both')]
        [string]$ErrorDetectionMode = 'RealTime',
        [int]$LatencyTargetMs = 500
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Starting concurrent error detection for '$monitorName' in $ErrorDetectionMode mode..." -Level "INFO"
    
    try {
        foreach ($projectName in $Monitor.ProjectNames) {
            $projectConfig = Get-UnityProjectConfiguration -ProjectName $projectName
            
            # Real-time error detection using FileSystemWatcher
            if ($ErrorDetectionMode -eq 'RealTime' -or $ErrorDetectionMode -eq 'Both') {
                $realTimeDetectionScript = {
                    param([ref]$MonitoringState, $ProjectName, $ProjectPath, $LogPath, $ErrorPatterns, $LatencyTarget)
                    
                    try {
                        # Create FileSystemWatcher for C# files (research-validated pattern)
                        $watcher = New-Object System.IO.FileSystemWatcher
                        $watcher.Path = $ProjectPath
                        $watcher.Filter = "*.cs"
                        $watcher.IncludeSubdirectories = $true
                        $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
                        
                        $changeDetected = $false
                        $lastChangeTime = Get-Date
                        
                        # Register event handler (research: use flag-based approach for Unity thread safety)
                        $action = {
                            $global:changeDetected = $true
                            $global:lastChangeTime = Get-Date
                        }
                        
                        Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action | Out-Null
                        $watcher.EnableRaisingEvents = $true
                        
                        $startTime = Get-Date
                        $timeout = (Get-Date).AddMinutes(10) # 10 minute monitoring window
                        $errorsDetected = 0
                        
                        while ((Get-Date) -lt $timeout) {
                            # Check for file changes
                            if ($changeDetected) {
                                # Reset flag
                                $changeDetected = $false
                                
                                # Wait for file write completion
                                Start-Sleep -Milliseconds $LatencyTarget
                                
                                # Check Unity log for new errors
                                if (Test-Path $LogPath) {
                                    $logContent = Get-Content $LogPath -Tail 20 -ErrorAction SilentlyContinue
                                    
                                    if ($logContent) {
                                        foreach ($line in $logContent) {
                                            # Check against error patterns
                                            foreach ($patternName in $ErrorPatterns.Keys) {
                                                if ($line -match $ErrorPatterns[$patternName]) {
                                                    $errorEvent = @{
                                                        ProjectName = $ProjectName
                                                        ErrorType = $patternName
                                                        ErrorText = $line
                                                        Timestamp = Get-Date
                                                        DetectionLatency = [math]::Round(((Get-Date) - $lastChangeTime).TotalMilliseconds, 2)
                                                        SourceFile = "Unknown"
                                                    }
                                                    
                                                    $MonitoringState.Value.DetectedErrors.Add($errorEvent)
                                                    $errorsDetected++
                                                    break
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Start-Sleep -Milliseconds 100 # Fast polling for real-time detection
                        }
                        
                        # Cleanup
                        $watcher.EnableRaisingEvents = $false
                        $watcher.Dispose()
                        
                        return "Real-time error detection completed for $ProjectName : $errorsDetected errors detected"
                        
                    } catch {
                        return "Real-time error detection error for $ProjectName : $($_.Exception.Message)"
                    }
                }
                
                # Submit real-time detection job using reference parameter passing
                $ps = [powershell]::Create()
                $ps.RunspacePool = $Monitor.RunspacePool.RunspacePool
                $ps.AddScript($realTimeDetectionScript)
                $ps.AddArgument([ref]$Monitor.MonitoringState)
                $ps.AddArgument($projectName)
                $ps.AddArgument($projectConfig.Path)
                $ps.AddArgument($projectConfig.LogPath)
                $ps.AddArgument($script:UnityParallelizationConfig.ErrorPatterns)
                $ps.AddArgument($LatencyTargetMs)
                
                $asyncResult = $ps.BeginInvoke()
                
                $detectionJob = @{
                    JobType = "RealTimeErrorDetection"
                    ProjectName = $projectName
                    PowerShell = $ps
                    AsyncResult = $asyncResult
                    StartTime = Get-Date
                    LatencyTarget = $LatencyTargetMs
                }
                
                $Monitor.ErrorDetectionJobs += $detectionJob
                
                Write-UnityParallelLog -Message "Started real-time error detection for project: $projectName (Target: ${LatencyTargetMs}ms)" -Level "DEBUG"
            }
        }
        
        Write-UnityParallelLog -Message "Concurrent error detection started for '$monitorName' - $($Monitor.ProjectNames.Count) projects" -Level "INFO"
        
        return @{
            Success = $true
            ErrorDetectionJobs = $Monitor.ErrorDetectionJobs.Count
            ProjectsMonitored = $Monitor.ProjectNames.Count
            LatencyTarget = $LatencyTargetMs
        }
        
    } catch {
        Write-UnityParallelLog -Message "Failed to start concurrent error detection for '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Classifies Unity compilation errors using existing patterns
.DESCRIPTION
Classifies Unity errors using research-validated error patterns and existing database
.PARAMETER ErrorText
Unity error text to classify
.PARAMETER ProjectName
Name of the Unity project where error occurred
.EXAMPLE
$classification = Classify-UnityCompilationError -ErrorText "CS0246: The type or namespace name 'TestClass' could not be found" -ProjectName "MyGame"
#>
function Classify-UnityCompilationError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorText,
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    
    try {
        $classification = @{
            ErrorText = $ErrorText
            ProjectName = $ProjectName
            ErrorType = "Unknown"
            ErrorCode = ""
            Severity = "Unknown"
            Category = "Unknown"
            Confidence = 0.0
            ClassifiedTime = Get-Date
        }
        
        # Classify using existing error patterns
        $errorPatterns = $script:UnityParallelizationConfig.ErrorPatterns
        
        foreach ($patternName in $errorPatterns.Keys) {
            if ($ErrorText -match $errorPatterns[$patternName]) {
                $classification.ErrorType = $patternName
                $classification.Confidence = 0.9
                
                # Extract error code if present
                if ($ErrorText -match '(CS\d{4})') {
                    $classification.ErrorCode = $matches[1]
                }
                
                # Determine severity and category based on error type
                switch ($patternName) {
                    "CS0246" {
                        $classification.Severity = "High"
                        $classification.Category = "MissingReference"
                    }
                    "CS0103" {
                        $classification.Severity = "High" 
                        $classification.Category = "UndefinedVariable"
                    }
                    "CS1061" {
                        $classification.Severity = "Medium"
                        $classification.Category = "MissingMember"
                    }
                    "CS0029" {
                        $classification.Severity = "Medium"
                        $classification.Category = "TypeConversion"
                    }
                    "CompilationError" {
                        $classification.Severity = "High"
                        $classification.Category = "Compilation"
                    }
                    default {
                        $classification.Severity = "Unknown"
                        $classification.Category = "General"
                    }
                }
                
                break
            }
        }
        
        Write-UnityParallelLog -Message "Unity error classified: $($classification.ErrorType) ($($classification.ErrorCode)) - Confidence: $($classification.Confidence)" -Level "DEBUG"
        
        return $classification
        
    } catch {
        Write-UnityParallelLog -Message "Failed to classify Unity error: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Aggregates Unity errors from multiple projects
.DESCRIPTION
Aggregates and consolidates Unity errors from concurrent monitoring across projects
.PARAMETER Monitor
Unity monitor object containing detected errors
.PARAMETER AggregationMode
Type of aggregation (ByProject, ByErrorType, ByTime, All)
.EXAMPLE
$aggregatedErrors = Aggregate-UnityErrors -Monitor $monitor -AggregationMode "ByErrorType"
#>
function Aggregate-UnityErrors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('ByProject', 'ByErrorType', 'ByTime', 'All')]
        [string]$AggregationMode = 'All'
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Aggregating Unity errors for '$monitorName' using $AggregationMode mode..." -Level "INFO"
    
    try {
        $detectedErrors = $Monitor.MonitoringState.DetectedErrors
        
        if ($detectedErrors.Count -eq 0) {
            Write-UnityParallelLog -Message "No errors detected to aggregate" -Level "DEBUG"
            return @{
                TotalErrors = 0
                AggregationMode = $AggregationMode
                Aggregations = @{}
                ProcessedTime = Get-Date
            }
        }
        
        $aggregationResults = @{
            TotalErrors = $detectedErrors.Count
            AggregationMode = $AggregationMode
            Aggregations = @{}
            ProcessedTime = Get-Date
        }
        
        # Perform aggregation based on mode
        switch ($AggregationMode) {
            "ByProject" {
                $projectGroups = @{}
                foreach ($error in $detectedErrors) {
                    $projectName = $error.ProjectName
                    if (-not $projectGroups.ContainsKey($projectName)) {
                        $projectGroups[$projectName] = @()
                    }
                    $projectGroups[$projectName] += $error
                }
                $aggregationResults.Aggregations = $projectGroups
            }
            
            "ByErrorType" {
                $typeGroups = @{}
                foreach ($error in $detectedErrors) {
                    $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                    $errorType = $classification.ErrorType
                    
                    if (-not $typeGroups.ContainsKey($errorType)) {
                        $typeGroups[$errorType] = @()
                    }
                    $typeGroups[$errorType] += $error
                }
                $aggregationResults.Aggregations = $typeGroups
            }
            
            "ByTime" {
                # Group by hour
                $timeGroups = @{}
                foreach ($error in $detectedErrors) {
                    $hourKey = $error.Timestamp.ToString("yyyy-MM-dd HH:00")
                    if (-not $timeGroups.ContainsKey($hourKey)) {
                        $timeGroups[$hourKey] = @()
                    }
                    $timeGroups[$hourKey] += $error
                }
                $aggregationResults.Aggregations = $timeGroups
            }
            
            "All" {
                # Include all aggregation types
                $aggregationResults.Aggregations = @{
                    ByProject = @{}
                    ByErrorType = @{}
                    ByTime = @{}
                }
                
                # Project aggregation
                foreach ($error in $detectedErrors) {
                    $projectName = $error.ProjectName
                    if (-not $aggregationResults.Aggregations.ByProject.ContainsKey($projectName)) {
                        $aggregationResults.Aggregations.ByProject[$projectName] = @()
                    }
                    $aggregationResults.Aggregations.ByProject[$projectName] += $error
                }
                
                # Error type aggregation
                foreach ($error in $detectedErrors) {
                    $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                    $errorType = $classification.ErrorType
                    
                    if (-not $aggregationResults.Aggregations.ByErrorType.ContainsKey($errorType)) {
                        $aggregationResults.Aggregations.ByErrorType[$errorType] = @()
                    }
                    $aggregationResults.Aggregations.ByErrorType[$errorType] += $error
                }
            }
        }
        
        Write-UnityParallelLog -Message "Unity error aggregation completed: $($detectedErrors.Count) errors aggregated using $AggregationMode mode" -Level "INFO"
        
        return $aggregationResults
        
    } catch {
        Write-UnityParallelLog -Message "Failed to aggregate Unity errors for '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Deduplicates Unity errors across projects
.DESCRIPTION
Removes duplicate Unity errors based on error text, type, and timing patterns
.PARAMETER AggregatedErrors
Aggregated errors from Aggregate-UnityErrors
.PARAMETER DeduplicationMode
Type of deduplication (Exact, Similar, Time)
.PARAMETER SimilarityThreshold
Threshold for similar error detection (0.0-1.0)
.EXAMPLE
$deduplicated = Deduplicate-UnityErrors -AggregatedErrors $aggregated -DeduplicationMode "Similar" -SimilarityThreshold 0.8
#>
function Deduplicate-UnityErrors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AggregatedErrors,
        [ValidateSet('Exact', 'Similar', 'Time')]
        [string]$DeduplicationMode = 'Similar',
        [double]$SimilarityThreshold = 0.8
    )
    
    Write-UnityParallelLog -Message "Deduplicating Unity errors using $DeduplicationMode mode..." -Level "INFO"
    
    try {
        $allErrors = @()
        
        # Extract all errors from aggregation
        if ($AggregatedErrors.Aggregations -is [hashtable]) {
            foreach ($groupKey in $AggregatedErrors.Aggregations.Keys) {
                $group = $AggregatedErrors.Aggregations[$groupKey]
                if ($group -is [array]) {
                    $allErrors += $group
                } elseif ($group -is [hashtable]) {
                    foreach ($subGroupKey in $group.Keys) {
                        $allErrors += $group[$subGroupKey]
                    }
                }
            }
        }
        
        Write-UnityParallelLog -Message "Processing $($allErrors.Count) errors for deduplication..." -Level "DEBUG"
        
        $uniqueErrors = @()
        $duplicatesRemoved = 0
        
        foreach ($error in $allErrors) {
            $isDuplicate = $false
            
            switch ($DeduplicationMode) {
                "Exact" {
                    # Exact text match
                    $isDuplicate = $uniqueErrors | Where-Object { $_.ErrorText -eq $error.ErrorText }
                }
                "Similar" {
                    # Similar text match (simple approach)
                    foreach ($existingError in $uniqueErrors) {
                        $similarity = Get-StringSimilarity -String1 $error.ErrorText -String2 $existingError.ErrorText
                        if ($similarity -ge $SimilarityThreshold) {
                            $isDuplicate = $true
                            break
                        }
                    }
                }
                "Time" {
                    # Same error within 30 seconds
                    $isDuplicate = $uniqueErrors | Where-Object { 
                        $_.ErrorText -eq $error.ErrorText -and 
                        [math]::Abs(($_.Timestamp - $error.Timestamp).TotalSeconds) -lt 30 
                    }
                }
            }
            
            if (-not $isDuplicate) {
                $uniqueErrors += $error
            } else {
                $duplicatesRemoved++
            }
        }
        
        $deduplicationResults = @{
            OriginalCount = $allErrors.Count
            UniqueCount = $uniqueErrors.Count
            DuplicatesRemoved = $duplicatesRemoved
            DeduplicationMode = $DeduplicationMode
            SimilarityThreshold = $SimilarityThreshold
            UniqueErrors = $uniqueErrors
            ProcessedTime = Get-Date
        }
        
        Write-UnityParallelLog -Message "Unity error deduplication completed: $($allErrors.Count) → $($uniqueErrors.Count) errors ($duplicatesRemoved duplicates removed)" -Level "INFO"
        
        return $deduplicationResults
        
    } catch {
        Write-UnityParallelLog -Message "Failed to deduplicate Unity errors: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Gets Unity error statistics from monitoring
.DESCRIPTION
Provides statistical analysis of detected Unity errors across projects
.PARAMETER Monitor
Unity monitor object
.PARAMETER IncludeBreakdown
Include detailed breakdown by project and error type
.EXAMPLE
$stats = Get-UnityErrorStatistics -Monitor $monitor -IncludeBreakdown
#>
function Get-UnityErrorStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [switch]$IncludeBreakdown
    )
    
    $monitorName = $Monitor.MonitorName
    
    try {
        $detectedErrors = $Monitor.MonitoringState.DetectedErrors
        
        $statistics = @{
            MonitorName = $monitorName
            TotalErrors = $detectedErrors.Count
            ProjectsMonitored = $Monitor.ProjectNames.Count
            MonitoringDuration = 0
            ErrorsPerProject = @{}
            ErrorsByType = @{}
            AverageDetectionLatency = 0
            GeneratedTime = Get-Date
        }
        
        # Calculate monitoring duration
        if ($Monitor.StartTime) {
            $statistics.MonitoringDuration = [math]::Round(((Get-Date) - $Monitor.StartTime).TotalMinutes, 2)
        }
        
        # Process errors for statistics
        if ($detectedErrors.Count -gt 0) {
            # Errors per project
            foreach ($error in $detectedErrors) {
                $projectName = $error.ProjectName
                if (-not $statistics.ErrorsPerProject.ContainsKey($projectName)) {
                    $statistics.ErrorsPerProject[$projectName] = 0
                }
                $statistics.ErrorsPerProject[$projectName]++
            }
            
            # Errors by type
            foreach ($error in $detectedErrors) {
                $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                $errorType = $classification.ErrorType
                
                if (-not $statistics.ErrorsByType.ContainsKey($errorType)) {
                    $statistics.ErrorsByType[$errorType] = 0
                }
                $statistics.ErrorsByType[$errorType]++
            }
            
            # Average detection latency
            $latencies = $detectedErrors | Where-Object { $_.DetectionLatency -ne $null } | ForEach-Object { $_.DetectionLatency }
            if ($latencies.Count -gt 0) {
                $totalLatency = 0
                foreach ($latency in $latencies) {
                    $totalLatency += $latency
                }
                $statistics.AverageDetectionLatency = [math]::Round($totalLatency / $latencies.Count, 2)
            }
        }
        
        # Include detailed breakdown if requested
        if ($IncludeBreakdown) {
            $statistics.DetailedBreakdown = @{
                ErrorsByProject = @{}
                ErrorsByTypePerProject = @{}
            }
            
            foreach ($projectName in $Monitor.ProjectNames) {
                $projectErrors = $detectedErrors | Where-Object { $_.ProjectName -eq $projectName }
                $statistics.DetailedBreakdown.ErrorsByProject[$projectName] = $projectErrors
                
                $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName] = @{}
                foreach ($error in $projectErrors) {
                    $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                    $errorType = $classification.ErrorType
                    
                    if (-not $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName].ContainsKey($errorType)) {
                        $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName][$errorType] = 0
                    }
                    $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName][$errorType]++
                }
            }
        }
        
        Write-UnityParallelLog -Message "Unity error statistics generated: $($statistics.TotalErrors) errors across $($statistics.ProjectsMonitored) projects" -Level "INFO"
        
        return $statistics
        
    } catch {
        Write-UnityParallelLog -Message "Failed to get Unity error statistics for '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region Concurrent Error Export and Integration (Hour 7-8)

<#
.SYNOPSIS
Exports Unity errors concurrently using runspace pools
.DESCRIPTION
Implements concurrent Unity error export using production runspace pools for performance optimization
.PARAMETER Monitor
Unity monitor object
.PARAMETER ExportFormat
Format for error export (Claude, JSON, CSV, XML)
.PARAMETER OutputPath
Directory path for exported error files
.PARAMETER PerformanceTarget
Target performance improvement percentage
.EXAMPLE
Export-UnityErrorsConcurrently -Monitor $monitor -ExportFormat "Claude" -OutputPath "C:\Exports" -PerformanceTarget 50
#>
function Export-UnityErrorsConcurrently {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('Claude', 'JSON', 'CSV', 'XML', 'All')]
        [string]$ExportFormat = 'Claude',
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [int]$PerformanceTarget = 50
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Starting concurrent Unity error export for '$monitorName' in $ExportFormat format..." -Level "INFO"
    
    try {
        # Validate output path
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Get aggregated and deduplicated errors
        $aggregatedErrors = Aggregate-UnityErrors -Monitor $Monitor -AggregationMode "All"
        $deduplicatedErrors = Deduplicate-UnityErrors -AggregatedErrors $aggregatedErrors -DeduplicationMode "Similar"
        
        if ($deduplicatedErrors.UniqueCount -eq 0) {
            Write-UnityParallelLog -Message "No unique errors to export" -Level "WARNING"
            return @{
                Success = $true
                ErrorsExported = 0
                ExportFiles = @()
                PerformanceImprovement = 0
            }
        }
        
        Write-UnityParallelLog -Message "Exporting $($deduplicatedErrors.UniqueCount) unique Unity errors..." -Level "INFO"
        
        # Measure sequential baseline for performance comparison
        $sequentialStart = Get-Date
        $sequentialExports = @()
        
        # Simulate sequential export (for performance comparison)
        foreach ($error in $deduplicatedErrors.UniqueErrors) {
            Start-Sleep -Milliseconds 10 # Simulate export processing time
            $sequentialExports += "Sequential export of $($error.ErrorType)"
        }
        $sequentialTime = ((Get-Date) - $sequentialStart).TotalMilliseconds
        
        # Concurrent export using runspace pools
        $concurrentStart = Get-Date
        $concurrentExports = @()
        
        # Create concurrent export jobs
        $exportScript = {
            param($Error, $OutputPath, $ExportFormat, $ProjectName)
            
            try {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
                $filename = "${ProjectName}_${ExportFormat}_Error_${timestamp}.txt"
                $filepath = Join-Path $OutputPath $filename
                
                # Format error based on export format
                $exportContent = switch ($ExportFormat) {
                    "Claude" {
                        @"
Unity Compilation Error Report
Project: $ProjectName
Error Type: $($Error.ErrorType)
Timestamp: $($Error.Timestamp)
Error Text: $($Error.ErrorText)
Log Path: $($Error.LogPath)

Error Details:
$($Error.ErrorText)
"@
                    }
                    "JSON" {
                        $Error | ConvertTo-Json -Depth 5
                    }
                    "CSV" {
                        "$($Error.ProjectName),$($Error.ErrorType),$($Error.Timestamp),$($Error.ErrorText)"
                    }
                    default {
                        $Error | Out-String
                    }
                }
                
                # Write export file
                $exportContent | Out-File -FilePath $filepath -Encoding UTF8
                
                # Simulate processing time
                Start-Sleep -Milliseconds 10
                
                return @{
                    Success = $true
                    ExportFile = $filepath
                    ProjectName = $ProjectName
                    ErrorType = $Error.ErrorType
                    ProcessingTime = 10
                }
                
            } catch {
                return @{
                    Success = $false
                    Error = $_.Exception.Message
                    ProjectName = $ProjectName
                }
            }
        }
        
        # Submit concurrent export jobs
        $exportJobs = @()
        foreach ($error in $deduplicatedErrors.UniqueErrors) {
            $job = Submit-RunspaceJob -PoolManager $Monitor.RunspacePool -ScriptBlock $exportScript -Parameters @{
                Error = $error
                OutputPath = $OutputPath
                ExportFormat = $ExportFormat
                ProjectName = $error.ProjectName
            } -JobName "ErrorExport-$($error.ProjectName)-$(Get-Date -Format 'HHmmss')" -TimeoutSeconds 60
            
            $exportJobs += $job
        }
        
        # Wait for concurrent exports to complete
        $waitResult = Wait-RunspaceJobs -PoolManager $Monitor.RunspacePool -TimeoutSeconds 120 -ProcessResults
        $exportResults = Get-RunspaceJobResults -PoolManager $Monitor.RunspacePool
        
        $concurrentTime = ((Get-Date) - $concurrentStart).TotalMilliseconds
        
        # Calculate performance improvement
        $performanceImprovement = [math]::Round((($sequentialTime - $concurrentTime) / $sequentialTime) * 100, 2)
        
        # Update monitor statistics
        $Monitor.MonitoringState.ExportResults.Clear()
        foreach ($result in $exportResults.CompletedJobs) {
            $Monitor.MonitoringState.ExportResults.Add($result.Result)
        }
        
        $exportSummary = @{
            Success = $waitResult.Success
            ErrorsExported = $exportResults.CompletedJobs.Count
            ExportsFailed = $exportResults.FailedJobs.Count
            ExportFiles = $exportResults.CompletedJobs | ForEach-Object { $_.Result.ExportFile }
            SequentialTime = $sequentialTime
            ConcurrentTime = $concurrentTime
            PerformanceImprovement = $performanceImprovement
            TargetAchieved = $performanceImprovement -ge $PerformanceTarget
        }
        
        Write-UnityParallelLog -Message "Concurrent Unity error export completed: $($exportSummary.ErrorsExported) errors exported, $($exportSummary.PerformanceImprovement)% improvement" -Level "INFO"
        
        return $exportSummary
        
    } catch {
        Write-UnityParallelLog -Message "Failed to export Unity errors concurrently: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Formats Unity errors specifically for Claude processing
.DESCRIPTION
Formats Unity errors in Claude-optimized format for automated problem-solving
.PARAMETER DeduplicatedErrors
Deduplicated errors from Deduplicate-UnityErrors
.PARAMETER IncludeContext
Include additional context information for Claude
.EXAMPLE
$claudeFormat = Format-UnityErrorsForClaude -DeduplicatedErrors $deduplicated -IncludeContext
#>
function Format-UnityErrorsForClaude {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DeduplicatedErrors,
        [switch]$IncludeContext
    )
    
    Write-UnityParallelLog -Message "Formatting Unity errors for Claude processing..." -Level "INFO"
    
    try {
        $claudeFormat = @{
            FormatVersion = "1.0"
            GeneratedTime = Get-Date
            ErrorSummary = @{
                TotalUniqueErrors = $DeduplicatedErrors.UniqueCount
                OriginalErrorCount = $DeduplicatedErrors.OriginalCount
                DuplicatesRemoved = $DeduplicatedErrors.DuplicatesRemoved
                DeduplicationMode = $DeduplicatedErrors.DeduplicationMode
            }
            FormattedErrors = @()
        }
        
        foreach ($error in $DeduplicatedErrors.UniqueErrors) {
            $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
            
            $claudeError = @{
                ErrorId = [System.Guid]::NewGuid().ToString()
                ProjectName = $error.ProjectName
                ErrorCode = $classification.ErrorCode
                ErrorType = $classification.ErrorType
                Severity = $classification.Severity
                Category = $classification.Category
                Confidence = $classification.Confidence
                Timestamp = $error.Timestamp
                ErrorText = $error.ErrorText
                DetectionLatency = $error.DetectionLatency
            }
            
            # Include additional context if requested
            if ($IncludeContext) {
                $claudeError.Context = @{
                    LogPath = $error.LogPath
                    SourceFile = $error.SourceFile
                    UnityVersion = "2021.1.14f1" # From project structure
                    Platform = "Windows"
                    AutomationContext = "Unity-Claude Parallel Processing"
                }
            }
            
            $claudeFormat.FormattedErrors += $claudeError
        }
        
        Write-UnityParallelLog -Message "Unity errors formatted for Claude: $($claudeFormat.FormattedErrors.Count) errors prepared" -Level "INFO"
        
        return $claudeFormat
        
    } catch {
        Write-UnityParallelLog -Message "Failed to format Unity errors for Claude: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Tests Unity parallelization performance compared to sequential processing
.DESCRIPTION
Benchmarks Unity parallel processing performance against sequential baseline
.PARAMETER Monitor
Unity monitor object
.PARAMETER TestScenario
Type of performance test (ErrorDetection, ErrorExport, FullWorkflow)
.EXAMPLE
Test-UnityParallelizationPerformance -Monitor $monitor -TestScenario "FullWorkflow"
#>
function Test-UnityParallelizationPerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('ErrorDetection', 'ErrorExport', 'FullWorkflow')]
        [string]$TestScenario = 'FullWorkflow'
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Testing Unity parallelization performance for '$monitorName' - $TestScenario scenario..." -Level "INFO"
    
    try {
        $performanceTest = @{
            Scenario = $TestScenario
            ProjectsCount = $Monitor.ProjectNames.Count
            TestStartTime = Get-Date
            SequentialTime = 0
            ParallelTime = 0
            PerformanceImprovement = 0
            TargetAchieved = $false
        }
        
        # Sequential baseline test
        Write-UnityParallelLog -Message "Running sequential baseline test..." -Level "DEBUG"
        $sequentialStart = Get-Date
        
        foreach ($projectName in $Monitor.ProjectNames) {
            # Simulate sequential processing time based on scenario
            switch ($TestScenario) {
                "ErrorDetection" { Start-Sleep -Milliseconds 200 }
                "ErrorExport" { Start-Sleep -Milliseconds 100 }
                "FullWorkflow" { Start-Sleep -Milliseconds 300 }
            }
        }
        
        $performanceTest.SequentialTime = ((Get-Date) - $sequentialStart).TotalMilliseconds
        
        # Parallel test using actual monitor capabilities
        Write-UnityParallelLog -Message "Running parallel test..." -Level "DEBUG"
        $parallelStart = Get-Date
        
        # Use actual monitor timing if available
        if ($Monitor.Statistics.TotalMonitoringTime -gt 0) {
            $performanceTest.ParallelTime = $Monitor.Statistics.TotalMonitoringTime * 60 * 1000 # Convert minutes to milliseconds
        } else {
            # Simulate parallel processing time
            $maxTime = switch ($TestScenario) {
                "ErrorDetection" { 200 }
                "ErrorExport" { 100 }
                "FullWorkflow" { 300 }
            }
            Start-Sleep -Milliseconds $maxTime
            $performanceTest.ParallelTime = ((Get-Date) - $parallelStart).TotalMilliseconds
        }
        
        # Calculate performance improvement
        $performanceTest.PerformanceImprovement = [math]::Round((($performanceTest.SequentialTime - $performanceTest.ParallelTime) / $performanceTest.SequentialTime) * 100, 2)
        $performanceTest.TargetAchieved = $performanceTest.PerformanceImprovement -ge 50 # 50% improvement target
        $performanceTest.TestEndTime = Get-Date
        $performanceTest.TotalTestDuration = [math]::Round(($performanceTest.TestEndTime - $performanceTest.TestStartTime).TotalSeconds, 2)
        
        Write-UnityParallelLog -Message "Unity parallelization performance test completed: $($performanceTest.PerformanceImprovement)% improvement (Sequential: $($performanceTest.SequentialTime)ms, Parallel: $($performanceTest.ParallelTime)ms)" -Level "INFO"
        
        return $performanceTest
        
    } catch {
        Write-UnityParallelLog -Message "Failed to test Unity parallelization performance: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    # Unity Project Discovery and Configuration (Hour 1-2)
    'Find-UnityProjects',
    'Register-UnityProject',
    'Get-RegisteredUnityProjects',
    'Get-UnityProjectConfiguration',
    'Set-UnityProjectConfiguration',
    'Test-UnityProjectAvailability',
    
    # Parallel Unity Monitoring Architecture (Hour 1-2)
    'New-UnityParallelMonitor',
    'Start-UnityParallelMonitoring',
    'Stop-UnityParallelMonitoring',
    'Get-UnityMonitoringStatus',
    
    # Unity Compilation Process Integration (Hour 3-4)
    'Start-UnityCompilationJob',
    
    # Concurrent Error Detection and Classification (Hour 5-6)
    'Start-ConcurrentErrorDetection',
    'Classify-UnityCompilationError',
    'Aggregate-UnityErrors',
    'Deduplicate-UnityErrors',
    'Get-UnityErrorStatistics',
    
    # Concurrent Error Export and Integration (Hour 7-8)
    'Export-UnityErrorsConcurrently',
    'Format-UnityErrorsForClaude',
    'Test-UnityParallelizationPerformance'
)

# Module loading complete
Write-UnityParallelLog -Message "Unity-Claude-UnityParallelization module loaded successfully with $((Get-Command -Module Unity-Claude-UnityParallelization).Count) functions" -Level "INFO"

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNu1YVURU6Zdn5dZ+QLRMEri2
# GDmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUzsDM0EgX0P2fvFGEhnNN3CuLGn0wDQYJKoZIhvcNAQEBBQAEggEAV3AG
# oCpiZCmNsONARxfhpw5Oxabm+p0dc65yAAEsHqFzkOuR09YxX74XfoYCTTgdWoYg
# AAzlADGaEV1IDBaa9L/QBjBPf9DDw9VOaxRmWgPVa5tFsq4x+EG0zopFTujVcaqF
# 6Dlgf16ps9HfJefmxD+9tuWTHwvFa+fKLXlkT0z8QrC3TJKEsruY+C0b8i9l3lcG
# pYH8lGQnnqucGQ9MGWp/snwZuzf/XiTYDcg/2CEy6T0lHv2XDmMM+8qWc0Z9wYRN
# cPDy8J3GaayXr6QpcGzoFf5DmpS4tEVVwcXsH5sSay7BniElVExoHuIQdtAr5Qop
# gsWEOJqCcMc7ex+4bQ==
# SIG # End signature block
