# Unity-Claude-RunspaceManagement Module (MONOLITHIC VERSION)
# WARNING: This is the deprecated monolithic version. Consider using the refactored modular version.
Write-Warning "[Unity-Claude-RunspaceManagement] Loading MONOLITHIC VERSION (deprecated) - Consider using refactored version"
Write-Warning "[Unity-Claude-RunspaceManagement] The modular version provides better maintainability and performance"

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

# Unity-Claude-RunspaceManagement.psm1
# Phase 1 Week 2 Days 1-2: Session State Configuration
# PowerShell 5.1 compatible runspace pool management with InitialSessionState configuration
# Date: 2025-08-21

$ErrorActionPreference = "Stop"

# Import required modules with fallback logging
$script:WriteAgentLogAvailable = $false
try {
    # Conditional import to preserve script variables - fixes state reset issue
    if (-not (Get-Module Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue)) {
# Removed by Fix-RunspaceManagementNesting: \0
        Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-ParallelProcessing module" -ForegroundColor Gray
    } else {
        Write-Host "[DEBUG] [StatePreservation] Unity-Claude-ParallelProcessing already loaded, preserving state" -ForegroundColor Gray
    }
    $script:WriteAgentLogAvailable = $true
} catch {
    Write-Warning "Failed to import Unity-Claude-ParallelProcessing: $($_.Exception.Message)"
    Write-Warning "Using Write-Host fallback for logging"
}

# Fallback logging function if Write-AgentLog not available
function Write-FallbackLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "RunspaceManagement"
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
function Write-ModuleLog {
    param(
        [string]$Message,
        [string]$Level = "INFO", 
        [string]$Component = "RunspaceManagement"
    )
    
    if ($script:WriteAgentLogAvailable) {
        Write-AgentLog -Message $Message -Level $Level -Component $Component
    } else {
        Write-FallbackLog -Message $Message -Level $Level -Component $Component
    }
}

# Module-level variables for session state management
$script:DefaultSessionConfiguration = @{
    LanguageMode = 'FullLanguage'
    ExecutionPolicy = 'Bypass'
    ApartmentState = 'STA'
    ThreadOptions = 'ReuseThread'
    UseFullLanguage = $true
    EnableProfiling = $false
}

$script:RegisteredModules = @()
$script:RegisteredVariables = @()
$script:ActiveRunspacePools = @{}

# Module loading notification
Write-ModuleLog -Message "Loading Unity-Claude-RunspaceManagement module..." -Level "DEBUG" -Component "RunspaceManagement"

#region InitialSessionState Configuration (Hour 1-3)

