function Get-UnityProjectCategory {
    <#
    .SYNOPSIS
    Gets the category and repository mapping for a Unity project
    
    .DESCRIPTION
    Determines which GitHub repository and category a Unity project belongs to
    based on project path, name, or configuration
    
    .PARAMETER ProjectPath
    Path to the Unity project
    
    .PARAMETER ProjectName
    Name of the Unity project
    
    .PARAMETER ErrorContext
    Error context to help determine categorization
    
    .PARAMETER ConfigPath
    Path to GitHub integration configuration file
    
    .EXAMPLE
    Get-UnityProjectCategory -ProjectPath "C:\UnityProjects\MyGame" -ErrorContext "Shader compilation error"
    #>
    [CmdletBinding()]
    param(
        [string]$ProjectPath,
        
        [string]$ProjectName,
        
        [string]$ErrorContext,
        
        [string]$ConfigPath
    )
    
    try {
        # Get configuration
        $config = Get-GitHubIntegrationConfig -ConfigPath $ConfigPath
        
        $result = [PSCustomObject]@{
            ProjectName = $ProjectName
            ProjectPath = $ProjectPath
            Repository = $null
            Category = "general"
            Labels = @()
            Priority = 0
            MatchedBy = "default"
        }
        
        # If no project name, try to extract from path
        if (-not $ProjectName -and $ProjectPath) {
            $ProjectName = Split-Path $ProjectPath -Leaf
            $result.ProjectName = $ProjectName
        }
        
        # Find matching repository configuration
        $matchedRepo = $null
        
        foreach ($repo in $config.repositories) {
            if ($repo.unityProjects) {
                foreach ($project in $repo.unityProjects) {
                    # Check if project matches by name
                    if ($project.name -eq $ProjectName) {
                        $matchedRepo = $repo
                        $result.MatchedBy = "name"
                        break
                    }
                    
                    # Check if project matches by path pattern
                    if ($project.pathPattern -and $ProjectPath) {
                        if ($ProjectPath -like $project.pathPattern) {
                            $matchedRepo = $repo
                            $result.MatchedBy = "path"
                            break
                        }
                    }
                }
            }
            
            if ($matchedRepo) { break }
        }
        
        # If no specific match, use default repository
        if (-not $matchedRepo) {
            $matchedRepo = $config.repositories | Where-Object { $_.isDefault -eq $true } | Select-Object -First 1
            $result.MatchedBy = "default"
        }
        
        # If still no match, use first repository
        if (-not $matchedRepo -and $config.repositories.Count -gt 0) {
            $matchedRepo = $config.repositories[0]
            $result.MatchedBy = "fallback"
        }
        
        if ($matchedRepo) {
            $result.Repository = "$($matchedRepo.owner)/$($matchedRepo.name)"
            
            # Determine category based on error context and project configuration
            $category = "general"
            $labels = @()
            
            # Check project-specific category
            $projectConfig = $matchedRepo.unityProjects | Where-Object { $_.name -eq $ProjectName }
            if ($projectConfig -and $projectConfig.category) {
                $category = $projectConfig.category
            }
            
            # Analyze error context for categorization
            if ($ErrorContext) {
                # Shader errors
                if ($ErrorContext -match "shader|HLSL|GLSL|material|rendering") {
                    $category = "graphics"
                    $labels += "shader"
                }
                # Networking errors
                elseif ($ErrorContext -match "network|socket|connection|multiplayer|Mirror|Netcode") {
                    $category = "networking"
                    $labels += "networking"
                }
                # Physics errors
                elseif ($ErrorContext -match "physics|rigidbody|collider|collision|Physics2D") {
                    $category = "physics"
                    $labels += "physics"
                }
                # UI errors
                elseif ($ErrorContext -match "UI|canvas|button|text|TMPro|TextMeshPro") {
                    $category = "ui"
                    $labels += "ui"
                }
                # Audio errors
                elseif ($ErrorContext -match "audio|sound|AudioSource|AudioClip|mixer") {
                    $category = "audio"
                    $labels += "audio"
                }
                # Build errors
                elseif ($ErrorContext -match "build|platform|iOS|Android|WebGL|compilation") {
                    $category = "build"
                    $labels += "build"
                }
                # Animation errors
                elseif ($ErrorContext -match "animation|animator|AnimationClip|timeline") {
                    $category = "animation"
                    $labels += "animation"
                }
                # AI/Navigation errors
                elseif ($ErrorContext -match "NavMesh|pathfinding|AI|agent") {
                    $category = "ai"
                    $labels += "ai-navigation"
                }
                # Input system errors
                elseif ($ErrorContext -match "Input|InputSystem|controller|keyboard|mouse") {
                    $category = "input"
                    $labels += "input-system"
                }
                # Package/dependency errors
                elseif ($ErrorContext -match "package|PackageManager|dependency|assembly") {
                    $category = "packages"
                    $labels += "package-manager"
                }
            }
            
            $result.Category = $category
            
            # Add repository-specific labels
            if ($matchedRepo.labels) {
                $labels += $matchedRepo.labels
            }
            
            # Add category-specific labels from config
            if ($matchedRepo.categories -and $matchedRepo.categories.$category) {
                if ($matchedRepo.categories.$category.labels) {
                    $labels += $matchedRepo.categories.$category.labels
                }
                if ($matchedRepo.categories.$category.priority) {
                    $result.Priority = $matchedRepo.categories.$category.priority
                }
            }
            
            # Add Unity version label if available
            if ($ProjectPath -and (Test-Path "$ProjectPath\ProjectSettings\ProjectVersion.txt")) {
                $versionContent = Get-Content "$ProjectPath\ProjectSettings\ProjectVersion.txt" -First 1
                if ($versionContent -match "(\d+\.\d+)") {
                    $labels += "unity-$($Matches[1])"
                }
            }
            
            # Remove duplicates
            $result.Labels = $labels | Select-Object -Unique
            
            # Set default priority if not set
            if ($result.Priority -eq 0) {
                # Set priority based on category
                $result.Priority = switch ($category) {
                    "build" { 3 }      # High priority - blocks releases
                    "networking" { 2 } # Medium-high - affects multiplayer
                    "physics" { 2 }    # Medium-high - affects gameplay
                    "graphics" { 2 }   # Medium-high - affects visuals
                    "ui" { 1 }        # Medium - affects user experience
                    "audio" { 1 }     # Medium - affects experience
                    "packages" { 1 }   # Medium - affects dependencies
                    default { 0 }      # Low - general issues
                }
            }
        }
        
        Write-Verbose "Project categorized as: $($result.Category) in repository: $($result.Repository)"
        return $result
        
    } catch {
        Write-Error "Failed to get Unity project category: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Get-UnityProjectCategory
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB5eetMrqsYgsVg
# 4V8fo/M1zoTiI0P8UQlgj0KW45XXcKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMWneLjk3HrAf8Rw2pQCJeaj
# XF4MhcsdSWoyjejG9WjPMA0GCSqGSIb3DQEBAQUABIIBAICFy0zjESRX0nekE+oT
# opP9hNyzijc/UZOS+IAvlD+BUqvSREmEAUk2poydbfzHxiTOjsh0hZE7Fwhzl91f
# foFs9LP6K7JLU+cU2mCA5dItQ9fEEUTWannCUAwILaCyHgjbSfI+thVBClQXiVXy
# Kf9JbPZGYZCXZQeMJfNuAxM4ZTE/hu+n/6uXHHkGll9tU70fH1N5VKgQFOV25RUj
# ci02LrcfClSdRyrewxXYqjgIWeGcb+GQnmhIA9oU/y3Yjq3pbzTh2+fshB4baKoy
# L07ny/aAkYW3ig0n6bgGGfK8/v9wbWVZ5n5pzHNphGJvPch9bfRuA8XTaFw5MOJx
# 4II=
# SIG # End signature block
