function Set-GitHubIntegrationConfig {
    <#
    .SYNOPSIS
    Sets GitHub integration configuration with validation
    
    .DESCRIPTION
    Updates GitHub integration configuration with validation and backup.
    Supports updating individual settings or complete configuration replacement.
    
    .PARAMETER Config
    Complete configuration object to set
    
    .PARAMETER ConfigPath
    Custom configuration file path (default: user config directory)
    
    .PARAMETER DefaultOwner
    Set the default repository owner
    
    .PARAMETER DefaultRepository
    Set the default repository name
    
    .PARAMETER CreateIssues
    Enable/disable automatic issue creation
    
    .PARAMETER CheckDuplicates
    Enable/disable duplicate checking
    
    .PARAMETER Environment
    Environment to update (development, testing, production)
    
    .PARAMETER BackupExisting
    Create backup of existing configuration (default: true)
    
    .EXAMPLE
    Set-GitHubIntegrationConfig -DefaultOwner "myorg" -DefaultRepository "myrepo"
    
    .EXAMPLE
    Set-GitHubIntegrationConfig -Config $newConfig -BackupExisting
    #>
    [CmdletBinding(DefaultParameterSetName = 'Individual')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Complete')]
        [PSCustomObject]$Config,
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter(ParameterSetName = 'Individual')]
        [string]$DefaultOwner,
        
        [Parameter(ParameterSetName = 'Individual')]
        [string]$DefaultRepository,
        
        [Parameter(ParameterSetName = 'Individual')]
        [bool]$CreateIssues,
        
        [Parameter(ParameterSetName = 'Individual')]
        [bool]$CheckDuplicates,
        
        [Parameter()]
        [ValidateSet('development', 'testing', 'production')]
        [string]$Environment = 'development',
        
        [Parameter()]
        [bool]$BackupExisting = $true
    )
    
    begin {
        Write-Debug "SET-CONFIG: Starting Set-GitHubIntegrationConfig"
        Write-Debug "  ParameterSet: $($PSCmdlet.ParameterSetName)"
        Write-Debug "  Environment: $Environment"
        Write-Debug "  BackupExisting: $BackupExisting"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Set-GitHubIntegrationConfig: Updating configuration"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    process {
        try {
            # Determine configuration file path
            $userConfigDir = Join-Path $env:APPDATA "Unity-Claude\GitHub"
            $configFilePath = if ($ConfigPath) { 
                $ConfigPath 
            } else { 
                Join-Path $userConfigDir "github-integration.json" 
            }
            
            Write-Debug "SET-CONFIG: Configuration file path: $configFilePath"
            
            # Ensure configuration directory exists
            $configDir = Split-Path $configFilePath -Parent
            if (-not (Test-Path $configDir)) {
                Write-Debug "SET-CONFIG: Creating configuration directory: $configDir"
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
            }
            
            # Load existing configuration or create new
            $existingConfig = $null
            if (Test-Path $configFilePath) {
                Write-Debug "SET-CONFIG: Loading existing configuration"
                try {
                    $existingConfig = Get-Content $configFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
                    Write-Debug "SET-CONFIG: Existing configuration loaded successfully"
                    
                    # Create backup if requested
                    if ($BackupExisting) {
                        $backupPath = "$configFilePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                        Copy-Item $configFilePath $backupPath -Force
                        Write-Debug "SET-CONFIG: Created configuration backup: $backupPath"
                        Write-Verbose "Configuration backed up to: $backupPath"
                    }
                } catch {
                    Write-Warning "Failed to load existing configuration: $_"
                    Write-Debug "SET-CONFIG: Existing config load failed, will create new"
                }
            }
            
            # Determine final configuration
            if ($PSCmdlet.ParameterSetName -eq 'Complete') {
                Write-Debug "SET-CONFIG: Using provided complete configuration"
                $finalConfig = $Config
            } else {
                Write-Debug "SET-CONFIG: Building configuration from individual parameters"
                
                # Start with existing config or load default
                if ($existingConfig) {
                    $finalConfig = $existingConfig
                    Write-Debug "SET-CONFIG: Starting with existing configuration"
                } else {
                    Write-Debug "SET-CONFIG: Loading default configuration as base"
                    $defaultConfigPath = Join-Path $PSScriptRoot "..\Config\github-integration.default.json"
                    $finalConfig = Get-Content $defaultConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
                }
                
                # Ensure global property exists
                if (-not $finalConfig.global) {
                    $finalConfig | Add-Member -NotePropertyName 'global' -NotePropertyValue ([PSCustomObject]@{}) -Force
                    Write-Debug "SET-CONFIG: Created global property"
                }
                
                # Apply individual parameter updates
                if ($PSBoundParameters.ContainsKey('DefaultOwner')) {
                    if ($finalConfig.global -is [PSCustomObject]) {
                        $finalConfig.global | Add-Member -NotePropertyName 'defaultOwner' -NotePropertyValue $DefaultOwner -Force
                    } else {
                        $finalConfig.global.defaultOwner = $DefaultOwner
                    }
                    Write-Debug "SET-CONFIG: Set defaultOwner: $DefaultOwner"
                }
                
                if ($PSBoundParameters.ContainsKey('DefaultRepository')) {
                    if ($finalConfig.global -is [PSCustomObject]) {
                        $finalConfig.global | Add-Member -NotePropertyName 'defaultRepository' -NotePropertyValue $DefaultRepository -Force
                    } else {
                        $finalConfig.global.defaultRepository = $DefaultRepository
                    }
                    Write-Debug "SET-CONFIG: Set defaultRepository: $DefaultRepository"
                }
                
                if ($PSBoundParameters.ContainsKey('CreateIssues')) {
                    if ($finalConfig.global -is [PSCustomObject]) {
                        $finalConfig.global | Add-Member -NotePropertyName 'createIssues' -NotePropertyValue $CreateIssues -Force
                    } else {
                        $finalConfig.global.createIssues = $CreateIssues
                    }
                    Write-Debug "SET-CONFIG: Set createIssues: $CreateIssues"
                }
                
                if ($PSBoundParameters.ContainsKey('CheckDuplicates')) {
                    if ($finalConfig.global -is [PSCustomObject]) {
                        $finalConfig.global | Add-Member -NotePropertyName 'checkDuplicates' -NotePropertyValue $CheckDuplicates -Force
                    } else {
                        $finalConfig.global.checkDuplicates = $CheckDuplicates
                    }
                    Write-Debug "SET-CONFIG: Set checkDuplicates: $CheckDuplicates"
                }
                
                # Update version and metadata
                $finalConfig.version = "1.0.0"
                $finalConfig | Add-Member -NotePropertyName 'UpdatedAt' -NotePropertyValue (Get-Date) -Force
                $finalConfig | Add-Member -NotePropertyName 'UpdatedBy' -NotePropertyValue $env:USERNAME -Force
            }
            
            # Validate the final configuration
            Write-Debug "SET-CONFIG: Validating final configuration"
            $validationResult = Test-GitHubIntegrationConfig -Config $finalConfig
            
            if (-not $validationResult.IsValid) {
                Write-Debug "SET-CONFIG: Configuration validation failed"
                throw "Configuration validation failed: $($validationResult.Errors -join ', ')"
            }
            
            Write-Debug "SET-CONFIG: Configuration validation passed"
            
            # Save configuration
            Write-Debug "SET-CONFIG: Saving configuration to: $configFilePath"
            $jsonOutput = $finalConfig | ConvertTo-Json -Depth 20
            Set-Content -Path $configFilePath -Value $jsonOutput -Encoding UTF8 -Force
            
            Write-Debug "SET-CONFIG: Configuration saved successfully"
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [SUCCESS] Set-GitHubIntegrationConfig: Configuration updated successfully"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "GitHub integration configuration updated successfully"
            return $validationResult
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Set-GitHubIntegrationConfig: Failed to update configuration - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to update GitHub integration configuration: $_"
            throw
        }
    }
    
    end {
        Write-Debug "SET-CONFIG: Completed Set-GitHubIntegrationConfig"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDjIcMaoWERBFxQ
# RoBkrqK4bo3pXhAXWjYcS0Y/m5XOgKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOoQ/+kdxdxFtRdCZkX4uJc1
# KqYA9N1TBStQClDhoethMA0GCSqGSIb3DQEBAQUABIIBACXrg/GasMGeBnZduzqL
# ivi/Y5QxgkqBaJoRW2Z7aEvDPCk4REI/WcK4UPuB8/55QDOy35j6+82plzCF/FLt
# cGiNmZOf+MGbuyZnh8u+aHDPPGVwsM/9tiMapEbWlxmFppMHhULnUZqRGMnYKTb/
# t6gyojcehKslXlro7yH3k7e1lvjo2k0o0bSIr4LHRvJME5Alat2gus36c3hkgpze
# aCdqJMUEBnV0PR5IFfXM/yqQApTgyuEbzB2b7zbUgTYEEdRmRhlpVKfExIVqE1PC
# gWXwEK/zPUFxPd3wVHbkb+/pNDOJkQHPaI/Lb603opyH9Fkx+gqwmGkQC+pftnGY
# yhs=
# SIG # End signature block
