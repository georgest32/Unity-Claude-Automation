# Unity-Claude-DocumentationDrift Core Configuration Module
# Manages configuration and initialization for Documentation Drift Detection
# Created: 2025-08-25 (Refactored from large monolithic module)

#Requires -Version 7.2

# Module-level variables for managing documentation drift detection
$script:Configuration = @{}              # Module configuration settings
$script:CacheEnabled = $true             # Performance caching flag
$script:LastIndexUpdate = $null          # Timestamp of last documentation index update

# Default configuration values
$script:DefaultConfiguration = @{
    DriftDetectionSensitivity = 'Medium'  # High, Medium, Low
    AutoPRCreationThreshold = 'Medium'    # Critical, High, Medium, Low, Never
    CacheTimeout = 300                    # Cache timeout in seconds (5 minutes)
    MaxBatchSize = 5                      # Maximum changes to batch together
    CooldownPeriod = 300                  # Cooldown between automated actions (5 minutes)
    ExcludePatterns = @(                  # Files to exclude from analysis
        '*.tmp', '*.temp', '*.log', '*.cache',
        'node_modules\*', '.git\*', 'bin\*', 'obj\*',
        '*.lock', '*.pid', '*~', '.DS_Store'
    )
    IncludePatterns = @(                  # Files to include in analysis
        '*.ps1', '*.psm1', '*.psd1',      # PowerShell files
        '*.cs', '*.js', '*.ts', '*.py',   # Code files  
        '*.md', '*.txt', '*.rst'          # Documentation files
    )
    DocumentationPaths = @(               # Paths to scan for documentation
        'docs\*', 'README*', '*.md'
    )
    PRTemplates = @{
        'default' = 'documentation-update.md'
        'api' = 'api-documentation-update.md'
        'breaking' = 'breaking-change-docs.md'
    }
    ReviewerAssignment = @{
        'critical' = @('tech-lead', 'docs-team')
        'high' = @('docs-team') 
        'medium' = @()
        'low' = @()
    }
}

function Initialize-DocumentationDrift {
    <#
    .SYNOPSIS
    Initializes the documentation drift detection system
    
    .DESCRIPTION
    Sets up the documentation drift detection system with default configuration,
    builds initial code-to-documentation mapping, and prepares the system for
    automated drift detection and documentation updates.
    
    .PARAMETER ConfigPath
    Path to custom configuration file. If not specified, uses default configuration.
    
    .PARAMETER Force
    Force reinitialization even if already initialized
    
    .EXAMPLE
    Initialize-DocumentationDrift
    Initializes with default configuration
    
    .EXAMPLE
    Initialize-DocumentationDrift -ConfigPath ".\docs-config.json" -Force
    Initializes with custom configuration and forces reinitialization
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Verbose "[Initialize-DocumentationDrift] Starting initialization..."
    
    try {
        # Check if already initialized (unless Force is specified)
        if (-not $Force -and $script:Configuration.Count -gt 0) {
            Write-Verbose "[Initialize-DocumentationDrift] Already initialized, skipping"
            return
        }
        
        # Load configuration
        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            Write-Verbose "[Initialize-DocumentationDrift] Loading configuration from: $ConfigPath"
            $customConfig = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
            $script:Configuration = $script:DefaultConfiguration.Clone()
            
            # Merge custom configuration with defaults
            foreach ($key in $customConfig.Keys) {
                $script:Configuration[$key] = $customConfig[$key]
            }
        } else {
            Write-Verbose "[Initialize-DocumentationDrift] Using default configuration"
            $script:Configuration = $script:DefaultConfiguration.Clone()
        }
        
        # Initialize cache settings
        $script:CacheEnabled = $script:Configuration.CacheTimeout -gt 0
        $script:LastIndexUpdate = $null
        
        Write-Information "[Initialize-DocumentationDrift] Documentation drift detection initialized successfully"
        Write-Verbose "[Initialize-DocumentationDrift] Configuration: $($script:Configuration | ConvertTo-Json -Depth 3)"
        
    } catch {
        Write-Error "[Initialize-DocumentationDrift] Initialization failed: $_"
        throw
    }
}

function Get-DocumentationDriftConfig {
    <#
    .SYNOPSIS
    Gets the current documentation drift detection configuration
    
    .DESCRIPTION
    Returns the current configuration settings for the documentation drift detection system
    
    .EXAMPLE
    Get-DocumentationDriftConfig
    Returns the current configuration as a hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    if ($script:Configuration.Count -eq 0) {
        Write-Warning "Documentation drift not initialized. Run Initialize-DocumentationDrift first."
        return @{}
    }
    
    return $script:Configuration.Clone()
}

