function Test-GitHubIntegrationConfig {
    <#
    .SYNOPSIS
    Validates GitHub integration configuration against schema
    
    .DESCRIPTION
    Validates configuration objects or JSON files against the GitHub integration schema.
    Provides detailed validation results with error descriptions.
    
    .PARAMETER Config
    Configuration object to validate
    
    .PARAMETER ConfigPath
    Path to JSON configuration file to validate
    
    .PARAMETER SchemaPath
    Custom schema file path (optional)
    
    .EXAMPLE
    $result = Test-GitHubIntegrationConfig -Config $configObject
    if (-not $result.IsValid) {
        Write-Host $result.Errors
    }
    
    .EXAMPLE
    Test-GitHubIntegrationConfig -ConfigPath "C:\config\github.json"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Config')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Config')]
        [PSCustomObject]$Config,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [string]$ConfigPath,
        
        [Parameter()]
        [string]$SchemaPath
    )
    
    begin {
        Write-Debug "TEST-CONFIG: Starting configuration validation"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Test-GitHubIntegrationConfig: Starting configuration validation"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    process {
        try {
            $validationResult = [PSCustomObject]@{
                IsValid = $false
                Errors = @()
                Warnings = @()
                ConfigObject = $null
            }
            
            # Get configuration to validate
            if ($PSCmdlet.ParameterSetName -eq 'File') {
                Write-Debug "TEST-CONFIG: Loading configuration from file: $ConfigPath"
                if (-not (Test-Path $ConfigPath)) {
                    $validationResult.Errors += "Configuration file not found: $ConfigPath"
                    return $validationResult
                }
                
                try {
                    $configContent = Get-Content $ConfigPath -Raw -Encoding UTF8
                    $Config = $configContent | ConvertFrom-Json
                    Write-Debug "TEST-CONFIG: Configuration loaded from file successfully"
                } catch {
                    $validationResult.Errors += "Failed to parse JSON configuration: $($_.Exception.Message)"
                    return $validationResult
                }
            }
            
            $validationResult.ConfigObject = $Config
            Write-Debug "TEST-CONFIG: Configuration object ready for validation"
            
            # Load schema
            $schemaFilePath = if ($SchemaPath) { 
                $SchemaPath 
            } else { 
                Join-Path $PSScriptRoot "..\Config\github-integration.schema.json" 
            }
            
            Write-Debug "TEST-CONFIG: Schema path: $schemaFilePath"
            
            # Validate required fields manually (since Test-Json not available in PS 5.1)
            Write-Debug "TEST-CONFIG: Starting manual validation (PowerShell 5.1 compatible)"
            
            # Check version field
            if (-not $Config.version) {
                $validationResult.Errors += "Missing required field: version"
            } elseif ($Config.version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
                $validationResult.Errors += "Invalid version format: $($Config.version). Expected: X.Y.Z"
            }
            
            # Check global configuration
            if (-not $Config.global) {
                $validationResult.Errors += "Missing required field: global"
            } else {
                Write-Debug "TEST-CONFIG: Validating global configuration"
                
                # Check required global fields
                if ($Config.global.createIssues -eq $null) {
                    $validationResult.Errors += "Missing required field: global.createIssues"
                }
                if ($Config.global.checkDuplicates -eq $null) {
                    $validationResult.Errors += "Missing required field: global.checkDuplicates"
                }
                
                # Validate duplicateSimilarityThreshold range
                if ($Config.global.duplicateSimilarityThreshold -ne $null) {
                    if ($Config.global.duplicateSimilarityThreshold -lt 0.0 -or $Config.global.duplicateSimilarityThreshold -gt 1.0) {
                        $validationResult.Errors += "duplicateSimilarityThreshold must be between 0.0 and 1.0"
                    }
                }
                
                # Validate maxSearchResults range
                if ($Config.global.maxSearchResults -ne $null) {
                    if ($Config.global.maxSearchResults -lt 1 -or $Config.global.maxSearchResults -gt 1000) {
                        $validationResult.Errors += "maxSearchResults must be between 1 and 1000"
                    }
                }
            }
            
            # Validate repositories configuration
            if ($Config.repositories) {
                Write-Debug "TEST-CONFIG: Validating repositories configuration"
                foreach ($repoKey in $Config.repositories.PSObject.Properties.Name) {
                    if ($repoKey -notmatch '^[^/]+/[^/]+$') {
                        $validationResult.Errors += "Invalid repository key format: $repoKey. Expected: owner/repo"
                    }
                }
            }
            
            # Validate Unity projects configuration
            if ($Config.unityProjects) {
                Write-Debug "TEST-CONFIG: Validating Unity projects configuration"
                foreach ($projectKey in $Config.unityProjects.PSObject.Properties.Name) {
                    $project = $Config.unityProjects.$projectKey
                    if (-not $project.repositoryOwner) {
                        $validationResult.Errors += "Unity project '$projectKey' missing required field: repositoryOwner"
                    }
                    if (-not $project.repositoryName) {
                        $validationResult.Errors += "Unity project '$projectKey' missing required field: repositoryName"
                    }
                }
            }
            
            # Validate templates structure
            if ($Config.templates) {
                Write-Debug "TEST-CONFIG: Validating templates configuration"
                foreach ($templateKey in $Config.templates.PSObject.Properties.Name) {
                    $template = $Config.templates.$templateKey
                    if (-not $template.title) {
                        $validationResult.Warnings += "Template '$templateKey' missing title"
                    }
                    if (-not $template.body) {
                        $validationResult.Warnings += "Template '$templateKey' missing body"
                    }
                }
            }
            
            # Set validation result
            $validationResult.IsValid = ($validationResult.Errors.Count -eq 0)
            
            Write-Debug "TEST-CONFIG: Validation completed"
            Write-Debug "  IsValid: $($validationResult.IsValid)"
            Write-Debug "  Errors: $($validationResult.Errors.Count)"
            Write-Debug "  Warnings: $($validationResult.Warnings.Count)"
            
            # Log validation result
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            if ($validationResult.IsValid) {
                $logEntry = "[$timestamp] [SUCCESS] Test-GitHubIntegrationConfig: Configuration validation passed"
            } else {
                $logEntry = "[$timestamp] [ERROR] Test-GitHubIntegrationConfig: Configuration validation failed - $($validationResult.Errors.Count) errors"
            }
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            return $validationResult
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Test-GitHubIntegrationConfig: Validation process failed - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Configuration validation process failed: $_"
            throw
        }
    }
    
    end {
        Write-Debug "TEST-CONFIG: Completed Test-GitHubIntegrationConfig"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDF/4MLoAqJE6x6
# +76vxxDS1BD4egiiYb5bGkMzg+HzhKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPKaJWcJOguTwZ12DxEGxGeO
# MgXo7IILkTD35PrM4hLFMA0GCSqGSIb3DQEBAQUABIIBAAx3amqN5BuIZTfQv9EH
# 9aDxR2QUs88AID8iVBZXk1UOioJ/ZE0ps6QVZRu8eSrc6WXSrL28mCknsvxym4f+
# Z3wmVvP7PPYMvneJ8sGs9KSK21R6cCoGHXEApKyGvdVKbwvcpICbVP/Sqgss36WM
# i++1ADsMVbVE1aUc5ar+R76W5AxOkTTzTInVxcOr8fOsMou3pxxwZOI8+UVAeEIa
# 5Jik9XNxTT5cLgxqZhp6/xa/q1qsvrD9WpLr5M5bWXj9CFAGD/YRRY8xqkjEdxDB
# 2uIwm3U4A/AwxPUfa9FryJLQtJ8CYblXeoXeeQWB20bJaE8HDgA0SVCv3WLMAQFP
# 8R8=
# SIG # End signature block
