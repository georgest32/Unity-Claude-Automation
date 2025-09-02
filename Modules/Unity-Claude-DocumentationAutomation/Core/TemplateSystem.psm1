#region Module Header
<#
.SYNOPSIS
    Documentation Template Management System
    
.DESCRIPTION
    Handles creation, management, and usage of documentation templates for different
    types of content including functions, classes, modules, and guides.
    
.VERSION
    2.0.0
    
.AUTHOR
    Unity-Claude-Automation
#>
#endregion

#region Template Management Functions

function New-DocumentationTemplate {
    <#
    .SYNOPSIS
        Creates a new documentation template
    .DESCRIPTION
        Creates reusable templates for different types of documentation
    .PARAMETER Name
        Template name
    .PARAMETER Type
        Template type (Function, Class, Module, API, etc.)
    .PARAMETER Template
        Template content with placeholders
    .EXAMPLE
        New-DocumentationTemplate -Name "PowerShellFunction" -Type "Function" -Template $template
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateSet('Function', 'Class', 'Module', 'API', 'Guide', 'Tutorial', 'Reference')]
        [string]$Type,
        [Parameter(Mandatory)]
        [string]$Template,
        [string]$Description,
        [hashtable]$Placeholders = @{},
        [string[]]$Tags = @()
    )
    
    try {
        $templateObj = @{
            Name = $Name
            Type = $Type
            Template = $Template
            Description = $Description
            Placeholders = $Placeholders
            Tags = $Tags
            CreatedAt = Get-Date
            UpdatedAt = Get-Date
            UsageCount = 0
        }
        
        $script:TemplateCache[$Name] = $templateObj
        
        # Save to disk
        $templatesPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation "Templates"
        if (-not (Test-Path $templatesPath)) {
            New-Item -Path $templatesPath -ItemType Directory -Force | Out-Null
        }
        
        $templateFile = Join-Path $templatesPath "$Name.json"
        $templateObj | ConvertTo-Json -Depth 10 | Out-File -FilePath $templateFile -Encoding UTF8
        
        Write-Host "Documentation template '$Name' created successfully" -ForegroundColor Green
        
        return $templateObj
        
    } catch {
        Write-Error "Failed to create documentation template: $_"
        throw
    }
}

function Get-DocumentationTemplates {
    <#
    .SYNOPSIS
        Gets available documentation templates
    .DESCRIPTION
        Returns list of available templates with filtering options
    .PARAMETER Type
        Filter by template type
    .PARAMETER Name
        Get specific template by name
    .EXAMPLE
        Get-DocumentationTemplates -Type Function
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Function', 'Class', 'Module', 'API', 'Guide', 'Tutorial', 'Reference', 'All')]
        [string]$Type = 'All',
        [string]$Name,
        [string[]]$Tags
    )
    
    try {
        if ($Name) {
            return $script:TemplateCache[$Name]
        }
        
        $templates = $script:TemplateCache.Values
        
        if ($Type -ne 'All') {
            $templates = $templates | Where-Object { $_.Type -eq $Type }
        }
        
        if ($Tags) {
            $templates = $templates | Where-Object { 
                $templateTags = $_.Tags
                $Tags | ForEach-Object { $templateTags -contains $_ }
            }
        }
        
        return $templates | Sort-Object Name
        
    } catch {
        Write-Error "Error getting documentation templates: $_"
        throw
    }
}

function Update-DocumentationTemplate {
    <#
    .SYNOPSIS
        Updates an existing documentation template
    .DESCRIPTION
        Modifies template content and metadata
    .PARAMETER Name
        Template name to update
    .PARAMETER Template
        New template content
    .EXAMPLE
        Update-DocumentationTemplate -Name "PowerShellFunction" -Template $newTemplate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Template,
        [string]$Description,
        [hashtable]$Placeholders,
        [string[]]$Tags
    )
    
    try {
        if (-not $script:TemplateCache.ContainsKey($Name)) {
            throw "Template '$Name' not found"
        }
        
        $templateObj = $script:TemplateCache[$Name]
        
        if ($Template) { $templateObj.Template = $Template }
        if ($Description) { $templateObj.Description = $Description }
        if ($Placeholders) { $templateObj.Placeholders = $Placeholders }
        if ($Tags) { $templateObj.Tags = $Tags }
        $templateObj.UpdatedAt = Get-Date
        
        # Save updated template
        $templatesPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation "Templates"
        $templateFile = Join-Path $templatesPath "$Name.json"
        $templateObj | ConvertTo-Json -Depth 10 | Out-File -FilePath $templateFile -Encoding UTF8
        
        Write-Host "Template '$Name' updated successfully" -ForegroundColor Green
        
        return $templateObj
        
    } catch {
        Write-Error "Failed to update documentation template: $_"
        throw
    }
}

