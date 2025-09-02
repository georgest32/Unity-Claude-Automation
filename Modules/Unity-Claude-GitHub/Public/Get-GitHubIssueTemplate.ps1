function Get-GitHubIssueTemplate {
    <#
    .SYNOPSIS
    Retrieves and processes GitHub issue templates for Unity errors
    
    .DESCRIPTION
    Gets the appropriate issue template based on Unity error type and applies
    variable substitution to generate complete issue content.
    
    .PARAMETER UnityError
    Unity error object to generate template for
    
    .PARAMETER TemplateType
    Specific template type to use (overrides automatic detection)
    
    .PARAMETER Config
    Configuration object (optional, will load if not provided)
    
    .PARAMETER IncludeCodeContext
    Include code context in the generated content (default: true)
    
    .EXAMPLE
    $error = Get-UnityErrors | Select-Object -First 1
    $template = Get-GitHubIssueTemplate -UnityError $error
    New-GitHubIssue -Title $template.Title -Body $template.Body -Labels $template.Labels
    
    .EXAMPLE
    Get-GitHubIssueTemplate -UnityError $error -TemplateType "compilationError"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UnityError,
        
        [Parameter()]
        [ValidateSet('compilationError', 'runtimeError', 'nullReferenceError')]
        [string]$TemplateType,
        
        [Parameter()]
        [PSCustomObject]$Config,
        
        [Parameter()]
        [bool]$IncludeCodeContext = $true
    )
    
    begin {
        Write-Debug "GET-TEMPLATE: Starting Get-GitHubIssueTemplate"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Get-GitHubIssueTemplate: Processing Unity error for template generation"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    process {
        try {
            # Load configuration if not provided
            if (-not $Config) {
                Write-Debug "GET-TEMPLATE: Loading configuration"
                $Config = Get-GitHubIntegrationConfig -Validate $false
            }
            
            # Determine template type if not specified
            if (-not $TemplateType) {
                $TemplateType = Get-UnityErrorTemplateType -UnityError $UnityError
                Write-Debug "GET-TEMPLATE: Auto-detected template type: $TemplateType"
            } else {
                Write-Debug "GET-TEMPLATE: Using specified template type: $TemplateType"
            }
            
            # Get template definition
            if (-not $Config.templates.$TemplateType) {
                throw "Template type '$TemplateType' not found in configuration"
            }
            
            $template = $Config.templates.$TemplateType
            Write-Debug "GET-TEMPLATE: Retrieved template definition for: $TemplateType"
            
            # Prepare template data from Unity error
            $templateData = Build-TemplateDataFromUnityError -UnityError $UnityError -IncludeCodeContext $IncludeCodeContext
            Write-Debug "GET-TEMPLATE: Built template data with $($templateData.Keys.Count) properties"
            
            # Expand title template
            Write-Debug "GET-TEMPLATE: Expanding title template"
            $expandedTitle = Expand-IssueTemplate -Template $template.title -Data $templateData
            
            # Expand body template
            Write-Debug "GET-TEMPLATE: Expanding body template"
            $expandedBody = Expand-IssueTemplate -Template $template.body -Data $templateData -ConditionalSections $true
            
            # Determine labels
            $labels = @()
            if ($template.labels) {
                $labels += $template.labels
                Write-Debug "GET-TEMPLATE: Added template labels: $($template.labels -join ', ')"
            }
            
            # Add error-specific labels
            $errorLabels = Get-UnityErrorLabels -UnityError $UnityError -Config $Config
            if ($errorLabels) {
                $labels += $errorLabels
                Write-Debug "GET-TEMPLATE: Added error-specific labels: $($errorLabels -join ', ')"
            }
            
            # Remove duplicates and clean labels
            $labels = $labels | Select-Object -Unique | Where-Object { $_ -and $_.Trim() -ne "" }
            Write-Debug "GET-TEMPLATE: Final labels: $($labels -join ', ')"
            
            # Build result object
            $result = [PSCustomObject]@{
                Title = $expandedTitle
                Body = $expandedBody
                Labels = $labels
                TemplateType = $TemplateType
                ErrorSignature = Get-UnityErrorSignature -UnityError $UnityError
                GeneratedAt = Get-Date
            }
            
            Write-Debug "GET-TEMPLATE: Template generation completed successfully"
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [SUCCESS] Get-GitHubIssueTemplate: Generated template for $TemplateType - Title: $expandedTitle"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            return $result
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Get-GitHubIssueTemplate: Failed to generate template - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to generate GitHub issue template: $_"
            throw
        }
    }
    
    end {
        Write-Debug "GET-TEMPLATE: Completed Get-GitHubIssueTemplate"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDUNB57a416wmdJ
# vqsFwEGeZng8qCy8sIvX+azCxy0f5KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAbNXZojj0HPuyWPBZkxSvcI
# RrF/WUqyLQ9rlsaKLYNyMA0GCSqGSIb3DQEBAQUABIIBADpit5ubqGZ1N6/7y57J
# zTfu4PuEEkWh76ghEkHVUZygJEfpadMiZpcg3oLQw5HnQW6VaceENCWdpMUYvt24
# t3Pthv/xu7X0W5l80U9fhK0EDLJ4mZr92I1V3ylKMFn0/8erowRJXe8/On/P4aZj
# 4QU6Eoc8UIEKPnn5CVih03v3t6/i5o6AIHio5sqvsXyLTq0IHnwC5TbujhkyMn2Z
# C5K1zB9aOTzNHwCfc42xjwM8QqaPbrCmovFuZ75mCQzOui/IrYpKuN5pkWuSXiIt
# rhJpwQBnTq3waOZ3ahiYiNW8V1GwOyGhNOpAngjqkLGWgOGZifjJYC6CjciPHkfI
# p90=
# SIG # End signature block