<#
.SYNOPSIS
Creates a new InitialSessionState configuration for runspace pools
.DESCRIPTION
Creates an optimized InitialSessionState using research-validated patterns for PowerShell 5.1 compatibility
.PARAMETER UseCreateDefault
Use CreateDefault() for better performance (default) vs CreateDefault2()
.PARAMETER LanguageMode
PowerShell language mode (FullLanguage, ConstrainedLanguage, NoLanguage)
.PARAMETER ExecutionPolicy
Execution policy for the session state
.PARAMETER ApartmentState
Threading apartment state (STA, MTA)
.PARAMETER ThreadOptions
Thread reuse options (ReuseThread, UseNewThread)
.EXAMPLE
$sessionState = New-RunspaceSessionState -LanguageMode FullLanguage
#>
function New-RunspaceSessionState {
    [CmdletBinding()]
    param(
        [switch]$UseCreateDefault = $true,
        [ValidateSet('FullLanguage', 'ConstrainedLanguage', 'NoLanguage')]
        [string]$LanguageMode = 'FullLanguage',
        [ValidateSet('Unrestricted', 'RemoteSigned', 'AllSigned', 'Restricted', 'Default', 'Bypass', 'Undefined')]
        [string]$ExecutionPolicy = 'Bypass',
        [ValidateSet('STA', 'MTA', 'Unknown')]
        [string]$ApartmentState = 'STA',
        [ValidateSet('ReuseThread', 'UseNewThread')]
        [string]$ThreadOptions = 'ReuseThread'
    )
    
    Write-ModuleLog -Message "Creating new InitialSessionState with research-validated configuration..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        # Use CreateDefault() for better performance (research finding: CreateDefault2 is 3-8x slower)
        if ($UseCreateDefault) {
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            Write-ModuleLog -Message "Using CreateDefault() for optimal performance" -Level "DEBUG" -Component "RunspaceManagement"
        } else {
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
            Write-ModuleLog -Message "Using CreateDefault2() with core commands only" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        # Configure session state properties based on research best practices
        # Convert string values to appropriate enum types for PowerShell 5.1 compatibility
        $sessionState.LanguageMode = [System.Management.Automation.PSLanguageMode]$LanguageMode
        
        # Convert ExecutionPolicy string to enum (research-validated approach)
        try {
            $sessionState.ExecutionPolicy = [Microsoft.PowerShell.ExecutionPolicy]$ExecutionPolicy
            Write-ModuleLog -Message "ExecutionPolicy set to $ExecutionPolicy using enum" -Level "DEBUG" -Component "RunspaceManagement"
        } catch {
            # Fallback: Set as string if enum not available
            Write-ModuleLog -Message "ExecutionPolicy enum not available, using string fallback" -Level "WARNING" -Component "RunspaceManagement"
            # Note: InitialSessionState may handle string-to-enum conversion internally
        }
        
        # Convert ApartmentState string to enum
        $sessionState.ApartmentState = [System.Threading.ApartmentState]$ApartmentState
        
        # Convert ThreadOptions string to enum  
        $sessionState.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]$ThreadOptions
        
        # Add metadata for tracking
        $sessionMetadata = @{
            Created = Get-Date
            LanguageMode = $LanguageMode
            ExecutionPolicy = $ExecutionPolicy
            ApartmentState = $ApartmentState
            ThreadOptions = $ThreadOptions
            UseCreateDefault = $UseCreateDefault
            ModulesCount = 0
            VariablesCount = 0
        }
        
        # Return session state with metadata
        $result = @{
            SessionState = $sessionState
            Metadata = $sessionMetadata
        }
        
        Write-ModuleLog -Message "InitialSessionState created successfully with $LanguageMode language mode" -Level "INFO" -Component "RunspaceManagement"
        return $result
        
    } catch {
        Write-ModuleLog -Message "Failed to create InitialSessionState: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Sets configuration for session state creation
.DESCRIPTION
Configures default settings for session state creation across the module
.PARAMETER Configuration
Hashtable containing configuration settings
.EXAMPLE
Set-SessionStateConfiguration -Configuration @{LanguageMode='FullLanguage'; ExecutionPolicy='Bypass'}
#>
function Set-SessionStateConfiguration {
    [CmdletBinding()]
    param(
        [hashtable]$Configuration
    )
    
    Write-ModuleLog -Message "Updating session state configuration..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        foreach ($key in $Configuration.Keys) {
            if ($script:DefaultSessionConfiguration.ContainsKey($key)) {
                $oldValue = $script:DefaultSessionConfiguration[$key]
                $script:DefaultSessionConfiguration[$key] = $Configuration[$key]
                Write-ModuleLog -Message "Updated $key from $oldValue to $($Configuration[$key])" -Level "DEBUG" -Component "RunspaceManagement"
            } else {
                Write-ModuleLog -Message "Unknown configuration key: $key" -Level "WARNING" -Component "RunspaceManagement"
            }
        }
        
        Write-ModuleLog -Message "Session state configuration updated successfully" -Level "INFO" -Component "RunspaceManagement"
        
    } catch {
        Write-ModuleLog -Message "Failed to set session state configuration: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Adds a PowerShell module to session state
.DESCRIPTION
Adds a module to the InitialSessionState for pre-loading in runspace pools
.PARAMETER SessionStateConfig
Session state configuration object from New-RunspaceSessionState
.PARAMETER ModuleName
Name of the module to add
.PARAMETER ModulePath
Optional path to the module
.EXAMPLE
Add-SessionStateModule -SessionStateConfig $config -ModuleName "Unity-Claude-Core"
#>
function Add-SessionStateModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [string]$ModulePath
    )
    
    Write-ModuleLog -Message "Adding module $ModuleName to session state..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        if ($ModulePath) {
            # Import module from specific path
            $sessionState.ImportPSModule($ModulePath)
            Write-ModuleLog -Message "Added module $ModuleName from path: $ModulePath" -Level "DEBUG" -Component "RunspaceManagement"
        } else {
            # Import module by name (must be in PSModulePath)
            $sessionState.ImportPSModule($ModuleName)
            Write-ModuleLog -Message "Added module $ModuleName from PSModulePath" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        # Update metadata
        $SessionStateConfig.Metadata.ModulesCount++
        $script:RegisteredModules += @{
            Name = $ModuleName
            Path = $ModulePath
            Added = Get-Date
        }
        
        Write-ModuleLog -Message "Module $ModuleName added successfully to session state" -Level "INFO" -Component "RunspaceManagement"
        
    } catch {
        Write-ModuleLog -Message "Failed to add module $ModuleName to session state: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Adds a variable to session state
.DESCRIPTION
Creates a SessionStateVariableEntry and adds it to the InitialSessionState
.PARAMETER SessionStateConfig
Session state configuration object from New-RunspaceSessionState
.PARAMETER Name
Variable name
.PARAMETER Value
Variable value
.PARAMETER Description
Optional variable description
.EXAMPLE
Add-SessionStateVariable -SessionStateConfig $config -Name "GlobalData" -Value $myData
#>
function Add-SessionStateVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        $Value,
        [string]$Description = ""
    )
    
    Write-ModuleLog -Message "Adding variable $Name to session state..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Create SessionStateVariableEntry using research-validated pattern
        $variableEntry = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Name, $Value, $Description
        
        # Add to session state
        $sessionState.Variables.Add($variableEntry)
        
        # Update metadata
        $SessionStateConfig.Metadata.VariablesCount++
        $script:RegisteredVariables += @{
            Name = $Name
            Type = $Value.GetType().Name
            Description = $Description
            Added = Get-Date
        }
        
        Write-ModuleLog -Message "Variable $Name added successfully to session state" -Level "INFO" -Component "RunspaceManagement"
        
    } catch {
        Write-ModuleLog -Message "Failed to add variable $Name to session state: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Tests session state configuration validity
.DESCRIPTION
Validates that session state configuration is properly set up for runspace pools
.PARAMETER SessionStateConfig
Session state configuration object to test
.EXAMPLE
Test-SessionStateConfiguration -SessionStateConfig $config
#>
function Test-SessionStateConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig
    )
    
    Write-ModuleLog -Message "Testing session state configuration..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        $metadata = $SessionStateConfig.Metadata
        
        # Validation checks
        $validationResults = @{
            SessionStateExists = $null -ne $sessionState
            LanguageModeSet = $null -ne $sessionState.LanguageMode
            ExecutionPolicySet = $null -ne $sessionState.ExecutionPolicy
            ApartmentStateSet = $null -ne $sessionState.ApartmentState
            ThreadOptionsSet = $null -ne $sessionState.ThreadOptions
            MetadataExists = $null -ne $metadata
            ModulesCount = $metadata.ModulesCount
            VariablesCount = $metadata.VariablesCount
        }
        
        # Calculate validation score
        $validationScore = ($validationResults.GetEnumerator() | Where-Object { $_.Value -eq $true }).Count
        $totalChecks = ($validationResults.GetEnumerator() | Where-Object { $_.Key -notlike "*Count" }).Count
        $validationPercentage = [math]::Round(($validationScore / $totalChecks) * 100, 2)
        
        $validationResults.ValidationScore = $validationPercentage
        $validationResults.IsValid = $validationPercentage -ge 80
        
        Write-ModuleLog -Message "Session state validation completed: $validationPercentage% ($validationScore/$totalChecks checks passed)" -Level "INFO" -Component "RunspaceManagement"
        
        return $validationResults
        
    } catch {
        Write-ModuleLog -Message "Failed to test session state configuration: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

#endregion

#region Module/Variable Pre-loading (Hour 4-6)

<#
.SYNOPSIS
Imports critical Unity-Claude modules into session state
.DESCRIPTION
Pre-loads essential modules for Unity-Claude automation in runspace pool session state
.PARAMETER SessionStateConfig
Session state configuration object
.PARAMETER ModuleList
Array of module names to import (defaults to critical Unity-Claude modules)
.EXAMPLE
Import-SessionStateModules -SessionStateConfig $config
#>
function Import-SessionStateModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [string[]]$ModuleList = @(
            'Unity-Claude-ParallelProcessing',
            'Unity-Claude-SystemStatus'
        )
    )
    
    Write-ModuleLog -Message "Importing critical Unity-Claude modules into session state..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $importedCount = 0
        $failedCount = 0
        
        foreach ($moduleName in $ModuleList) {
            try {
                # Check if module exists in current session first
                $moduleExists = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue
                
                if ($moduleExists) {
                    Add-SessionStateModule -SessionStateConfig $SessionStateConfig -ModuleName $moduleName
                    $importedCount++
                    Write-ModuleLog -Message "Successfully imported module: $moduleName" -Level "DEBUG" -Component "RunspaceManagement"
                } else {
                    Write-ModuleLog -Message "Module not found: $moduleName" -Level "WARNING" -Component "RunspaceManagement"
                    $failedCount++
                }
            } catch {
                Write-ModuleLog -Message "Failed to import module ${moduleName}: $($_.Exception.Message)" -Level "WARNING" -Component "RunspaceManagement"
                $failedCount++
            }
        }
        
        $result = @{
            ImportedCount = $importedCount
            FailedCount = $failedCount
            TotalModules = $ModuleList.Count
            SuccessRate = [math]::Round(($importedCount / $ModuleList.Count) * 100, 2)
        }
        
        Write-ModuleLog -Message "Module import completed: $importedCount/$($ModuleList.Count) modules imported successfully ($($result.SuccessRate)%)" -Level "INFO" -Component "RunspaceManagement"
        
        return $result
        
    } catch {
        Write-ModuleLog -Message "Failed to import session state modules: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Initializes critical variables in session state
.DESCRIPTION
Pre-loads essential variables for Unity-Claude automation in runspace pool session state
.PARAMETER SessionStateConfig
Session state configuration object
.PARAMETER Variables
Hashtable of variables to initialize
.EXAMPLE
Initialize-SessionStateVariables -SessionStateConfig $config -Variables @{GlobalStatus=$statusData}
#>
function Initialize-SessionStateVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [hashtable]$Variables = @{}
    )
    
    Write-ModuleLog -Message "Initializing critical variables in session state..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        # Add default Unity-Claude variables
        $defaultVariables = @{
            'UnityClaudeVersion' = '2.0.0'
            'AutomationStartTime' = Get-Date
            'RunspaceMode' = 'Pool'
            'ThreadSafeLogging' = $true
        }
        
        # Merge with provided variables
        $allVariables = $defaultVariables.Clone()
        foreach ($key in $Variables.Keys) {
            $allVariables[$key] = $Variables[$key]
        }
        
        $initializedCount = 0
        
        foreach ($varName in $allVariables.Keys) {
            try {
                Add-SessionStateVariable -SessionStateConfig $SessionStateConfig -Name $varName -Value $allVariables[$varName] -Description "Unity-Claude automation variable"
                $initializedCount++
                Write-ModuleLog -Message "Initialized variable: $varName" -Level "DEBUG" -Component "RunspaceManagement"
            } catch {
                Write-ModuleLog -Message "Failed to initialize variable ${varName}: $($_.Exception.Message)" -Level "WARNING" -Component "RunspaceManagement"
            }
        }
        
        $result = @{
            InitializedCount = $initializedCount
            TotalVariables = $allVariables.Count
            SuccessRate = [math]::Round(($initializedCount / $allVariables.Count) * 100, 2)
        }
        
        Write-ModuleLog -Message "Variable initialization completed: $initializedCount/$($allVariables.Count) variables initialized ($($result.SuccessRate)%)" -Level "INFO" -Component "RunspaceManagement"
        
        return $result
        
    } catch {
        Write-ModuleLog -Message "Failed to initialize session state variables: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Gets list of modules in session state
.DESCRIPTION
Returns information about modules configured in the session state
.PARAMETER SessionStateConfig
Session state configuration object
.EXAMPLE
Get-SessionStateModules -SessionStateConfig $config
#>
function Get-SessionStateModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig
    )
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Get modules from session state (this is limited in PowerShell 5.1)
        $moduleInfo = @{
            RegisteredModules = $script:RegisteredModules
            ModuleCount = $SessionStateConfig.Metadata.ModulesCount
            LastUpdate = Get-Date
        }
        
        Write-ModuleLog -Message "Retrieved session state modules: $($moduleInfo.ModuleCount) modules" -Level "INFO" -Component "RunspaceManagement"
        
        return $moduleInfo
        
    } catch {
        Write-ModuleLog -Message "Failed to get session state modules: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Gets list of variables in session state
.DESCRIPTION
Returns information about variables configured in the session state
.PARAMETER SessionStateConfig
Session state configuration object
.EXAMPLE
Get-SessionStateVariables -SessionStateConfig $config
#>
function Get-SessionStateVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig
    )
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Get variables from session state
        $variableInfo = @{
            RegisteredVariables = $script:RegisteredVariables
            VariableCount = $SessionStateConfig.Metadata.VariablesCount
            SessionStateVariables = @()
            LastUpdate = Get-Date
        }
        
        # Get variables from session state (limited access in PowerShell 5.1)
        try {
            $variableInfo.SessionStateVariables = $sessionState.Variables | ForEach-Object { 
                @{
                    Name = $_.Name
                    Type = if ($_.Value) { $_.Value.GetType().Name } else { "Unknown" }
                    Description = $_.Description
                }
            }
        } catch {
            Write-ModuleLog -Message "Unable to enumerate session state variables directly" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        Write-ModuleLog -Message "Retrieved session state variables: $($variableInfo.VariableCount) variables" -Level "INFO" -Component "RunspaceManagement"
        
        return $variableInfo
        
    } catch {
        Write-ModuleLog -Message "Failed to get session state variables: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

#endregion

#region SessionStateVariableEntry Sharing (Hour 7-8)

<#
.SYNOPSIS
Creates a new SessionStateVariableEntry
.DESCRIPTION
Creates a SessionStateVariableEntry using research-validated patterns for thread-safe variable sharing
.PARAMETER Name
Variable name
.PARAMETER Value
Variable value
.PARAMETER Description
Variable description
.PARAMETER Options
Variable options (None, ReadOnly, Constant, Private, AllScope)
.EXAMPLE
$entry = New-SessionStateVariableEntry -Name "SharedData" -Value $data -Description "Shared data between runspaces"
#>
function New-SessionStateVariableEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        $Value,
        [string]$Description = "",
        [System.Management.Automation.ScopedItemOptions]$Options = 'None'
    )
    
    Write-ModuleLog -Message "Creating SessionStateVariableEntry for $Name..." -Level "DEBUG" -Component "RunspaceManagement"
    
    try {
        # Create SessionStateVariableEntry using research-validated pattern
        $variableEntry = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Name, $Value, $Description, $Options
        
        Write-ModuleLog -Message "Created SessionStateVariableEntry for $Name successfully" -Level "DEBUG" -Component "RunspaceManagement"
        
        return $variableEntry
        
    } catch {
        Write-ModuleLog -Message "Failed to create SessionStateVariableEntry for ${Name}: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Adds a shared variable to session state
.DESCRIPTION
Adds a variable that will be shared across all runspaces in the pool
.PARAMETER SessionStateConfig
Session state configuration object
.PARAMETER Name
Variable name
.PARAMETER Value
Variable value
.PARAMETER Description
Variable description
.PARAMETER MakeThreadSafe
If true, wraps collections in synchronized wrappers
.EXAMPLE
Add-SharedVariable -SessionStateConfig $config -Name "SharedQueue" -Value $queue -MakeThreadSafe
#>
function Add-SharedVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        $Value,
        [string]$Description = "Shared variable across runspaces",
        [switch]$MakeThreadSafe
    )
    
    Write-ModuleLog -Message "Adding shared variable $Name to session state..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $finalValue = $Value
        
        # Make thread-safe if requested and applicable
        if ($MakeThreadSafe) {
            if ($Value -is [hashtable]) {
                $finalValue = [hashtable]::Synchronized($Value)
                Write-ModuleLog -Message "Made hashtable $Name thread-safe" -Level "DEBUG" -Component "RunspaceManagement"
            } elseif ($Value -is [System.Collections.ArrayList]) {
                $finalValue = [System.Collections.ArrayList]::Synchronized($Value)
                Write-ModuleLog -Message "Made ArrayList $Name thread-safe" -Level "DEBUG" -Component "RunspaceManagement"
            } else {
                Write-ModuleLog -Message "Cannot make $Name thread-safe - unsupported type: $($Value.GetType().Name)" -Level "WARNING" -Component "RunspaceManagement"
            }
        }
        
        # Add to session state
        Add-SessionStateVariable -SessionStateConfig $SessionStateConfig -Name $Name -Value $finalValue -Description $Description
        
        Write-ModuleLog -Message "Shared variable $Name added successfully" -Level "INFO" -Component "RunspaceManagement"
        
    } catch {
        Write-ModuleLog -Message "Failed to add shared variable ${Name}: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Gets a shared variable value (not available in session state context)
.DESCRIPTION
This function is for documentation purposes - shared variables are accessed directly in runspace context
.PARAMETER Name
Variable name
.EXAMPLE
# In runspace context: $value = $SharedVariableName
Get-SharedVariable -Name "SharedData"
#>
function Get-SharedVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    Write-ModuleLog -Message "Note: Shared variables are accessed directly in runspace context as dollar-sign-$Name" -Level "INFO" -Component "RunspaceManagement"
    
    # Return information about how to access the variable
    return @{
        VariableName = $Name
        AccessPattern = "`$$Name"
        Note = "Access this variable directly in runspace scriptblocks using `$$Name"
    }
}

