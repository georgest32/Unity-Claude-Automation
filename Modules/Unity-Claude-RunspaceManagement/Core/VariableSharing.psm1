# Unity-Claude-RunspaceManagement Variable Sharing Component
# Thread-safe variable sharing across runspaces
# Part of refactored RunspaceManagement module

$ErrorActionPreference = "Stop"

# Import core components with conditional loading and fallback
$CorePath = Join-Path $PSScriptRoot "RunspaceCore.psm1"
$SessionStatePath = Join-Path $PSScriptRoot "SessionStateConfiguration.psm1"

# Check for and load required functions with fallback
try {
    if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
        . $CorePath -ErrorAction SilentlyContinue
    }
    if (-not (Get-Command Add-SessionStateVariable -ErrorAction SilentlyContinue)) {
        . $SessionStatePath -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host "[VariableSharing] Warning: Could not load dependencies, using fallback logging" -ForegroundColor Yellow
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [VariableSharing] [$Level] $Message"
    }
    function Add-SessionStateVariable { param($SessionStateConfig, $Name, $Value, $Description) }
    function Get-SharedVariablesDictionary { return @{} }
}

function New-SessionStateVariableEntry {
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        $Value,
        [string]$Description = "",
        [System.Management.Automation.ScopedItemOptions]$Options = 'None'
    )
    
    Write-ModuleLog -Message "Creating SessionStateVariableEntry for $Name..." -Level "DEBUG"
    
    try {
        # Create SessionStateVariableEntry using research-validated pattern
        $variableEntry = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Name, $Value, $Description, $Options
        
        Write-ModuleLog -Message "Created SessionStateVariableEntry for $Name successfully" -Level "DEBUG"
        
        return $variableEntry
        
    } catch {
        Write-ModuleLog -Message "Failed to create SessionStateVariableEntry for ${Name}: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Add-SharedVariable {
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
    
    Write-ModuleLog -Message "Adding shared variable $Name to session state..." -Level "INFO"
    
    try {
        $finalValue = $Value
        
        # Make thread-safe if requested and applicable
        if ($MakeThreadSafe) {
            if ($Value -is [hashtable]) {
                $finalValue = [hashtable]::Synchronized($Value)
                Write-ModuleLog -Message "Made hashtable $Name thread-safe" -Level "DEBUG"
            } elseif ($Value -is [System.Collections.ArrayList]) {
                $finalValue = [System.Collections.ArrayList]::Synchronized($Value)
                Write-ModuleLog -Message "Made ArrayList $Name thread-safe" -Level "DEBUG"
            } elseif ($Value -is [System.Collections.Queue]) {
                $finalValue = [System.Collections.Queue]::Synchronized($Value)
                Write-ModuleLog -Message "Made Queue $Name thread-safe" -Level "DEBUG"
            } else {
                Write-ModuleLog -Message "Cannot make $Name thread-safe - unsupported type: $($Value.GetType().Name)" -Level "WARNING"
            }
        }
        
        # Add to session state
        Add-SessionStateVariable -SessionStateConfig $SessionStateConfig -Name $Name -Value $finalValue -Description $Description
        
        # Also add to shared variables dictionary for external access
        $sharedDict = Get-SharedVariablesDictionary
        [void]$sharedDict.TryAdd($Name, $finalValue)
        
        Write-ModuleLog -Message "Shared variable $Name added successfully" -Level "INFO"
        
    } catch {
        Write-ModuleLog -Message "Failed to add shared variable ${Name}: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-SharedVariable {
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    Write-ModuleLog -Message "Note: Shared variables are accessed directly in runspace context as dollar-sign-$Name" -Level "INFO"
    
    # Try to get from shared variables dictionary
    $sharedDict = Get-SharedVariablesDictionary
    $value = $null
    if ($sharedDict.TryGetValue($Name, [ref]$value)) {
        return @{
            VariableName = $Name
            CurrentValue = $value
            AccessPattern = "`$$Name"
            Note = "Access this variable directly in runspace scriptblocks using `$$Name"
        }
    }
    
    # Return information about how to access the variable
    return @{
        VariableName = $Name
        AccessPattern = "`$$Name"
        Note = "Access this variable directly in runspace scriptblocks using `$$Name"
    }
}

function Set-SharedVariable {
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        $Value
    )
    
    Write-ModuleLog -Message "Note: Shared variables are modified directly in runspace context as dollar-sign-$Name = dollar-sign-value" -Level "INFO"
    
    # Update in shared variables dictionary
    $sharedDict = Get-SharedVariablesDictionary
    $sharedDict[$Name] = $Value
    
    # Return information about how to modify the variable
    return @{
        VariableName = $Name
        ModificationPattern = "`$$Name = `$newValue"
        Note = "Modify this variable directly in runspace scriptblocks using assignment"
        ThreadSafetyNote = "Ensure thread-safe operations when modifying shared variables"
    }
}