function Export-DocumentationTemplates {
    <#
    .SYNOPSIS
        Exports documentation templates to file
    .DESCRIPTION
        Exports all or selected templates to a file for backup or sharing
    .PARAMETER OutputPath
        Path for template export file
    .PARAMETER Names
        Specific template names to export (all if not specified)
    .EXAMPLE
        Export-DocumentationTemplates -OutputPath ".\templates-backup.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [string[]]$Names,
        [ValidateSet('JSON', 'ZIP')]
        [string]$Format = 'JSON'
    )
    
    try {
        Write-Host "Exporting documentation templates..." -ForegroundColor Cyan
        
        $templatesToExport = if ($Names) {
            $script:TemplateCache.GetEnumerator() | Where-Object { $Names -contains $_.Key }
        } else {
            $script:TemplateCache.GetEnumerator()
        }
        
        $exportData = @{
            ExportedAt = Get-Date
            Version = "2.0.0"
            Templates = @{}
        }
        
        foreach ($entry in $templatesToExport) {
            $exportData.Templates[$entry.Key] = $entry.Value
        }
        
        switch ($Format) {
            'JSON' {
                $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            'ZIP' {
                $tempDir = Join-Path $env:TEMP "template-export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
                
                foreach ($entry in $templatesToExport) {
                    $templateFile = Join-Path $tempDir "$($entry.Key).json"
                    $entry.Value | ConvertTo-Json -Depth 10 | Out-File -FilePath $templateFile -Encoding UTF8
                }
                
                Compress-Archive -Path "$tempDir\*" -DestinationPath $OutputPath -Force
                Remove-Item -Path $tempDir -Recurse -Force
            }
        }
        
        Write-Host "Templates exported successfully" -ForegroundColor Green
        Write-Host "  Count: $($templatesToExport.Count)" -ForegroundColor Gray
        Write-Host "  Format: $Format" -ForegroundColor Gray
        Write-Host "  Output: $OutputPath" -ForegroundColor Gray
        
        return @{
            Count = $templatesToExport.Count
            OutputPath = $OutputPath
            Format = $Format
        }
        
    } catch {
        Write-Error "Failed to export documentation templates: $_"
        throw
    }
}

function Import-DocumentationTemplates {
    <#
    .SYNOPSIS
        Imports documentation templates from file
    .DESCRIPTION
        Imports templates from a previously exported file
    .PARAMETER InputPath
        Path to template import file
    .PARAMETER Overwrite
        Overwrite existing templates with same names
    .EXAMPLE
        Import-DocumentationTemplates -InputPath ".\templates-backup.json" -Overwrite
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [switch]$Overwrite,
        [ValidateSet('JSON', 'ZIP')]
        [string]$Format = 'JSON'
    )
    
    try {
        if (-not (Test-Path $InputPath)) {
            throw "Template import file not found: $InputPath"
        }
        
        Write-Host "Importing documentation templates..." -ForegroundColor Cyan
        
        $importedCount = 0
        $skippedCount = 0
        
        switch ($Format) {
            'JSON' {
                $importData = Get-Content $InputPath | ConvertFrom-Json
                
                foreach ($templateEntry in $importData.Templates.PSObject.Properties) {
                    $name = $templateEntry.Name
                    $template = $templateEntry.Value
                    
                    if ($script:TemplateCache.ContainsKey($name) -and -not $Overwrite) {
                        Write-Warning "Template '$name' already exists, skipping (use -Overwrite to replace)"
                        $skippedCount++
                        continue
                    }
                    
                    $script:TemplateCache[$name] = $template
                    
                    # Save to disk
                    $templatesPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation "Templates"
                    if (-not (Test-Path $templatesPath)) {
                        New-Item -Path $templatesPath -ItemType Directory -Force | Out-Null
                    }
                    
                    $templateFile = Join-Path $templatesPath "$name.json"
                    $template | ConvertTo-Json -Depth 10 | Out-File -FilePath $templateFile -Encoding UTF8
                    
                    $importedCount++
                }
            }
            'ZIP' {
                $tempDir = Join-Path $env:TEMP "template-import-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Expand-Archive -Path $InputPath -DestinationPath $tempDir -Force
                
                Get-ChildItem -Path $tempDir -Filter "*.json" | ForEach-Object {
                    $name = $_.BaseName
                    $template = Get-Content $_.FullName | ConvertFrom-Json
                    
                    if ($script:TemplateCache.ContainsKey($name) -and -not $Overwrite) {
                        Write-Warning "Template '$name' already exists, skipping (use -Overwrite to replace)"
                        $skippedCount++
                        return
                    }
                    
                    $script:TemplateCache[$name] = $template
                    
                    # Save to persistent location
                    $templatesPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation "Templates"
                    if (-not (Test-Path $templatesPath)) {
                        New-Item -Path $templatesPath -ItemType Directory -Force | Out-Null
                    }
                    
                    Copy-Item -Path $_.FullName -Destination (Join-Path $templatesPath $_.Name) -Force
                    $importedCount++
                }
                
                Remove-Item -Path $tempDir -Recurse -Force
            }
        }
        
        Write-Host "Templates imported successfully" -ForegroundColor Green
        Write-Host "  Imported: $importedCount" -ForegroundColor Gray
        Write-Host "  Skipped: $skippedCount" -ForegroundColor Gray
        
        return @{
            ImportedCount = $importedCount
            SkippedCount = $skippedCount
            InputPath = $InputPath
        }
        
    } catch {
        Write-Error "Failed to import documentation templates: $_"
        throw
    }
}