<#
.SYNOPSIS
Sets a shared variable value (not available in session state context)
.DESCRIPTION
This function is for documentation purposes - shared variables are modified directly in runspace context
.PARAMETER Name
Variable name
.PARAMETER Value
New value
.EXAMPLE
# In runspace context: $SharedVariableName = $newValue
Set-SharedVariable -Name "SharedData" -Value $newValue
#>
function Set-SharedVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        $Value
    )
    
    Write-ModuleLog -Message "Note: Shared variables are modified directly in runspace context as dollar-sign-$Name = dollar-sign-value" -Level "INFO" -Component "RunspaceManagement"
    
    # Return information about how to modify the variable
    return @{
        VariableName = $Name
        ModificationPattern = "`$$Name = `$newValue"
        Note = "Modify this variable directly in runspace scriptblocks using assignment"
        ThreadSafetyNote = "Ensure thread-safe operations when modifying shared variables"
    }
}

<#
.SYNOPSIS
Removes a shared variable (not available in session state context)
.DESCRIPTION
This function is for documentation purposes - shared variables cannot be removed from session state after creation
.PARAMETER Name
Variable name
.EXAMPLE
Remove-SharedVariable -Name "SharedData"
#>
function Remove-SharedVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    Write-ModuleLog -Message "Note: Shared variables cannot be removed from InitialSessionState after runspace pool creation" -Level "WARNING" -Component "RunspaceManagement"
    
    return @{
        VariableName = $Name
        Note = "SessionState variables cannot be removed after runspace pool is created"
        Alternative = "Set variable to null or empty value in runspace context"
    }
}

