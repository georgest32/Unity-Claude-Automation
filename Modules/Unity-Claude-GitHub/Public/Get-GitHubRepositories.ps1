function Get-GitHubRepositories {
    <#
    .SYNOPSIS
    Gets configured GitHub repositories for Unity projects
    
    .DESCRIPTION
    Retrieves list of GitHub repositories configured for Unity-Claude automation,
    including project mappings and repository metadata
    
    .PARAMETER ConfigPath
    Path to GitHub integration configuration file
    
    .PARAMETER IncludeMetadata
    Include repository metadata from GitHub API
    
    .PARAMETER TestAccess
    Test API access to each repository
    
    .EXAMPLE
    Get-GitHubRepositories -IncludeMetadata -TestAccess
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigPath,
        
        [switch]$IncludeMetadata,
        
        [switch]$TestAccess
    )
    
    try {
        # Get configuration
        $config = Get-GitHubIntegrationConfig -ConfigPath $ConfigPath
        
        if (-not $config.repositories) {
            Write-Warning "No repositories configured"
            return @()
        }
        
        $repositories = @()
        
        foreach ($repo in $config.repositories) {
            $repoInfo = [PSCustomObject]@{
                Owner = $repo.owner
                Name = $repo.name
                FullName = "$($repo.owner)/$($repo.name)"
                UnityProjects = $repo.unityProjects
                IsDefault = $repo.isDefault -eq $true
                Priority = if ($repo.priority) { $repo.priority } else { 0 }
                Labels = $repo.labels
                Categories = $repo.categories
                AccessTestPassed = $null
                Metadata = $null
            }
            
            # Test access if requested
            if ($TestAccess) {
                Write-Verbose "Testing access to $($repoInfo.FullName)"
                $accessTest = Test-GitHubRepositoryAccess -Owner $repo.owner -Repository $repo.name
                $repoInfo.AccessTestPassed = $accessTest.Success
                
                if (-not $accessTest.Success) {
                    Write-Warning "Failed to access repository $($repoInfo.FullName): $($accessTest.Error)"
                }
            }
            
            # Get metadata if requested
            if ($IncludeMetadata) {
                try {
                    $pat = Get-GitHubPATInternal
                    if ($pat) {
                        $headers = @{
                            "Authorization" = "Bearer $pat"
                            "Accept" = "application/vnd.github+json"
                        }
                        
                        $repoUri = "https://api.github.com/repos/$($repo.owner)/$($repo.name)"
                        $metadata = Invoke-GitHubAPIWithRetry -Uri $repoUri -Headers $headers -Method Get
                        
                        $repoInfo.Metadata = [PSCustomObject]@{
                            Description = $metadata.description
                            Private = $metadata.private
                            DefaultBranch = $metadata.default_branch
                            OpenIssuesCount = $metadata.open_issues_count
                            CreatedAt = $metadata.created_at
                            UpdatedAt = $metadata.updated_at
                            Language = $metadata.language
                            Topics = $metadata.topics
                        }
                    }
                } catch {
                    Write-Warning "Failed to get metadata for $($repoInfo.FullName): $_"
                }
            }
            
            $repositories += $repoInfo
        }
        
        # Sort by priority (higher first) then by default status
        $repositories = $repositories | Sort-Object -Property @{Expression = {$_.Priority}; Descending = $true}, IsDefault -Descending
        
        return $repositories
        
    } catch {
        Write-Error "Failed to get GitHub repositories: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Get-GitHubRepositories
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD7NCJDTC1zL+VY
# Vk2nD0wtXsJ6l9jxaq8+uUgqE6rTFKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHHVwEfHSYRnmnU3sL2AX35y
# oyNlnMjFyrmEY0BRqrt3MA0GCSqGSIb3DQEBAQUABIIBAKZZe9myp8h9rpRpUyN+
# ahST+QJKg3IvSpdhd6VHfgbU3D3UcsyIqeJx6p7b272DTs20avCjB5qAd0j/wusT
# CNV5R48Ef7769ErYNkJZY77XagaIf6mX1ZL+maSgcQ4e1fHeE81fTHIJdlaZgGNM
# ZSXJMv0zqTZEirnBnZz6HP7GiYHZq7VoVLmeXt69Egs+GwSRNYRf/UVfdT8IAuZd
# veIY0Nv3poYFgwRsOzAAxtmEmvF3ALCdUfLN+7tNx7q/9/a81iVe8YP812eSKl43
# r4mXwvmjiWaK9qSvmWMrTbrk+GlirCKW2FxaXGO3buZap4X49+GhYMAeDLIF2FZ/
# QCo=
# SIG # End signature block