function Remove-SharedVariable {
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    Write-ModuleLog -Message "Note: Shared variables cannot be removed from InitialSessionState after runspace pool creation" -Level "WARNING"
    
    # Remove from shared variables dictionary
    $sharedDict = Get-SharedVariablesDictionary
    $removed = $null
    [void]$sharedDict.TryRemove($Name, [ref]$removed)
    
    return @{
        VariableName = $Name
        Note = "SessionState variables cannot be removed after runspace pool is created"
        Alternative = "Set variable to null or empty value in runspace context"
        RemovedFromCache = ($null -ne $removed)
    }
}

function Test-SharedVariableAccess {
    <#
    .SYNOPSIS
    Tests if a shared variable is accessible
    .DESCRIPTION
    Checks if a shared variable exists in the shared variables dictionary
    .PARAMETER Name
    Variable name to test
    .EXAMPLE
    Test-SharedVariableAccess -Name "SharedQueue"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    $sharedDict = Get-SharedVariablesDictionary
    return $sharedDict.ContainsKey($Name)
}

function Get-AllSharedVariables {
    <#
    .SYNOPSIS
    Gets all shared variables
    .DESCRIPTION
    Returns information about all shared variables in the dictionary
    .EXAMPLE
    Get-AllSharedVariables
    #>
    [CmdletBinding()]
    param()
    
    $sharedDict = Get-SharedVariablesDictionary
    $variables = @()
    
    foreach ($key in $sharedDict.Keys) {
        $value = $null
        if ($sharedDict.TryGetValue($key, [ref]$value)) {
            $variables += @{
                Name = $key
                Type = if ($value) { $value.GetType().Name } else { "null" }
                IsThreadSafe = ($value -is [System.Collections.Hashtable] -and $value.IsSynchronized) -or
                               ($value -is [System.Collections.ArrayList] -and $value.IsSynchronized) -or
                               ($value -is [System.Collections.Queue] -and $value.IsSynchronized)
            }
        }
    }
    
    return $variables
}

# Export functions
Export-ModuleMember -Function @(
    'New-SessionStateVariableEntry',
    'Add-SharedVariable',
    'Get-SharedVariable',
    'Set-SharedVariable',
    'Remove-SharedVariable',
    'Test-SharedVariableAccess',
    'Get-AllSharedVariables'
)

Write-ModuleLog -Message "VariableSharing component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCparkHAKoZOz1w
# 2GGrDVGvB2fR+CZwy3QSf5V1Swl3iKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP0uGieRcjm7Ke0Osf215kn/
# JNDTuPu2KNJf4uZCbRKRMA0GCSqGSIb3DQEBAQUABIIBAFY6bZLZaQNssF9Z9y2V
# l4sX7E9lSlqCf0Q73sPj9iAlkcOnpx2votizpdADwgGwV70ChjuNiL/Rh7vciEbX
# /1QN3f9xJurYDeoqMCQYHaoly9cz5s86eYpWNNgGYITqttR8JLFxtjvTi48PQgM0
# JkzX9OCtPgafLr42I4JVdW4OIRiqAxvnP1FRdLHnJg4+b9C4xh/S3K8sgIcCFpcM
# zPyk+oW2KRg63wySdiAzL/WNG3zS+/rdnkOcEKxNtSHGWV313/BacJ/IkSX2C34G
# V6wVf9VRh6CM0fkTbQIXkcrBuWWNLKOVjPu+757hNurg/s0EDTTjqODwB6JHcE4o
# GPw=
# SIG # End signature block