#endregion

#region Runspace Pool Management

<#
.SYNOPSIS
Creates a new managed runspace pool with configured session state
.DESCRIPTION
Creates a runspace pool using research-validated patterns with proper session state configuration
.PARAMETER SessionStateConfig
Session state configuration object
.PARAMETER MinRunspaces
Minimum number of runspaces in the pool
.PARAMETER MaxRunspaces
Maximum number of runspaces in the pool
.PARAMETER Name
Optional name for the runspace pool
.EXAMPLE
$pool = New-ManagedRunspacePool -SessionStateConfig $config -MinRunspaces 1 -MaxRunspaces 5
#>
function New-ManagedRunspacePool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [int]$MinRunspaces = 1,
        [int]$MaxRunspaces = 5,
        [string]$Name = "Unity-Claude-Pool-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    )
    
    Write-ModuleLog -Message "Creating managed runspace pool '$Name' with $MinRunspaces-$MaxRunspaces runspaces..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Create runspace pool using research-validated pattern
        $runspacePool = [runspacefactory]::CreateRunspacePool($MinRunspaces, $MaxRunspaces, $sessionState, $Host)
        
        # Create pool management object
        $poolManager = @{
            RunspacePool = $runspacePool
            Name = $Name
            MinRunspaces = $MinRunspaces
            MaxRunspaces = $MaxRunspaces
            SessionStateConfig = $SessionStateConfig
            Created = Get-Date
            Status = 'Created'
            ActiveJobs = @()
            CompletedJobs = @()
            Statistics = @{
                JobsSubmitted = 0
                JobsCompleted = 0
                JobsFailed = 0
                AverageExecutionTimeMs = 0
            }
        }
        
        # Register pool
        $script:ActiveRunspacePools[$Name] = $poolManager
        
        Write-ModuleLog -Message "Managed runspace pool '$Name' created successfully" -Level "INFO" -Component "RunspaceManagement"
        
        return $poolManager
        
    } catch {
        Write-ModuleLog -Message "Failed to create managed runspace pool '$Name': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Opens a runspace pool for use
.DESCRIPTION
Opens the runspace pool and makes it available for job execution
.PARAMETER PoolManager
Pool manager object from New-ManagedRunspacePool
.EXAMPLE
Open-RunspacePool -PoolManager $poolManager
#>
function Open-RunspacePool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Opening runspace pool '$poolName'..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        
        # Open the pool
        $runspacePool.Open()
        
        # Update status
        $PoolManager.Status = 'Open'
        $PoolManager.Opened = Get-Date
        
        Write-ModuleLog -Message "Runspace pool '$poolName' opened successfully (State: $($runspacePool.RunspacePoolStateInfo.State))" -Level "INFO" -Component "RunspaceManagement"
        
        return @{
            Success = $true
            State = $runspacePool.RunspacePoolStateInfo.State
            AvailableRunspaces = $runspacePool.GetAvailableRunspaces()
            MaxRunspaces = $runspacePool.GetMaxRunspaces()
        }
        
    } catch {
        Write-ModuleLog -Message "Failed to open runspace pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        $PoolManager.Status = 'Failed'
        throw
    }
}

