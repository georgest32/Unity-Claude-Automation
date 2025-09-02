function Expand-IssueTemplate {
    <#
    .SYNOPSIS
    Expands issue templates with variable substitution
    
    .DESCRIPTION
    Simple template engine for GitHub issue content generation.
    Supports {{variable}} syntax with hashtable/PSCustomObject data.
    Provides conditional sections and basic formatting.
    
    .PARAMETER Template
    Template string with {{variable}} placeholders
    
    .PARAMETER Data
    Data object (hashtable or PSCustomObject) with values for substitution
    
    .PARAMETER ConditionalSections
    Handle conditional sections like {{#property}}...{{/property}}
    
    .EXAMPLE
    $template = "Error: {{errorCode}} in {{file}}"
    $data = @{ errorCode = "CS0103"; file = "Player.cs" }
    Expand-IssueTemplate -Template $template -Data $data
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        $Data,
        
        [Parameter()]
        [bool]$ConditionalSections = $true
    )
    
    begin {
        Write-Debug "EXPAND-TEMPLATE: Starting template expansion"
        Write-Debug "  Template length: $($Template.Length) characters"
        Write-Debug "  Data type: $($Data.GetType().FullName)"
    }
    
    process {
        try {
            $result = $Template
            Write-Debug "EXPAND-TEMPLATE: Created working copy of template"
            
            # Convert data to hashtable for easier processing
            $dataHash = @{}
            
            if ($Data -is [hashtable]) {
                $dataHash = $Data.Clone()
                Write-Debug "EXPAND-TEMPLATE: Using hashtable data directly"
            } elseif ($Data -is [PSCustomObject]) {
                Write-Debug "EXPAND-TEMPLATE: Converting PSCustomObject to hashtable"
                foreach ($property in $Data.PSObject.Properties) {
                    $dataHash[$property.Name] = $property.Value
                    Write-Debug "  Added property: $($property.Name) = $($property.Value)"
                }
            } else {
                throw "Data parameter must be hashtable or PSCustomObject"
            }
            
            Write-Debug "EXPAND-TEMPLATE: Data hashtable prepared with $($dataHash.Keys.Count) keys"
            
            # Handle conditional sections first ({{#property}}...{{/property}})
            if ($ConditionalSections) {
                Write-Debug "EXPAND-TEMPLATE: Processing conditional sections"
                
                # Find conditional blocks
                $conditionalPattern = '\{\{#(\w+)\}\}(.*?)\{\{/\1\}\}'
                $conditionalMatches = [regex]::Matches($result, $conditionalPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                Write-Debug "EXPAND-TEMPLATE: Found $($conditionalMatches.Count) conditional sections"
                
                foreach ($match in $conditionalMatches) {
                    $propertyName = $match.Groups[1].Value
                    $sectionContent = $match.Groups[2].Value
                    $fullMatch = $match.Groups[0].Value
                    
                    Write-Debug "EXPAND-TEMPLATE: Processing conditional section: $propertyName"
                    
                    if ($dataHash.ContainsKey($propertyName) -and 
                        $dataHash[$propertyName] -and 
                        $dataHash[$propertyName] -ne "" -and
                        $dataHash[$propertyName] -ne $null) {
                        
                        Write-Debug "EXPAND-TEMPLATE: Conditional section '$propertyName' - condition TRUE, including content"
                        # Include the section content (still with variables to be expanded)
                        $result = $result.Replace($fullMatch, $sectionContent)
                    } else {
                        Write-Debug "EXPAND-TEMPLATE: Conditional section '$propertyName' - condition FALSE, removing section"
                        # Remove the entire section
                        $result = $result.Replace($fullMatch, "")
                    }
                }
            }
            
            # Replace simple variables ({{variable}})
            Write-Debug "EXPAND-TEMPLATE: Processing variable substitutions"
            $variablePattern = '\{\{(\w+)\}\}'
            $variableMatches = [regex]::Matches($result, $variablePattern)
            
            Write-Debug "EXPAND-TEMPLATE: Found $($variableMatches.Count) variable references"
            
            foreach ($match in $variableMatches) {
                $variableName = $match.Groups[1].Value
                $fullMatch = $match.Groups[0].Value
                
                Write-Debug "EXPAND-TEMPLATE: Processing variable: $variableName"
                
                if ($dataHash.ContainsKey($variableName)) {
                    $value = $dataHash[$variableName]
                    
                    # Handle null values
                    if ($value -eq $null) {
                        $value = ""
                        Write-Debug "EXPAND-TEMPLATE: Variable '$variableName' is null, using empty string"
                    }
                    
                    Write-Debug "EXPAND-TEMPLATE: Replacing $fullMatch with: $value"
                    $result = $result.Replace($fullMatch, $value.ToString())
                } else {
                    Write-Debug "EXPAND-TEMPLATE: Variable '$variableName' not found in data, leaving placeholder"
                    # Leave placeholder for missing variables (could be intentional)
                }
            }
            
            # Clean up any remaining empty conditional markers
            $result = $result -replace '\{\{#\w+\}\}', '' -replace '\{\{/\w+\}\}', ''
            
            # Normalize line endings and whitespace
            $result = $result -replace '\r\n', "`n" -replace '\r', "`n"
            $result = $result -replace '\n{3,}', "`n`n"  # Limit consecutive newlines
            
            Write-Debug "EXPAND-TEMPLATE: Template expansion completed"
            Write-Debug "  Result length: $($result.Length) characters"
            
            return $result.Trim()
        }
        catch {
            Write-Error "Failed to expand issue template: $_"
            throw
        }
    }
    
    end {
        Write-Debug "EXPAND-TEMPLATE: Completed Expand-IssueTemplate"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCpg5VZ4HbYrwB8
# ZT68izZWLnqbhSrV5trjIfm56qXBnqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPTMpT6DQjEgAcAVGQWavbDl
# TViEYwyCfBEJOGX664ZDMA0GCSqGSIb3DQEBAQUABIIBAEPW2MdJilSaQ3U8QrBv
# QadJFnkgGf2PR17h9Yr+FoDmkbO1KoJGowUGfPIurvI4DkWJDg/UHo5ORpLohF2B
# /ECPDBhp+bciwTeDwYJ8KsMcQxmGJgOTvhOY3pStRUrdrtRU4X82AIKbVnJqe6GV
# NMNx0ANhRTK7Zm9ASFdYgUjaKthvtHCBZB9fu2CYduruAAxhCB9zP3psvFKaLhyh
# H6/IBDBHK+P3iBBtoQw+DQ1llFrI+yFM62vCt2Vezd3sxyXR4TO+WLgHkRl2cLAD
# v/6MI7G9f3WWqIOFG4T3KXwAARc6O75RqcSJgHQ5GlC4hHno4UlNd/KSvA+VJhCP
# Ga0=
# SIG # End signature block
