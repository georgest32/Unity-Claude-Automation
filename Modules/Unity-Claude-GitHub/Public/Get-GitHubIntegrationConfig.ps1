function Get-GitHubIntegrationConfig {
    <#
    .SYNOPSIS
    Retrieves the GitHub integration configuration with environment overrides
    
    .DESCRIPTION
    Loads the GitHub integration configuration from JSON files with support for
    hierarchical loading (default -> user -> environment) and validation.
    
    .PARAMETER Environment
    Environment name for configuration overrides (development, testing, production)
    
    .PARAMETER ConfigPath
    Custom configuration file path (optional)
    
    .PARAMETER Validate
    Validate configuration against schema (default: true)
    
    .PARAMETER UnityProject
    Unity project name for project-specific configuration
    
    .EXAMPLE
    $config = Get-GitHubIntegrationConfig -Environment "development"
    
    .EXAMPLE
    $config = Get-GitHubIntegrationConfig -UnityProject "MyGame" -Environment "production"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('development', 'testing', 'production')]
        [string]$Environment = 'development',
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [bool]$Validate = $true,
        
        [Parameter()]
        [string]$UnityProject
    )
    
    begin {
        Write-Debug "GET-CONFIG: Starting Get-GitHubIntegrationConfig"
        Write-Debug "  Environment: $Environment"
        Write-Debug "  UnityProject: $UnityProject"
        Write-Debug "  Validate: $Validate"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Get-GitHubIntegrationConfig: Loading configuration for environment: $Environment"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    process {
        try {
            # Determine configuration file paths
            $moduleConfigDir = Join-Path $PSScriptRoot "..\Config"
            $userConfigDir = Join-Path $env:APPDATA "Unity-Claude\GitHub"
            
            Write-Debug "GET-CONFIG: Module config directory: $moduleConfigDir"
            Write-Debug "GET-CONFIG: User config directory: $userConfigDir"
            
            # Load default configuration
            $defaultConfigPath = Join-Path $moduleConfigDir "github-integration.default.json"
            if (-not (Test-Path $defaultConfigPath)) {
                throw "Default configuration file not found: $defaultConfigPath"
            }
            
            Write-Debug "GET-CONFIG: Loading default configuration from: $defaultConfigPath"
            $defaultConfig = Get-Content $defaultConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Debug "GET-CONFIG: Default configuration loaded successfully"
            
            # Load user configuration if exists
            $userConfigPath = if ($ConfigPath) { 
                $ConfigPath 
            } else { 
                Join-Path $userConfigDir "github-integration.json" 
            }
            
            $userConfig = $null
            if (Test-Path $userConfigPath) {
                Write-Debug "GET-CONFIG: Loading user configuration from: $userConfigPath"
                try {
                    $userConfig = Get-Content $userConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    Write-Debug "GET-CONFIG: User configuration loaded successfully"
                } catch {
                    Write-Warning "Failed to load user configuration: $_"
                    Write-Debug "GET-CONFIG: User configuration load failed, using defaults only"
                }
            } else {
                Write-Debug "GET-CONFIG: No user configuration found at: $userConfigPath"
            }
            
            # Start with default configuration
            $config = $defaultConfig | ConvertTo-Json -Depth 20 | ConvertFrom-Json
            Write-Debug "GET-CONFIG: Created working configuration from defaults"
            
            # Apply user configuration overrides
            if ($userConfig) {
                Write-Debug "GET-CONFIG: Applying user configuration overrides"
                $config = Merge-GitHubConfiguration -BaseConfig $config -OverrideConfig $userConfig
                Write-Debug "GET-CONFIG: User overrides applied successfully"
            }
            
            # Apply environment-specific overrides
            if ($config.environments -and $config.environments.$Environment) {
                Write-Debug "GET-CONFIG: Applying environment overrides for: $Environment"
                $envOverrides = $config.environments.$Environment
                $config = Merge-GitHubConfiguration -BaseConfig $config -OverrideConfig $envOverrides
                Write-Debug "GET-CONFIG: Environment overrides applied successfully"
            }
            
            # Apply Unity project-specific configuration
            if ($UnityProject -and $config.unityProjects -and $config.unityProjects.$UnityProject) {
                Write-Debug "GET-CONFIG: Applying Unity project configuration for: $UnityProject"
                $projectConfig = $config.unityProjects.$UnityProject
                
                # Override repository settings if specified in project config
                if ($projectConfig.repositoryOwner -and $projectConfig.repositoryName) {
                    $config.global.defaultOwner = $projectConfig.repositoryOwner
                    $config.global.defaultRepository = $projectConfig.repositoryName
                    Write-Debug "GET-CONFIG: Set repository from project config: $($projectConfig.repositoryOwner)/$($projectConfig.repositoryName)"
                }
                
                # Apply project-specific overrides
                if ($projectConfig.enabled -ne $null) {
                    $config.global.createIssues = $projectConfig.enabled
                    Write-Debug "GET-CONFIG: Set createIssues from project config: $($projectConfig.enabled)"
                }
            }
            
            # Validate configuration if requested
            if ($Validate) {
                Write-Debug "GET-CONFIG: Validating configuration"
                $validationResult = Test-GitHubIntegrationConfig -Config $config
                if (-not $validationResult.IsValid) {
                    throw "Configuration validation failed: $($validationResult.Errors -join ', ')"
                }
                Write-Debug "GET-CONFIG: Configuration validation passed"
            }
            
            # Add runtime metadata
            $config | Add-Member -NotePropertyName 'LoadedAt' -NotePropertyValue (Get-Date) -Force
            $config | Add-Member -NotePropertyName 'Environment' -NotePropertyValue $Environment -Force
            $config | Add-Member -NotePropertyName 'UnityProject' -NotePropertyValue $UnityProject -Force
            Write-Debug "GET-CONFIG: Added runtime metadata"
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [SUCCESS] Get-GitHubIntegrationConfig: Configuration loaded successfully"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully loaded GitHub integration configuration"
            return $config
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Get-GitHubIntegrationConfig: Failed to load configuration - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to load GitHub integration configuration: $_"
            throw
        }
    }
    
    end {
        Write-Debug "GET-CONFIG: Completed Get-GitHubIntegrationConfig"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDDihED7c8Gyyba
# 8qePypYnmBBvu0EdjllYygt+Mm7rnKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBH7XqhaQ+ZcKLN5UCi37iwr
# RZm+v5CJVlex9/G0SwCVMA0GCSqGSIb3DQEBAQUABIIBAIEY2wbggcsZowYK0zlX
# m2Kst9OL9pWb9wQQ5d4nqRbS/Pxzl+e88OrINHvLoplgRoXKzz8jGNaLenQvUy2J
# FANxIuBjnFgNQlSc+qToWXTZnzxRUZSGtjii/Z7HedoUJpn244NepjQA0zZVTl0j
# wyVlWesYgra7jU9CVAK5Cq2vOcIqBGljE0dBf3HLRAjjwZsgM8LyT6KCuo2zf9Y1
# 5X7NfA1jrXadFEeozfYRlDAeXBk/0bz6OGR9Y2amTV1MTAxkrtwVvShAuYUjvK67
# 8SnaGDUoc/tot82rmrjkoetoeJP/ckiMzTTI0xrvt76B/dI1k03f1CBBCv+6CfRr
# I6E=
# SIG # End signature block