<#
.SYNOPSIS
Closes a runspace pool
.DESCRIPTION
Closes the runspace pool and cleans up resources
.PARAMETER PoolManager
Pool manager object
.PARAMETER Force
Force close even if jobs are running
.EXAMPLE
Close-RunspacePool -PoolManager $poolManager
#>
function Close-RunspacePool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [switch]$Force
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Closing runspace pool '$poolName'..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        
        # Check for active jobs
        if ($PoolManager.ActiveJobs.Count -gt 0 -and -not $Force) {
            Write-ModuleLog -Message "Cannot close pool '$poolName' - $($PoolManager.ActiveJobs.Count) active jobs running. Use -Force to override." -Level "WARNING" -Component "RunspaceManagement"
            return @{
                Success = $false
                Reason = "ActiveJobs"
                ActiveJobCount = $PoolManager.ActiveJobs.Count
            }
        }
        
        # Close the pool
        $runspacePool.Close()
        
        # Update status
        $PoolManager.Status = 'Closed'
        $PoolManager.Closed = Get-Date
        
        # Remove from active pools
        $script:ActiveRunspacePools.Remove($poolName)
        
        Write-ModuleLog -Message "Runspace pool '$poolName' closed successfully" -Level "INFO" -Component "RunspaceManagement"
        
        return @{
            Success = $true
            State = $runspacePool.RunspacePoolStateInfo.State
            Statistics = $PoolManager.Statistics
        }
        
    } catch {
        Write-ModuleLog -Message "Failed to close runspace pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Gets runspace pool status
.DESCRIPTION
Returns current status and statistics for a runspace pool
.PARAMETER PoolManager
Pool manager object
.EXAMPLE
Get-RunspacePoolStatus -PoolManager $poolManager
#>
function Get-RunspacePoolStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        $poolName = $PoolManager.Name
        
        $status = @{
            Name = $poolName
            Status = $PoolManager.Status
            State = $runspacePool.RunspacePoolStateInfo.State
            Created = $PoolManager.Created
            MinRunspaces = $PoolManager.MinRunspaces
            MaxRunspaces = $PoolManager.MaxRunspaces
            AvailableRunspaces = 0
            ActiveJobs = $PoolManager.ActiveJobs.Count
            Statistics = $PoolManager.Statistics
            SessionStateInfo = @{
                ModulesCount = $PoolManager.SessionStateConfig.Metadata.ModulesCount
                VariablesCount = $PoolManager.SessionStateConfig.Metadata.VariablesCount
                LanguageMode = $PoolManager.SessionStateConfig.Metadata.LanguageMode
            }
        }
        
        # Get available runspaces if pool is open
        if ($PoolManager.Status -eq 'Open') {
            try {
                $status.AvailableRunspaces = $runspacePool.GetAvailableRunspaces()
            } catch {
                $status.AvailableRunspaces = "Unknown"
            }
        }
        
        return $status
        
    } catch {
        Write-ModuleLog -Message "Failed to get runspace pool status: $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Tests runspace pool health
.DESCRIPTION
Performs health checks on a runspace pool to ensure it's functioning properly
.PARAMETER PoolManager
Pool manager object
.EXAMPLE
Test-RunspacePoolHealth -PoolManager $poolManager
#>
function Test-RunspacePoolHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Testing health of runspace pool '$poolName'..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        
        $healthChecks = @{
            PoolExists = $null -ne $runspacePool
            StateValid = $runspacePool.RunspacePoolStateInfo.State -in @('Opened', 'Opening')
            NoErrors = $null -eq $runspacePool.RunspacePoolStateInfo.Reason
            HasAvailableRunspaces = $false
            SessionStateConfigured = $null -ne $PoolManager.SessionStateConfig
            ManagerStatusConsistent = $PoolManager.Status -eq 'Open'
        }
        
        # Check available runspaces
        if ($healthChecks.StateValid) {
            try {
                $availableRunspaces = $runspacePool.GetAvailableRunspaces()
                $healthChecks.HasAvailableRunspaces = $availableRunspaces -gt 0
                $healthChecks.AvailableRunspaces = $availableRunspaces
            } catch {
                $healthChecks.HasAvailableRunspaces = $false
                $healthChecks.AvailableRunspaces = 0
            }
        }
        
        # Calculate health score
        $healthScore = ($healthChecks.GetEnumerator() | Where-Object { $_.Value -eq $true }).Count
        $totalChecks = ($healthChecks.GetEnumerator() | Where-Object { $_.Key -notlike "*Runspaces" }).Count
        $healthPercentage = [math]::Round(($healthScore / $totalChecks) * 100, 2)
        
        $healthChecks.HealthScore = $healthPercentage
        $healthChecks.IsHealthy = $healthPercentage -ge 80
        
        $healthStatus = if ($healthChecks.IsHealthy) { "Healthy" } else { "Unhealthy" }
        Write-ModuleLog -Message "Runspace pool '$poolName' health check completed: $healthStatus ($healthPercentage%)" -Level "INFO" -Component "RunspaceManagement"
        
        return $healthChecks
        
    } catch {
        Write-ModuleLog -Message "Failed to test runspace pool health for '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        return @{
            PoolExists = $false
            IsHealthy = $false
            HealthScore = 0
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Production Runspace Pool Infrastructure (Hour 1-2)

<#
.SYNOPSIS
Creates a production-ready runspace pool with comprehensive job management
.DESCRIPTION
Implements enterprise-grade runspace pool with proper lifecycle management, job tracking, and memory leak prevention
.PARAMETER SessionStateConfig
Session state configuration from New-RunspaceSessionState
.PARAMETER MinRunspaces
Minimum number of runspaces in pool
.PARAMETER MaxRunspaces
Maximum number of runspaces in pool (throttle limit)
.PARAMETER Name
Pool name for tracking and management
.PARAMETER EnableResourceMonitoring
Enable CPU and memory monitoring during pool operations
.EXAMPLE
$pool = New-ProductionRunspacePool -SessionStateConfig $config -MaxRunspaces 5 -EnableResourceMonitoring
#>
function New-ProductionRunspacePool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [int]$MinRunspaces = 1,
        [int]$MaxRunspaces = [Environment]::ProcessorCount,
        [string]$Name = "Unity-Claude-Production-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
        [switch]$EnableResourceMonitoring
    )
    
    Write-ModuleLog -Message "Creating production runspace pool '$Name' with research-validated patterns..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Create runspace pool using research-validated pattern
        $runspacePool = [runspacefactory]::CreateRunspacePool($MinRunspaces, $MaxRunspaces, $sessionState, $Host)
        
        # Configure for optimal performance (research finding: MTA for better performance)
        $runspacePool.ApartmentState = 'MTA'
        
        # Create comprehensive pool manager with job tracking
        $poolManager = @{
            RunspacePool = $runspacePool
            Name = $Name
            MinRunspaces = $MinRunspaces
            MaxRunspaces = $MaxRunspaces
            SessionStateConfig = $SessionStateConfig
            Created = Get-Date
            Status = 'Created'
            
            # Job management infrastructure
            ActiveJobs = [System.Collections.ArrayList]::new()
            CompletedJobs = [System.Collections.ArrayList]::new()
            FailedJobs = [System.Collections.ArrayList]::new()
            JobQueue = [System.Collections.Queue]::new()
            
            # Performance and resource tracking
            Statistics = @{
                JobsSubmitted = 0
                JobsCompleted = 0
                JobsFailed = 0
                JobsCancelled = 0
                AverageExecutionTimeMs = 0
                TotalExecutionTimeMs = 0
                PeakMemoryUsageMB = 0
                PeakCpuPercent = 0
            }
            
            # Resource monitoring configuration
            ResourceMonitoring = @{
                Enabled = $EnableResourceMonitoring
                CpuThreshold = 80
                MemoryThresholdMB = 1000
                MonitoringInterval = 1000
                LastCpuCheck = $null
                LastMemoryCheck = $null
            }
            
            # Cleanup tracking to prevent memory leaks
            DisposalTracking = @{
                PowerShellInstancesCreated = 0
                PowerShellInstancesDisposed = 0
                RunspacesCreated = 0
                RunspacesDisposed = 0
            }
        }
        
        # Register pool for management
        $script:ActiveRunspacePools[$Name] = $poolManager
        
        Write-ModuleLog -Message "Production runspace pool '$Name' created successfully (Min: $MinRunspaces, Max: $MaxRunspaces)" -Level "INFO" -Component "RunspaceManagement"
        
        return $poolManager
        
    } catch {
        Write-ModuleLog -Message "Failed to create production runspace pool '$Name': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Submits a job to the runspace pool with comprehensive tracking
.DESCRIPTION
Submits PowerShell scriptblock to runspace pool using research-validated BeginInvoke patterns
.PARAMETER PoolManager
Pool manager object from New-ProductionRunspacePool
.PARAMETER ScriptBlock
PowerShell scriptblock to execute
.PARAMETER Parameters
Hashtable of parameters to pass to scriptblock
.PARAMETER JobName
Optional job name for tracking
.PARAMETER Priority
Job priority (High, Normal, Low)
.PARAMETER TimeoutSeconds
Job timeout in seconds
.EXAMPLE
$job = Submit-RunspaceJob -PoolManager $pool -ScriptBlock {param($x) $x * 2} -Parameters @{x=5}
#>
function Submit-RunspaceJob {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        [hashtable]$Parameters = @{},
        [string]$JobName = "Job-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')",
        [ValidateSet('High', 'Normal', 'Low')]
        [string]$Priority = 'Normal',
        [int]$TimeoutSeconds = 300
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Submitting job '$JobName' to runspace pool '$poolName'..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        # Check pool state
        if ($PoolManager.Status -ne 'Open') {
            throw "Runspace pool '$poolName' is not open (Status: $($PoolManager.Status))"
        }
        
        # Create PowerShell instance
        $powerShell = [powershell]::Create()
        $powerShell.RunspacePool = $PoolManager.RunspacePool
        
        # Add script and parameters
        $powerShell.AddScript($ScriptBlock)
        foreach ($paramKey in $Parameters.Keys) {
            $powerShell.AddParameter($paramKey, $Parameters[$paramKey])
        }
        
        # Create job object with comprehensive tracking
        $job = @{
            JobId = [System.Guid]::NewGuid().ToString()
            JobName = $JobName
            PowerShell = $powerShell
            AsyncResult = $null
            ScriptBlock = $ScriptBlock
            Parameters = $Parameters
            Priority = $Priority
            TimeoutSeconds = $TimeoutSeconds
            SubmittedTime = Get-Date
            StartedTime = $null
            CompletedTime = $null
            Status = 'Queued'
            Result = $null
            Error = $null
            ExecutionTimeMs = 0
        }
        
        # Start execution using research-validated BeginInvoke pattern
        $job.AsyncResult = $powerShell.BeginInvoke()
        $job.Status = 'Running'
        $job.StartedTime = Get-Date
        
        # Add to active jobs tracking
        $null = $PoolManager.ActiveJobs.Add($job)
        $PoolManager.Statistics.JobsSubmitted++
        
        # Update disposal tracking
        $PoolManager.DisposalTracking.PowerShellInstancesCreated++
        
        Write-ModuleLog -Message "Job '$JobName' submitted successfully (JobId: $($job.JobId))" -Level "INFO" -Component "RunspaceManagement"
        
        return $job
        
    } catch {
        Write-ModuleLog -Message "Failed to submit job '${JobName}': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Monitors runspace pool jobs and updates completion status
.DESCRIPTION
Monitors all active jobs in runspace pool and updates their completion status with proper error handling
.PARAMETER PoolManager
Pool manager object
.PARAMETER ProcessCompletedJobs
Automatically process completed jobs and retrieve results
.EXAMPLE
Update-RunspaceJobStatus -PoolManager $pool -ProcessCompletedJobs
#>
function Update-RunspaceJobStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [switch]$ProcessCompletedJobs
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Updating job status for runspace pool '$poolName'..." -Level "DEBUG" -Component "RunspaceManagement"
    
    try {
        $completedJobs = @()
        $activeJobsCount = $PoolManager.ActiveJobs.Count
        
        # Check each active job for completion
        for ($i = 0; $i -lt $PoolManager.ActiveJobs.Count; $i++) {
            $job = $PoolManager.ActiveJobs[$i]
            
            try {
                # Check if job completed
                if ($job.AsyncResult.IsCompleted) {
                    $job.CompletedTime = Get-Date
                    $job.ExecutionTimeMs = [math]::Round(($job.CompletedTime - $job.StartedTime).TotalMilliseconds, 2)
                    
                    # Process completion based on research-validated patterns
                    if ($ProcessCompletedJobs) {
                        try {
                            # Retrieve results using EndInvoke (research: check state first)
                            $job.Result = $job.PowerShell.EndInvoke($job.AsyncResult)
                            $job.Status = 'Completed'
                            
                            # Move to completed jobs
                            $null = $PoolManager.CompletedJobs.Add($job)
                            $PoolManager.Statistics.JobsCompleted++
                            
                            Write-ModuleLog -Message "Job '$($job.JobName)' completed successfully in $($job.ExecutionTimeMs)ms" -Level "DEBUG" -Component "RunspaceManagement"
                            
                        } catch {
                            # Handle EndInvoke errors (research: common issue with stopped pipelines)
                            $job.Error = $_.Exception
                            $job.Status = 'Failed'
                            
                            # Move to failed jobs
                            $null = $PoolManager.FailedJobs.Add($job)
                            $PoolManager.Statistics.JobsFailed++
                            
                            Write-ModuleLog -Message "Job '$($job.JobName)' failed: $($_.Exception.Message)" -Level "WARNING" -Component "RunspaceManagement"
                        }
                        
                        # Proper disposal sequence (research-validated: EndInvoke → Runspace.Dispose → PowerShell.Dispose)
                        try {
                            if ($job.PowerShell.Runspace) {
                                $job.PowerShell.Runspace.Dispose()
                            }
                            $job.PowerShell.Dispose()
                            $PoolManager.DisposalTracking.PowerShellInstancesDisposed++
                            
                        } catch {
                            Write-ModuleLog -Message "Disposal error for job '$($job.JobName)': $($_.Exception.Message)" -Level "WARNING" -Component "RunspaceManagement"
                        }
                    } else {
                        $job.Status = 'Ready'
                    }
                    
                    $completedJobs += $job
                }
                
                # Check for timeout (research-validated timeout pattern)
                elseif ($job.TimeoutSeconds -gt 0) {
                    $runtimeSeconds = ((Get-Date) - $job.StartedTime).TotalSeconds
                    if ($runtimeSeconds -gt $job.TimeoutSeconds) {
                        $job.Status = 'TimedOut'
                        $job.CompletedTime = Get-Date
                        $job.ExecutionTimeMs = [math]::Round(($job.CompletedTime - $job.StartedTime).TotalMilliseconds, 2)
                        
                        # Cancel timed out job
                        try {
                            $job.PowerShell.Stop()
                            $job.Result = $job.PowerShell.EndInvoke($job.AsyncResult)
                        } catch {
                            $job.Error = "Timeout after $($job.TimeoutSeconds) seconds: $($_.Exception.Message)"
                        }
                        
                        # Cleanup timed out job
                        try {
                            if ($job.PowerShell.Runspace) {
                                $job.PowerShell.Runspace.Dispose()
                            }
                            $job.PowerShell.Dispose()
                            $PoolManager.DisposalTracking.PowerShellInstancesDisposed++
                        } catch {
                            Write-ModuleLog -Message "Cleanup error for timed out job '$($job.JobName)': $($_.Exception.Message)" -Level "WARNING" -Component "RunspaceManagement"
                        }
                        
                        $null = $PoolManager.FailedJobs.Add($job)
                        $PoolManager.Statistics.JobsCancelled++
                        $completedJobs += $job
                        
                        Write-ModuleLog -Message "Job '$($job.JobName)' timed out after $($job.TimeoutSeconds) seconds" -Level "WARNING" -Component "RunspaceManagement"
                    }
                }
                
            } catch {
                Write-ModuleLog -Message "Error monitoring job '$($job.JobName)': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
            }
        }
        
        # Remove completed jobs from active list
        foreach ($completedJob in $completedJobs) {
            $PoolManager.ActiveJobs.Remove($completedJob)
        }
        
        # Update statistics (Learning #21: Use manual iteration for hashtable property access)
        if ($PoolManager.Statistics.JobsCompleted -gt 0) {
            # Manual iteration to avoid Measure-Object hashtable property access issue
            $totalTime = 0
            foreach ($job in $PoolManager.CompletedJobs) {
                if ($job.ExecutionTimeMs -ne $null) {
                    $totalTime += $job.ExecutionTimeMs
                }
            }
            $PoolManager.Statistics.TotalExecutionTimeMs = $totalTime
            $PoolManager.Statistics.AverageExecutionTimeMs = [math]::Round($totalTime / $PoolManager.Statistics.JobsCompleted, 2)
            
            Write-ModuleLog -Message "Statistics updated: Total time: ${totalTime}ms, Average: $($PoolManager.Statistics.AverageExecutionTimeMs)ms" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        $result = @{
            ActiveJobs = $PoolManager.ActiveJobs.Count
            CompletedJobs = $completedJobs.Count
            TotalCompleted = $PoolManager.CompletedJobs.Count
            TotalFailed = $PoolManager.FailedJobs.Count
            AvailableRunspaces = if ($PoolManager.Status -eq 'Open') { $PoolManager.RunspacePool.GetAvailableRunspaces() } else { 0 }
        }
        
        Write-ModuleLog -Message "Job status updated for pool '$poolName': Active: $($result.ActiveJobs), Completed: $($result.CompletedJobs), Available: $($result.AvailableRunspaces)" -Level "DEBUG" -Component "RunspaceManagement"
        
        return $result
        
    } catch {
        Write-ModuleLog -Message "Failed to update job status for pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Waits for all jobs in runspace pool to complete
.DESCRIPTION
Monitors active jobs until completion with configurable polling interval and timeout
.PARAMETER PoolManager
Pool manager object
.PARAMETER PollingIntervalMs
Polling interval in milliseconds (default: 100ms based on research)
.PARAMETER TimeoutSeconds
Overall timeout for all jobs completion
.PARAMETER ProcessResults
Automatically process results when jobs complete
.EXAMPLE
Wait-RunspaceJobs -PoolManager $pool -TimeoutSeconds 300 -ProcessResults
#>
function Wait-RunspaceJobs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [int]$PollingIntervalMs = 100,
        [int]$TimeoutSeconds = 600,
        [switch]$ProcessResults
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Waiting for jobs completion in pool '$poolName' (Timeout: ${TimeoutSeconds}s)..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $startTime = Get-Date
        $lastStatusUpdate = Get-Date
        
        # Monitor jobs until completion (research-validated pattern)
        while ($PoolManager.ActiveJobs.Count -gt 0) {
            # Update job status
            $statusUpdate = Update-RunspaceJobStatus -PoolManager $PoolManager -ProcessCompletedJobs:$ProcessResults
            
            # Check timeout
            $elapsedSeconds = ((Get-Date) - $startTime).TotalSeconds
            if ($elapsedSeconds -gt $TimeoutSeconds) {
                Write-ModuleLog -Message "Jobs wait timeout exceeded ($TimeoutSeconds seconds) - $($PoolManager.ActiveJobs.Count) jobs still running" -Level "WARNING" -Component "RunspaceManagement"
                break
            }
            
            # Status update every 5 seconds
            if (((Get-Date) - $lastStatusUpdate).TotalSeconds -gt 5) {
                Write-ModuleLog -Message "Job progress: Active: $($statusUpdate.ActiveJobs), Completed: $($statusUpdate.TotalCompleted), Failed: $($statusUpdate.TotalFailed)" -Level "INFO" -Component "RunspaceManagement"
                $lastStatusUpdate = Get-Date
            }
            
            # Resource monitoring if enabled
            if ($PoolManager.ResourceMonitoring.Enabled) {
                Test-RunspacePoolResources -PoolManager $PoolManager
            }
            
            # Polling interval (research: 100ms standard)
            Start-Sleep -Milliseconds $PollingIntervalMs
        }
        
        $totalElapsed = ((Get-Date) - $startTime).TotalSeconds
        $completionStatus = if ($PoolManager.ActiveJobs.Count -eq 0) { "All jobs completed" } else { "Timeout with $($PoolManager.ActiveJobs.Count) jobs remaining" }
        
        Write-ModuleLog -Message "Job wait completed for pool '$poolName': $completionStatus in ${totalElapsed}s" -Level "INFO" -Component "RunspaceManagement"
        
        return @{
            Success = $PoolManager.ActiveJobs.Count -eq 0
            ElapsedSeconds = $totalElapsed
            RemainingJobs = $PoolManager.ActiveJobs.Count
            CompletedJobs = $PoolManager.CompletedJobs.Count
            FailedJobs = $PoolManager.FailedJobs.Count
        }
        
    } catch {
        Write-ModuleLog -Message "Error waiting for jobs in pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Gets all job results from runspace pool
.DESCRIPTION
Retrieves results from completed jobs with proper error handling and disposal
.PARAMETER PoolManager
Pool manager object
.PARAMETER IncludeFailedJobs
Include failed job information in results
.EXAMPLE
$results = Get-RunspaceJobResults -PoolManager $pool -IncludeFailedJobs
#>
function Get-RunspaceJobResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [switch]$IncludeFailedJobs
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Retrieving job results from pool '$poolName'..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $results = @{
            PoolName = $poolName
            CompletedJobs = @()
            FailedJobs = @()
            Statistics = $PoolManager.Statistics.Clone()
            Retrieved = Get-Date
        }
        
        # Process completed jobs
        foreach ($job in $PoolManager.CompletedJobs) {
            $results.CompletedJobs += @{
                JobId = $job.JobId
                JobName = $job.JobName
                Result = $job.Result
                ExecutionTimeMs = $job.ExecutionTimeMs
                SubmittedTime = $job.SubmittedTime
                CompletedTime = $job.CompletedTime
            }
        }
        
        # Process failed jobs if requested
        if ($IncludeFailedJobs) {
            foreach ($job in $PoolManager.FailedJobs) {
                $results.FailedJobs += @{
                    JobId = $job.JobId
                    JobName = $job.JobName
                    Error = $job.Error
                    Status = $job.Status
                    ExecutionTimeMs = $job.ExecutionTimeMs
                    SubmittedTime = $job.SubmittedTime
                    CompletedTime = $job.CompletedTime
                }
            }
        }
        
        Write-ModuleLog -Message "Retrieved results from pool '$poolName': $($results.CompletedJobs.Count) completed, $($results.FailedJobs.Count) failed" -Level "INFO" -Component "RunspaceManagement"
        
        return $results
        
    } catch {
        Write-ModuleLog -Message "Failed to retrieve job results from pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

#endregion

#region Throttling and Resource Control (Hour 5-6)

<#
.SYNOPSIS
Monitors resource usage for runspace pool operations
.DESCRIPTION
Uses Get-Counter to monitor CPU and memory usage during runspace pool operations
.PARAMETER PoolManager
Pool manager object with resource monitoring configuration
.EXAMPLE
Test-RunspacePoolResources -PoolManager $pool
#>
function Test-RunspacePoolResources {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    if (-not $PoolManager.ResourceMonitoring.Enabled) {
        return @{Enabled = $false}
    }
    
    $poolName = $PoolManager.Name
    
    try {
        $resourceInfo = @{
            Enabled = $true
            Timestamp = Get-Date
            CpuPercent = 0
            MemoryUsedMB = 0
            AvailableMemoryMB = 0
            ThresholdExceeded = $false
            Warnings = @()
        }
        
        # Get CPU usage (research-validated Get-Counter pattern)
        try {
            $cpuCounter = Get-Counter -Counter "Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            $resourceInfo.CpuPercent = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
            $PoolManager.ResourceMonitoring.LastCpuCheck = Get-Date
            
            # Update peak CPU usage
            if ($resourceInfo.CpuPercent -gt $PoolManager.Statistics.PeakCpuPercent) {
                $PoolManager.Statistics.PeakCpuPercent = $resourceInfo.CpuPercent
            }
            
            # Check CPU threshold
            if ($resourceInfo.CpuPercent -gt $PoolManager.ResourceMonitoring.CpuThreshold) {
                $resourceInfo.ThresholdExceeded = $true
                $resourceInfo.Warnings += "CPU usage ($($resourceInfo.CpuPercent)%) exceeds threshold ($($PoolManager.ResourceMonitoring.CpuThreshold)%)"
            }
            
        } catch {
            Write-ModuleLog -Message "Failed to get CPU counter: $($_.Exception.Message)" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        # Get memory usage (research-validated pattern)
        try {
            $memoryCounter = Get-Counter -Counter "Memory\Available MBytes" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            $resourceInfo.AvailableMemoryMB = [math]::Round($memoryCounter.CounterSamples[0].CookedValue, 2)
            
            # Calculate used memory (approximate)
            $processCounter = Get-Counter -Counter "Process(powershell*)\Working Set - Private" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            $resourceInfo.MemoryUsedMB = [math]::Round(($processCounter.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum / 1MB, 2)
            $PoolManager.ResourceMonitoring.LastMemoryCheck = Get-Date
            
            # Update peak memory usage
            if ($resourceInfo.MemoryUsedMB -gt $PoolManager.Statistics.PeakMemoryUsageMB) {
                $PoolManager.Statistics.PeakMemoryUsageMB = $resourceInfo.MemoryUsedMB
            }
            
            # Check memory threshold
            if ($resourceInfo.MemoryUsedMB -gt $PoolManager.ResourceMonitoring.MemoryThresholdMB) {
                $resourceInfo.ThresholdExceeded = $true
                $resourceInfo.Warnings += "Memory usage ($($resourceInfo.MemoryUsedMB)MB) exceeds threshold ($($PoolManager.ResourceMonitoring.MemoryThresholdMB)MB)"
            }
            
        } catch {
            Write-ModuleLog -Message "Failed to get memory counter: $($_.Exception.Message)" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        # Log warnings if thresholds exceeded
        if ($resourceInfo.ThresholdExceeded) {
            foreach ($warning in $resourceInfo.Warnings) {
                Write-ModuleLog -Message "Resource threshold warning for pool '$poolName': $warning" -Level "WARNING" -Component "RunspaceManagement"
            }
        }
        
        return $resourceInfo
        
    } catch {
        Write-ModuleLog -Message "Failed to monitor resources for pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        return @{Enabled = $true; Error = $_.Exception.Message}
    }
}

<#
.SYNOPSIS
Implements adaptive throttling based on system performance
.DESCRIPTION
Adjusts runspace pool throttling based on CPU and memory usage patterns
.PARAMETER PoolManager
Pool manager object
.PARAMETER CpuThreshold
CPU threshold for throttling adjustment (default: 80%)
.PARAMETER MemoryThresholdMB
Memory threshold for throttling adjustment (default: 1000MB)
.EXAMPLE
Set-AdaptiveThrottling -PoolManager $pool -CpuThreshold 70
#>
function Set-AdaptiveThrottling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [int]$CpuThreshold = 80,
        [int]$MemoryThresholdMB = 1000
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Setting adaptive throttling for pool '$poolName'..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        # Update resource monitoring configuration
        $PoolManager.ResourceMonitoring.CpuThreshold = $CpuThreshold
        $PoolManager.ResourceMonitoring.MemoryThresholdMB = $MemoryThresholdMB
        $PoolManager.ResourceMonitoring.Enabled = $true
        
        # Get current resource usage
        $resourceInfo = Test-RunspacePoolResources -PoolManager $PoolManager
        
        $adaptiveConfig = @{
            OriginalMaxRunspaces = $PoolManager.MaxRunspaces
            RecommendedMaxRunspaces = $PoolManager.MaxRunspaces
            CpuBasedAdjustment = 0
            MemoryBasedAdjustment = 0
            Reasoning = @()
        }
        
        # CPU-based throttling adjustment
        if ($resourceInfo.CpuPercent -gt $CpuThreshold) {
            $cpuAdjustment = -[math]::Ceiling($PoolManager.MaxRunspaces * 0.2) # Reduce by 20%
            $adaptiveConfig.CpuBasedAdjustment = $cpuAdjustment
            $adaptiveConfig.Reasoning += "High CPU usage ($($resourceInfo.CpuPercent)%) - reduce runspaces"
        } elseif ($resourceInfo.CpuPercent -lt ($CpuThreshold * 0.5)) {
            $cpuAdjustment = [math]::Min(2, [Environment]::ProcessorCount - $PoolManager.MaxRunspaces) # Increase by up to 2
            $adaptiveConfig.CpuBasedAdjustment = $cpuAdjustment
            $adaptiveConfig.Reasoning += "Low CPU usage ($($resourceInfo.CpuPercent)%) - can increase runspaces"
        }
        
        # Memory-based throttling adjustment
        if ($resourceInfo.MemoryUsedMB -gt $MemoryThresholdMB) {
            $memoryAdjustment = -[math]::Ceiling($PoolManager.MaxRunspaces * 0.3) # Reduce by 30%
            $adaptiveConfig.MemoryBasedAdjustment = $memoryAdjustment
            $adaptiveConfig.Reasoning += "High memory usage ($($resourceInfo.MemoryUsedMB)MB) - reduce runspaces"
        }
        
        # Calculate recommended adjustment (take most conservative)
        $totalAdjustment = [math]::Min($adaptiveConfig.CpuBasedAdjustment, $adaptiveConfig.MemoryBasedAdjustment)
        $adaptiveConfig.RecommendedMaxRunspaces = [math]::Max(1, $PoolManager.MaxRunspaces + $totalAdjustment)
        
        Write-ModuleLog -Message "Adaptive throttling analysis for pool '$poolName': Current: $($PoolManager.MaxRunspaces), Recommended: $($adaptiveConfig.RecommendedMaxRunspaces)" -Level "INFO" -Component "RunspaceManagement"
        
        return $adaptiveConfig
        
    } catch {
        Write-ModuleLog -Message "Failed to set adaptive throttling for pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

<#
.SYNOPSIS
Forces garbage collection and cleanup for memory management
.DESCRIPTION
Implements research-validated garbage collection patterns for long-running runspace pool operations
.PARAMETER PoolManager
Pool manager object
.PARAMETER Force
Force garbage collection even if not recommended
.EXAMPLE
Invoke-RunspacePoolCleanup -PoolManager $pool -Force
#>
function Invoke-RunspacePoolCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [switch]$Force
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Performing cleanup for runspace pool '$poolName'..." -Level "INFO" -Component "RunspaceManagement"
    
    try {
        $cleanupStats = @{
            StartTime = Get-Date
            InitialMemoryMB = 0
            FinalMemoryMB = 0
            MemoryFreedMB = 0
            DisposalStats = $PoolManager.DisposalTracking.Clone()
        }
        
        # Get initial memory usage
        try {
            $process = Get-Process -Id $PID
            $cleanupStats.InitialMemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
        } catch {
            Write-ModuleLog -Message "Could not get initial memory usage" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        # Clear completed job collections to free memory
        $completedCount = $PoolManager.CompletedJobs.Count
        $failedCount = $PoolManager.FailedJobs.Count
        
        $PoolManager.CompletedJobs.Clear()
        $PoolManager.FailedJobs.Clear()
        
        Write-ModuleLog -Message "Cleared $completedCount completed jobs and $failedCount failed jobs from memory" -Level "DEBUG" -Component "RunspaceManagement"
        
        # Force garbage collection (research: manual GC for long-running processes)
        if ($Force -or $completedCount -gt 10 -or $failedCount -gt 5) {
            Write-ModuleLog -Message "Forcing garbage collection..." -Level "DEBUG" -Component "RunspaceManagement"
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
        }
        
        # Get final memory usage
        try {
            Start-Sleep -Milliseconds 500 # Allow GC to complete
            $process = Get-Process -Id $PID
            $cleanupStats.FinalMemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
            $cleanupStats.MemoryFreedMB = $cleanupStats.InitialMemoryMB - $cleanupStats.FinalMemoryMB
        } catch {
            Write-ModuleLog -Message "Could not get final memory usage" -Level "DEBUG" -Component "RunspaceManagement"
        }
        
        $cleanupStats.Duration = ((Get-Date) - $cleanupStats.StartTime).TotalMilliseconds
        
        Write-ModuleLog -Message "Cleanup completed for pool '$poolName': Freed ${cleanupStats.MemoryFreedMB}MB memory in $($cleanupStats.Duration)ms" -Level "INFO" -Component "RunspaceManagement"
        
        return $cleanupStats
        
    } catch {
        Write-ModuleLog -Message "Failed to cleanup pool '$poolName': $($_.Exception.Message)" -Level "ERROR" -Component "RunspaceManagement"
        throw
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    # InitialSessionState Configuration (Hour 1-3)
    'New-RunspaceSessionState',
    'Set-SessionStateConfiguration',
    'Add-SessionStateModule',
    'Add-SessionStateVariable',
    'Test-SessionStateConfiguration',
    
    # Module/Variable Pre-loading (Hour 4-6)
    'Import-SessionStateModules',
    'Initialize-SessionStateVariables',
    'Get-SessionStateModules',
    'Get-SessionStateVariables',
    
    # SessionStateVariableEntry Sharing (Hour 7-8)
    'New-SessionStateVariableEntry',
    'Add-SharedVariable',
    'Get-SharedVariable',
    'Set-SharedVariable',
    'Remove-SharedVariable',
    
    # Basic Runspace Pool Management (Days 1-2)
    'New-ManagedRunspacePool',
    'Open-RunspacePool',
    'Close-RunspacePool',
    'Get-RunspacePoolStatus',
    'Test-RunspacePoolHealth',
    
    # Production Runspace Pool Infrastructure (Days 3-4 Hour 1-2)
    'New-ProductionRunspacePool',
    'Submit-RunspaceJob',
    'Update-RunspaceJobStatus',
    'Wait-RunspaceJobs',
    'Get-RunspaceJobResults',
    
    # Throttling and Resource Control (Days 3-4 Hour 5-6)
    'Test-RunspacePoolResources',
    'Set-AdaptiveThrottling',
    'Invoke-RunspacePoolCleanup'
)

# Module loading complete
Write-ModuleLog -Message "Unity-Claude-RunspaceManagement module loaded successfully with $((Get-Command -Module Unity-Claude-RunspaceManagement).Count) functions" -Level "INFO" -Component "RunspaceManagement"

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB/KdfrmwWS7Rn6
# OYYuPTTj7Z+Oa7r+EzLg+QWRChXMXqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILiX3iqMCRyBg0a3q7Mdc7lv
# v+nXechff6SOZhec/x7GMA0GCSqGSIb3DQEBAQUABIIBAESootXWRdBhyMbHBoJM
# e4RxFcEKgAiAbzHoxQtJYQVimFdmC0Yczmavn9Ps40yUXOsTLTjeQQVJmM/z1SFY
# avwwpnrwlYMgrfOpfS9ImxWqrJdD6w0bdUDtwet3WM60KIClS9iCxbj8vw9SlATg
# 0tzY3sCqPxkT3AxV1RaKwbHT7Zl6gKug3QLlOAP8+RcvdK9AoM6L0TF9nEIO4Dz8
# auznVf+sX7+wP4aRz17ltNgX6SqC4krZjSAmhJ5ZdZPJpGMGm22sFO+TTPJkykHU
# k4foHmVkPyi/LPSlrqBjtvKWMGN+YXzOCoBvHpMiLLd91wx8bFrBG6ZD/B4tOfRQ
# ryM=
# SIG # End signature block