function Set-DocumentationDriftConfig {
    <#
    .SYNOPSIS
    Updates documentation drift detection configuration settings
    
    .DESCRIPTION
    Updates one or more configuration settings for the documentation drift detection system
    
    .PARAMETER Configuration
    Hashtable containing configuration settings to update
    
    .PARAMETER DriftDetectionSensitivity
    Sets the drift detection sensitivity (High, Medium, Low)
    
    .PARAMETER AutoPRCreationThreshold
    Sets the threshold for automatic PR creation (Critical, High, Medium, Low, Never)
    
    .PARAMETER CacheTimeout
    Sets the cache timeout in seconds
    
    .EXAMPLE
    Set-DocumentationDriftConfig -DriftDetectionSensitivity High -AutoPRCreationThreshold Medium
    Updates specific configuration settings
    
    .EXAMPLE
    Set-DocumentationDriftConfig -Configuration @{CacheTimeout = 600; MaxBatchSize = 10}
    Updates multiple settings using a hashtable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('High', 'Medium', 'Low')]
        [string]$DriftDetectionSensitivity,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Never')]
        [string]$AutoPRCreationThreshold,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 3600)]
        [int]$CacheTimeout
    )
    
    if ($script:Configuration.Count -eq 0) {
        Write-Error "Documentation drift not initialized. Run Initialize-DocumentationDrift first."
        return
    }
    
    try {
        # Update from hashtable if provided
        if ($Configuration) {
            foreach ($key in $Configuration.Keys) {
                if ($script:Configuration.ContainsKey($key)) {
                    $script:Configuration[$key] = $Configuration[$key]
                    Write-Verbose "[Set-DocumentationDriftConfig] Updated $key = $($Configuration[$key])"
                } else {
                    Write-Warning "[Set-DocumentationDriftConfig] Unknown configuration key: $key"
                }
            }
        }
        
        # Update individual parameters if provided
        if ($DriftDetectionSensitivity) {
            $script:Configuration.DriftDetectionSensitivity = $DriftDetectionSensitivity
            Write-Verbose "[Set-DocumentationDriftConfig] Updated DriftDetectionSensitivity = $DriftDetectionSensitivity"
        }
        
        if ($AutoPRCreationThreshold) {
            $script:Configuration.AutoPRCreationThreshold = $AutoPRCreationThreshold
            Write-Verbose "[Set-DocumentationDriftConfig] Updated AutoPRCreationThreshold = $AutoPRCreationThreshold"
        }
        
        if ($CacheTimeout -ge 0) {
            $script:Configuration.CacheTimeout = $CacheTimeout
            $script:CacheEnabled = $CacheTimeout -gt 0
            Write-Verbose "[Set-DocumentationDriftConfig] Updated CacheTimeout = $CacheTimeout"
        }
        
        Write-Information "[Set-DocumentationDriftConfig] Configuration updated successfully"
        
    } catch {
        Write-Error "[Set-DocumentationDriftConfig] Failed to update configuration: $_"
        throw
    }
}

function Reset-DocumentationDriftConfig {
    <#
    .SYNOPSIS
    Resets documentation drift configuration to defaults
    
    .DESCRIPTION
    Resets all configuration settings to their default values
    
    .EXAMPLE
    Reset-DocumentationDriftConfig
    Resets configuration to default values
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Documentation Drift Configuration", "Reset to defaults")) {
        $script:Configuration = $script:DefaultConfiguration.Clone()
        $script:CacheEnabled = $script:Configuration.CacheTimeout -gt 0
        Write-Information "[Reset-DocumentationDriftConfig] Configuration reset to defaults"
    }
}

function Export-DocumentationDriftConfig {
    <#
    .SYNOPSIS
    Exports current configuration to a file
    
    .DESCRIPTION
    Exports the current documentation drift configuration to a JSON file
    
    .PARAMETER Path
    Path where to save the configuration file
    
    .EXAMPLE
    Export-DocumentationDriftConfig -Path ".\my-docs-config.json"
    Exports current configuration to specified file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if ($script:Configuration.Count -eq 0) {
        Write-Error "Documentation drift not initialized. Run Initialize-DocumentationDrift first."
        return
    }
    
    try {
        $script:Configuration | ConvertTo-Json -Depth 5 | Out-File -FilePath $Path -Encoding UTF8
        Write-Information "[Export-DocumentationDriftConfig] Configuration exported to: $Path"
    } catch {
        Write-Error "[Export-DocumentationDriftConfig] Failed to export configuration: $_"
        throw
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Initialize-DocumentationDrift',
    'Get-DocumentationDriftConfig', 
    'Set-DocumentationDriftConfig',
    'Reset-DocumentationDriftConfig',
    'Export-DocumentationDriftConfig'
)

# Auto-initialize with defaults on module load
Initialize-DocumentationDrift
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCro5PmB3ndzeU3
# TUAM2F8mkG6ZGT8xJwR5UXQn5VWRdqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGXPz8SuLQlhJNEY6T51Vsdw
# FBf6Ii3eKVz1jrAqGCcwMA0GCSqGSIb3DQEBAQUABIIBAAZUKcV4K2a1mQjt+t/q
# fqcfHr0o36XiS7AGpP30WdaB0qnCb7KzRFgso5LrS5pjotj6PlpORr5WCXpr6+p/
# k7ELkIb9OzfAoblR8e9vhUATyAiqyyiQsRzXEn3oQ2pTRBMwcdIykqOr1Vq9ER3u
# 7RJflkCjLH9gQt16Mkm3aW2/URExV4uCglnWPp8wmX8mXKU5Wa4nS+9Vv2P4vooJ
# lP31Je5aUOC2i4oqEPpdTGupKZYzoDHnA7n5V+7Ii3oB2SP1Iz72nVktjPJ8HyZr
# RuU2t/P1sv9nccRQufKTGFGzMxutTWVf0VfNgYtxAy7I0JvfOaDbjwBjBY98e4fa
# hak=
# SIG # End signature block
