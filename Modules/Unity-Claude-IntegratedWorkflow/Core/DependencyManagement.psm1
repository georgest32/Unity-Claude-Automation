# Unity-Claude-IntegratedWorkflow Dependency Management Component
# Handles module dependencies and validation
# Part of refactored IntegratedWorkflow module

$ErrorActionPreference = "Stop"

# Import core component
$CorePath = Join-Path $PSScriptRoot "WorkflowCore.psm1"
Import-Module $CorePath -Force

# Module dependency tracking
$script:RequiredModulesAvailable = @{}
$script:WriteModuleLogAvailable = $false

# Dependency validation function
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

# Initialize required modules
function Initialize-RequiredModules {
    param(
        [string]$ModulesPath
    )
    
    if (-not $ModulesPath) {
        $ModulesPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent | Join-Path -ChildPath "Modules"
    }
    
    # Load RunspaceManagement module
    try {
        $RunspaceManagementPath = Join-Path $ModulesPath "Unity-Claude-RunspaceManagement"
        if (-not (Get-Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue)) {
            Import-Module $RunspaceManagementPath -ErrorAction Stop
            Write-IntegratedWorkflowLog -Message "[StatePreservation] Loaded Unity-Claude-RunspaceManagement module" -Level "DEBUG"
        } else {
            Write-IntegratedWorkflowLog -Message "[StatePreservation] Unity-Claude-RunspaceManagement already loaded, preserving state" -Level "DEBUG"
        }
        $script:RequiredModulesAvailable['RunspaceManagement'] = $true
        $script:WriteModuleLogAvailable = $true
    } catch {
        Write-Warning "Failed to import Unity-Claude-RunspaceManagement: $($_.Exception.Message)"
        $script:RequiredModulesAvailable['RunspaceManagement'] = $false
    }
    
    # Load UnityParallelization module
    try {
        $UnityParallelizationPath = Join-Path $ModulesPath "Unity-Claude-UnityParallelization"
        if (-not (Get-Module Unity-Claude-UnityParallelization -ErrorAction SilentlyContinue)) {
            Import-Module $UnityParallelizationPath -ErrorAction Stop
            Write-IntegratedWorkflowLog -Message "[StatePreservation] Loaded Unity-Claude-UnityParallelization module" -Level "DEBUG"
        } else {
            Write-IntegratedWorkflowLog -Message "[StatePreservation] Unity-Claude-UnityParallelization already loaded, PRESERVING REGISTRATION STATE" -Level "DEBUG"
        }
        $script:RequiredModulesAvailable['UnityParallelization'] = $true
    } catch {
        Write-Warning "Failed to import Unity-Claude-UnityParallelization: $($_.Exception.Message)"
        $script:RequiredModulesAvailable['UnityParallelization'] = $false
    }
    
    # Load ClaudeParallelization module
    try {
        $ClaudeParallelizationPath = Join-Path $ModulesPath "Unity-Claude-ClaudeParallelization"
        if (-not (Get-Module Unity-Claude-ClaudeParallelization -ErrorAction SilentlyContinue)) {
            Import-Module $ClaudeParallelizationPath -ErrorAction Stop
            Write-IntegratedWorkflowLog -Message "[StatePreservation] Loaded Unity-Claude-ClaudeParallelization module" -Level "DEBUG"
        } else {
            Write-IntegratedWorkflowLog -Message "[StatePreservation] Unity-Claude-ClaudeParallelization already loaded, preserving state" -Level "DEBUG"
        }
        $script:RequiredModulesAvailable['ClaudeParallelization'] = $true
    } catch {
        Write-Warning "Failed to import Unity-Claude-ClaudeParallelization: $($_.Exception.Message)"
        $script:RequiredModulesAvailable['ClaudeParallelization'] = $false
    }
    
    return $script:RequiredModulesAvailable
}

# Comprehensive dependency validation
function Test-ModuleDependencies {
    $totalDependencies = $script:RequiredModulesAvailable.Count
    $loadedDependencies = ($script:RequiredModulesAvailable.Values | Where-Object { $_ -eq $true }).Count
    
    Write-Host "Module Dependencies: $loadedDependencies/$totalDependencies loaded" -ForegroundColor $(if ($loadedDependencies -eq $totalDependencies) { "Green" } else { "Yellow" })
    
    foreach ($dep in $script:RequiredModulesAvailable.GetEnumerator()) {
        $status = if ($dep.Value) { "LOADED" } else { "FAILED" }
        Write-Host "  $($dep.Key): $status" -ForegroundColor $(if ($dep.Value) { "Green" } else { "Red" })
    }
    
    return $loadedDependencies -eq $totalDependencies
}

# Dependency validation helper for functions
function Assert-Dependencies {
    param(
        [string[]]$RequiredDependencies
    )
    
    foreach ($dep in $RequiredDependencies) {
        if (-not $script:RequiredModulesAvailable[$dep]) {
            throw "Required dependency '$dep' is not available. Function cannot execute."
        }
    }
}

# Get module availability status
function Get-ModuleAvailability {
    return $script:RequiredModulesAvailable
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ModuleDependencyAvailability',
    'Initialize-RequiredModules',
    'Test-ModuleDependencies',
    'Assert-Dependencies',
    'Get-ModuleAvailability'
)

Write-IntegratedWorkflowLog -Message "DependencyManagement component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD7AQ/+5hOBVoT6
# p5py7LPdyuSasZtFH3OI2KWHaK4VkKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA4Mls7aJlrvYEzSqEV2eo+5
# LTBIBBD7XbIDbeF18NGyMA0GCSqGSIb3DQEBAQUABIIBAJ3RKpLh1cNLRS2fMaLc
# 9kOrO9kry3OJdMChYh1QwVMt7TFscOwzVDRjVhK5KiHui7hn8cTYQVeJGmYSFlFC
# KVn4YQqe3BvWIv7ZnC10TLEiXyKsMKY3cT4e9O53b0stRb9aWUVgg2firaZbgiot
# cdlpdYueV2iVkeK3sSC0pMx3WVK9vkp/o3aUJE3Q7Yu3hP/kFLcs8tv/xLQEAfJr
# PJnXdKrR2Nh5GpKWADxoDImpQOTktPbGxQAlT+T2a2VaouPdD2z7AnMCBA+aDfav
# DZqigLsRL+mVUk224AtmU6sctO1/vaKqSHYgql6E3NVsTJYHgik932RvqtoFPzs+
# jDM=
# SIG # End signature block