function Invoke-TemplateRendering {
    <#
    .SYNOPSIS
        Renders a documentation template with provided data
    .DESCRIPTION
        Takes a template and data to produce final documentation content
    .PARAMETER TemplateName
        Name of template to render
    .PARAMETER Data
        Data hashtable for template placeholders
    .EXAMPLE
        Invoke-TemplateRendering -TemplateName "PowerShellFunction" -Data $functionData
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,
        [Parameter(Mandatory)]
        [hashtable]$Data
    )
    
    try {
        if (-not $script:TemplateCache.ContainsKey($TemplateName)) {
            throw "Template '$TemplateName' not found"
        }
        
        $template = $script:TemplateCache[$TemplateName]
        $content = $template.Template
        
        # Update usage count
        $template.UsageCount++
        $template.LastUsed = Get-Date
        
        # Replace placeholders
        foreach ($placeholder in $template.Placeholders.Keys) {
            $placeholderPattern = "{{$placeholder}}"
            if ($Data.ContainsKey($placeholder)) {
                $content = $content -replace [regex]::Escape($placeholderPattern), $Data[$placeholder]
            } else {
                $content = $content -replace [regex]::Escape($placeholderPattern), $template.Placeholders[$placeholder]
            }
        }
        
        # Replace any remaining data placeholders
        foreach ($dataEntry in $Data.GetEnumerator()) {
            $placeholderPattern = "{{$($dataEntry.Key)}}"
            $content = $content -replace [regex]::Escape($placeholderPattern), $dataEntry.Value
        }
        
        Write-Verbose "Template '$TemplateName' rendered successfully"
        
        return $content
        
    } catch {
        Write-Error "Failed to render template: $_"
        throw
    }
}

#endregion

Export-ModuleMember -Function @(
    'New-DocumentationTemplate',
    'Get-DocumentationTemplates',
    'Update-DocumentationTemplate',
    'Export-DocumentationTemplates',
    'Import-DocumentationTemplates',
    'Invoke-TemplateRendering'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDHrH4p349jFn6V
# gz4i+IKlESg2G7HvVk7m4fYoYqFJAaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFQUfAG9Sq8kF7dU/GfL1miN
# B/fp4necsitbvsenAr2PMA0GCSqGSIb3DQEBAQUABIIBAJF5GN+Zz9FMk/eViONg
# ryttPSIWZV6BTQ/bHtiDdQUbd3t/5I6bCOn5VGjHbwisQYfrO/JIwHw4BqaODt9c
# xW3V3wF9Zdn4qAc1IkZY8QmpjTX9CDmgALFJKCWc6nOYFhXgJtU+rchmbRRS1Lyx
# Ug+czWtHkgbbijTXXE+dj4xGXytOTapXhtiKDYAiZXQRbazUAcpVlUPMuFp96CdP
# Hg/o0Q9lZacRPFrwhFgZTnSP0u8Tp6vn5PvmEaPrKXWMnctXA9mAZ1RVixE9XJtk
# NsvuZqcWUsBg5/jo5yp2MyIL0LuUL2+Dw6hRXZGXFVWad9lbF+WKRoSKgg/K+H3f
# 3KM=
# SIG # End signature block
