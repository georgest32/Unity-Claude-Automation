# Unity-Claude-RunspaceManagement Session State Configuration Component
# InitialSessionState configuration and management
# Part of refactored RunspaceManagement module

$ErrorActionPreference = "Stop"

# Import core component functions directly to avoid circular dependency
$CorePath = Join-Path $PSScriptRoot "RunspaceCore.psm1"
try {
    if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
        . $CorePath
    }
} catch {
    Write-Host "[SessionStateConfiguration] Warning: Could not load RunspaceCore functions, using fallback logging" -ForegroundColor Yellow
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [SessionStateConfiguration] [$Level] $Message"
    }
    function Update-SessionStateRegistry { param($StateName, $State) }
}

# Default configuration
$script:DefaultSessionConfiguration = @{
    LanguageMode = 'FullLanguage'
    ExecutionPolicy = 'Bypass'
    ApartmentState = 'STA'
    ThreadOptions = 'ReuseThread'
    UseCreateDefault = $true
}

function New-RunspaceSessionState {
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
    
    Write-ModuleLog -Message "Creating new InitialSessionState with research-validated configuration..." -Level "INFO"
    
    try {
        # Use CreateDefault() for better performance (research finding: CreateDefault2 is 3-8x slower)
        if ($UseCreateDefault) {
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            Write-ModuleLog -Message "Using CreateDefault() for optimal performance" -Level "DEBUG"
        } else {
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
            Write-ModuleLog -Message "Using CreateDefault2() with core commands only" -Level "DEBUG"
        }
        
        # Configure session state properties based on research best practices
        $sessionState.LanguageMode = [System.Management.Automation.PSLanguageMode]$LanguageMode
        
        # Convert ExecutionPolicy string to enum (research-validated approach)
        try {
            $sessionState.ExecutionPolicy = [Microsoft.PowerShell.ExecutionPolicy]$ExecutionPolicy
            Write-ModuleLog -Message "ExecutionPolicy set to $ExecutionPolicy using enum" -Level "DEBUG"
        } catch {
            Write-ModuleLog -Message "ExecutionPolicy enum not available, using string fallback" -Level "WARNING"
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
        
        # Register in session state registry
        $stateName = "SessionState_$(Get-Date -Format 'yyyyMMddHHmmss')"
        Update-SessionStateRegistry -StateName $stateName -State $result
        
        Write-ModuleLog -Message "InitialSessionState created successfully with $LanguageMode language mode" -Level "INFO"
        return $result
        
    } catch {
        Write-ModuleLog -Message "Failed to create InitialSessionState: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Set-SessionStateConfiguration {
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
    [CmdletBinding()]
    param(
        [hashtable]$Configuration
    )
    
    Write-ModuleLog -Message "Updating session state configuration..." -Level "INFO"
    
    try {
        foreach ($key in $Configuration.Keys) {
            if ($script:DefaultSessionConfiguration.ContainsKey($key)) {
                $oldValue = $script:DefaultSessionConfiguration[$key]
                $script:DefaultSessionConfiguration[$key] = $Configuration[$key]
                Write-ModuleLog -Message "Updated $key from $oldValue to $($Configuration[$key])" -Level "DEBUG"
            } else {
                Write-ModuleLog -Message "Unknown configuration key: $key" -Level "WARNING"
            }
        }
        
        Write-ModuleLog -Message "Session state configuration updated successfully" -Level "INFO"
        
    } catch {
        Write-ModuleLog -Message "Failed to set session state configuration: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Add-SessionStateModule {
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [string]$ModulePath = $null
    )
    
    Write-ModuleLog -Message "Adding module '$ModuleName' to session state..." -Level "DEBUG"
    
    try {
        if (-not $SessionStateConfig.SessionState) {
            throw "Invalid session state configuration object"
        }
        
        # Determine module path if not provided
        if ([string]::IsNullOrEmpty($ModulePath)) {
            $module = Get-Module -Name $ModuleName -ListAvailable | Select-Object -First 1
            if ($module) {
                $ModulePath = Split-Path $module.Path -Parent
                Write-ModuleLog -Message "Auto-detected module path: $ModulePath" -Level "DEBUG"
            } else {
                Write-ModuleLog -Message "Module '$ModuleName' not found in available modules" -Level "WARNING"
                return
            }
        }
        
        # Add module to session state
        $SessionStateConfig.SessionState.ImportPSModule($ModuleName)
        
        # Update metadata
        $SessionStateConfig.Metadata.ModulesCount++
        
        Write-ModuleLog -Message "Module '$ModuleName' added to session state" -Level "INFO"
        
    } catch {
        Write-ModuleLog -Message "Failed to add module to session state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Add-SessionStateVariable {
    <#
    .SYNOPSIS
    Adds a variable to the InitialSessionState
    .DESCRIPTION
    Adds a variable that will be available in all runspaces created from this session state
    .PARAMETER SessionStateConfig
    Session state configuration object
    .PARAMETER Name
    Variable name
    .PARAMETER Value
    Variable value
    .PARAMETER Description
    Optional description
    .EXAMPLE
    Add-SessionStateVariable -SessionStateConfig $config -Name "ProjectRoot" -Value "C:\Projects"
    #>
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
    
    Write-ModuleLog -Message "Adding variable '$Name' to session state..." -Level "DEBUG"
    
    try {
        if (-not $SessionStateConfig.SessionState) {
            throw "Invalid session state configuration object"
        }
        
        # Create variable entry
        $variableEntry = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry(
            $Name, $Value, $Description
        )
        
        # Add to session state
        $SessionStateConfig.SessionState.Variables.Add($variableEntry)
        
        # Update metadata
        $SessionStateConfig.Metadata.VariablesCount++
        
        Write-ModuleLog -Message "Variable '$Name' added to session state" -Level "INFO"
        
    } catch {
        Write-ModuleLog -Message "Failed to add variable to session state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Test-SessionStateConfiguration {
    <#
    .SYNOPSIS
    Tests if session state configuration is valid
    .DESCRIPTION
    Validates session state configuration and returns test results
    .PARAMETER SessionStateConfig
    Session state configuration object to test
    .EXAMPLE
    Test-SessionStateConfiguration -SessionStateConfig $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig
    )
    
    Write-ModuleLog -Message "Testing session state configuration..." -Level "DEBUG"
    
    $results = @{
        IsValid = $false
        HasSessionState = $false
        HasMetadata = $false
        ModulesCount = 0
        VariablesCount = 0
        Errors = @()
    }
    
    try {
        # Check for session state
        if ($SessionStateConfig.SessionState) {
            $results.HasSessionState = $true
            
            # Check if it's a valid InitialSessionState object
            if ($SessionStateConfig.SessionState -is [System.Management.Automation.Runspaces.InitialSessionState]) {
                $results.IsValid = $true
            } else {
                $results.Errors += "SessionState is not of type InitialSessionState"
            }
        } else {
            $results.Errors += "SessionState property not found"
        }
        
        # Check for metadata
        if ($SessionStateConfig.Metadata) {
            $results.HasMetadata = $true
            $results.ModulesCount = $SessionStateConfig.Metadata.ModulesCount
            $results.VariablesCount = $SessionStateConfig.Metadata.VariablesCount
        } else {
            $results.Errors += "Metadata property not found"
        }
        
        Write-ModuleLog -Message "Session state configuration test completed. IsValid: $($results.IsValid)" -Level "INFO"
        
    } catch {
        $results.Errors += $_.Exception.Message
        Write-ModuleLog -Message "Error testing session state configuration: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'New-RunspaceSessionState',
    'Set-SessionStateConfiguration',
    'Add-SessionStateModule',
    'Add-SessionStateVariable',
    'Test-SessionStateConfiguration'
)

Write-ModuleLog -Message "SessionStateConfiguration component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCApmYYqcetPE92F
# MR2pHNyDUgR4vIrdwtCQVXM8UcVz6KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMWcWcgmN/zztSRxewJZ4yfc
# /EuDKuRU6dXTVOJNrWXbMA0GCSqGSIb3DQEBAQUABIIBAEdtU/XyLFbsoc7dvKf3
# fWeyZ+3CcbfuwqrPxctOW77hYaH2VUvaMMe+j6JDy7k53TREV/kvXuNSk2LPBdUI
# s5WGWg7OVJ7yOF6ckEREGp7a1iA7WY3rrzbTs+GVG4TycLopX9rlb+qetAtmp9Sg
# GPGlb2P5YkMhuHgRa1sdw39OYFuyAYy0F3CFzsLs9IdoV3bE6tqVuivBzpHRvKr7
# 9Df2kzDlHvAuHSI5wa6dPv0DiM/zsONmr7CIjJJkzkyzHH03OTrqmtYtFPgIfZz7
# l6Hy3hUX4vg1i3h97NdfoV2jxcxGQ/VnzH6yZSZHoiIz+PhhS9D3btmTnRLiGlRU
# ovc=
# SIG # End signature block
