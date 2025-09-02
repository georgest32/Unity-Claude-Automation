#Requires -Version 5.1
<#
.SYNOPSIS
    Extracts documentation from C# source files including XML comments.

.DESCRIPTION
    Parses C# files to extract XML documentation comments, class structures,
    method signatures, and generates structured documentation. Supports Unity
    MonoBehaviour and ScriptableObject patterns.

.PARAMETER Path
    Path to C# file or directory to analyze

.PARAMETER OutputFormat
    Output format: JSON, Markdown, or Both (default)

.PARAMETER Recurse
    Recursively process directories

.PARAMETER IncludePrivate
    Include private members in documentation

.EXAMPLE
    Get-CSharpDocumentation -Path .\Assets\Scripts -OutputFormat Both -Recurse
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [ValidateSet('JSON', 'Markdown', 'Both')]
    [string]$OutputFormat = 'Both',
    
    [switch]$Recurse,
    
    [switch]$IncludePrivate
)

function Extract-XMLComments {
    param([string]$Content, [int]$LineNumber)
    
    $xmlComments = @{}
    $lines = $Content -split "`n"
    $commentBlock = @()
    $inCommentBlock = $false
    
    # Look backwards from the line number to find XML comments
    for ($i = $LineNumber - 2; $i -ge 0; $i--) {
        $line = $lines[$i].Trim()
        
        if ($line -match '^///\s*(.*)') {
            $commentBlock = @($Matches[1]) + $commentBlock
            $inCommentBlock = $true
        }
        elseif ($inCommentBlock) {
            break
        }
    }
    
    if ($commentBlock.Count -gt 0) {
        $xmlText = "<root>" + ($commentBlock -join "`n") + "</root>"
        
        try {
            $xml = [xml]$xmlText
            
            if ($xml.root.summary) {
                $xmlComments.Summary = $xml.root.summary.Trim()
            }
            
            if ($xml.root.param) {
                $xmlComments.Parameters = @{}
                foreach ($param in $xml.root.param) {
                    if ($param.name) {
                        $xmlComments.Parameters[$param.name] = $param.InnerText.Trim()
                    }
                }
            }
            
            if ($xml.root.returns) {
                $xmlComments.Returns = $xml.root.returns.Trim()
            }
            
            if ($xml.root.remarks) {
                $xmlComments.Remarks = $xml.root.remarks.Trim()
            }
            
            if ($xml.root.example) {
                $xmlComments.Example = $xml.root.example.Trim()
            }
        }
        catch {
            # If XML parsing fails, return raw comments
            $xmlComments.RawComments = $commentBlock -join "`n"
        }
    }
    
    return $xmlComments
}

function Extract-ClassInfo {
    param([string]$FilePath)
    
    Write-Host "Analyzing: $FilePath"
    
    $content = Get-Content -Path $FilePath -Raw
    $classes = @()
    
    # Regex patterns for C# elements
    $classPattern = '(?ms)((?:public|private|protected|internal)\s+)?(?:abstract\s+|sealed\s+|static\s+)?(?:partial\s+)?class\s+(\w+)(?:\s*:\s*([^{]+))?'
    $methodPattern = '(?ms)((?:public|private|protected|internal)\s+)?(?:static\s+|virtual\s+|override\s+|abstract\s+)?(?:async\s+)?(\w+(?:\[\])?|\w+<[^>]+>|void)\s+(\w+)\s*\(([^)]*)\)'
    $propertyPattern = '(?ms)((?:public|private|protected|internal)\s+)?(?:static\s+|virtual\s+|override\s+|abstract\s+)?(\w+(?:\[\])?|\w+<[^>]+>)\s+(\w+)\s*(?:\{|;)'
    $fieldPattern = '(?ms)((?:public|private|protected|internal)\s+)?(?:static\s+|readonly\s+|const\s+)?(\w+(?:\[\])?|\w+<[^>]+>)\s+(\w+)\s*(?:=|;)'
    
    # Find all classes
    $classMatches = [regex]::Matches($content, $classPattern)
    
    foreach ($classMatch in $classMatches) {
        $classInfo = @{
            Name = $classMatch.Groups[2].Value
            AccessModifier = if ($classMatch.Groups[1].Value) { $classMatch.Groups[1].Value.Trim() } else { "internal" }
            BaseClasses = @()
            FilePath = $FilePath
            LineNumber = ($content.Substring(0, $classMatch.Index) -split "`n").Count
            Methods = @()
            Properties = @()
            Fields = @()
            XMLComments = @{}
            IsUnityComponent = $false
        }
        
        # Extract base classes
        if ($classMatch.Groups[3].Value) {
            $bases = $classMatch.Groups[3].Value -split ',' | ForEach-Object { $_.Trim() }
            $classInfo.BaseClasses = $bases
            
            # Check if it's a Unity component
            if ($bases -contains 'MonoBehaviour' -or $bases -contains 'ScriptableObject') {
                $classInfo.IsUnityComponent = $true
                $classInfo.UnityType = if ($bases -contains 'MonoBehaviour') { 'MonoBehaviour' } else { 'ScriptableObject' }
            }
        }
        
        # Extract XML comments for class
        $classInfo.XMLComments = Extract-XMLComments -Content $content -LineNumber $classInfo.LineNumber
        
        # Find class body
        $classStart = $classMatch.Index + $classMatch.Length
        $braceCount = 0
        $classEnd = $classStart
        $foundFirstBrace = $false
        
        for ($i = $classStart; $i -lt $content.Length; $i++) {
            if ($content[$i] -eq '{') {
                $braceCount++
                $foundFirstBrace = $true
            }
            elseif ($content[$i] -eq '}') {
                $braceCount--
                if ($foundFirstBrace -and $braceCount -eq 0) {
                    $classEnd = $i
                    break
                }
            }
        }
        
        $classBody = $content.Substring($classStart, $classEnd - $classStart)
        
        # Extract methods
        $methodMatches = [regex]::Matches($classBody, $methodPattern)
        foreach ($methodMatch in $methodMatches) {
            $accessMod = if ($methodMatch.Groups[1].Value) { $methodMatch.Groups[1].Value.Trim() } else { "private" }
            
            if ($IncludePrivate -or $accessMod -ne "private") {
                $methodLineNum = ($content.Substring(0, $classStart + $methodMatch.Index) -split "`n").Count
                
                $methodInfo = @{
                    Name = $methodMatch.Groups[3].Value
                    ReturnType = $methodMatch.Groups[2].Value
                    AccessModifier = $accessMod
                    Parameters = @()
                    LineNumber = $methodLineNum
                    XMLComments = Extract-XMLComments -Content $content -LineNumber $methodLineNum
                }
                
                # Parse parameters
                if ($methodMatch.Groups[4].Value) {
                    $paramString = $methodMatch.Groups[4].Value
                    $params = $paramString -split ',' | ForEach-Object {
                        $parts = $_.Trim() -split '\s+'
                        if ($parts.Count -ge 2) {
                            @{
                                Type = $parts[0..($parts.Count-2)] -join ' '
                                Name = $parts[-1]
                            }
                        }
                    }
                    $methodInfo.Parameters = $params
                }
                
                $classInfo.Methods += $methodInfo
            }
        }
        
        # Extract properties
        $propertyMatches = [regex]::Matches($classBody, $propertyPattern)
        foreach ($propMatch in $propertyMatches) {
            $accessMod = if ($propMatch.Groups[1].Value) { $propMatch.Groups[1].Value.Trim() } else { "private" }
            
            if ($IncludePrivate -or $accessMod -ne "private") {
                $propLineNum = ($content.Substring(0, $classStart + $propMatch.Index) -split "`n").Count
                
                $propInfo = @{
                    Name = $propMatch.Groups[3].Value
                    Type = $propMatch.Groups[2].Value
                    AccessModifier = $accessMod
                    LineNumber = $propLineNum
                    XMLComments = Extract-XMLComments -Content $content -LineNumber $propLineNum
                }
                
                # Check if it's a Unity serialized field
                $linesBefore = ($content.Substring(0, $classStart + $propMatch.Index) -split "`n")
                if ($linesBefore.Count -gt 1 -and $linesBefore[-2] -match '\[SerializeField\]') {
                    $propInfo.IsSerializedField = $true
                }
                
                $classInfo.Properties += $propInfo
            }
        }
        
        # Extract fields
        $fieldMatches = [regex]::Matches($classBody, $fieldPattern)
        foreach ($fieldMatch in $fieldMatches) {
            $accessMod = if ($fieldMatch.Groups[1].Value) { $fieldMatch.Groups[1].Value.Trim() } else { "private" }
            
            if ($IncludePrivate -or $accessMod -ne "private") {
                $fieldLineNum = ($content.Substring(0, $classStart + $fieldMatch.Index) -split "`n").Count
                
                $fieldInfo = @{
                    Name = $fieldMatch.Groups[3].Value
                    Type = $fieldMatch.Groups[2].Value
                    AccessModifier = $accessMod
                    LineNumber = $fieldLineNum
                    XMLComments = Extract-XMLComments -Content $content -LineNumber $fieldLineNum
                }
                
                # Check for Unity attributes
                $linesBefore = ($content.Substring(0, $classStart + $fieldMatch.Index) -split "`n")
                if ($linesBefore.Count -gt 1) {
                    if ($linesBefore[-2] -match '\[SerializeField\]') {
                        $fieldInfo.IsSerializedField = $true
                    }
                    if ($linesBefore[-2] -match '\[Header\("([^"]+)"\)\]') {
                        $fieldInfo.Header = $Matches[1]
                    }
                    if ($linesBefore[-2] -match '\[Tooltip\("([^"]+)"\)\]') {
                        $fieldInfo.Tooltip = $Matches[1]
                    }
                }
                
                $classInfo.Fields += $fieldInfo
            }
        }
        
        $classes += $classInfo
    }
    
    return $classes
}

function ConvertTo-MarkdownDoc {
    param($Documentation)
    
    $markdown = @()
    $markdown += "# C# Documentation"
    $markdown += ""
    $markdown += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $markdown += ""
    
    # Unity Components section
    $unityComponents = $Documentation.Classes | Where-Object { $_.IsUnityComponent }
    if ($unityComponents) {
        $markdown += "## Unity Components"
        $markdown += ""
        
        foreach ($component in $unityComponents) {
            $markdown += "### $($component.Name) ($($component.UnityType))"
            $markdown += ""
            
            if ($component.XMLComments.Summary) {
                $markdown += $component.XMLComments.Summary
                $markdown += ""
            }
            
            if ($component.Fields -and $component.Fields.Count -gt 0) {
                $markdown += "**Serialized Fields:**"
                $markdown += ""
                
                foreach ($field in ($component.Fields | Where-Object { $_.IsSerializedField })) {
                    $markdown += "- **$($field.Name)** [$($field.Type)]"
                    if ($field.Header) {
                        $markdown += "  - Header: $($field.Header)"
                    }
                    if ($field.Tooltip) {
                        $markdown += "  - Tooltip: $($field.Tooltip)"
                    }
                    if ($field.XMLComments.Summary) {
                        $markdown += "  - $($field.XMLComments.Summary)"
                    }
                }
                $markdown += ""
            }
        }
    }
    
    # Regular Classes section
    $regularClasses = $Documentation.Classes | Where-Object { -not $_.IsUnityComponent }
    if ($regularClasses) {
        $markdown += "## Classes"
        $markdown += ""
        
        foreach ($class in $regularClasses) {
            $markdown += "### $($class.Name)"
            $markdown += ""
            
            if ($class.XMLComments.Summary) {
                $markdown += $class.XMLComments.Summary
                $markdown += ""
            }
            
            if ($class.BaseClasses -and $class.BaseClasses.Count -gt 0) {
                $markdown += "**Inherits:** $($class.BaseClasses -join ', ')"
                $markdown += ""
            }
            
            if ($class.Methods -and $class.Methods.Count -gt 0) {
                $markdown += "**Methods:**"
                $markdown += ""
                
                foreach ($method in $class.Methods) {
                    $params = ($method.Parameters | ForEach-Object { "$($_.Type) $($_.Name)" }) -join ', '
                    $markdown += "- `$($method.Name)($params)` : $($method.ReturnType)"
                    
                    if ($method.XMLComments.Summary) {
                        $markdown += "  - $($method.XMLComments.Summary)"
                    }
                }
                $markdown += ""
            }
            
            if ($class.Properties -and $class.Properties.Count -gt 0) {
                $markdown += "**Properties:**"
                $markdown += ""
                
                foreach ($prop in $class.Properties) {
                    $markdown += "- **$($prop.Name)** [$($prop.Type)]"
                    if ($prop.XMLComments.Summary) {
                        $markdown += "  - $($prop.XMLComments.Summary)"
                    }
                }
                $markdown += ""
            }
            
            $markdown += "**Source:** $($class.FilePath):$($class.LineNumber)"
            $markdown += ""
            $markdown += "---"
            $markdown += ""
        }
    }
    
    return $markdown -join "`n"
}

# Main execution
Write-Host "C# Documentation Extractor"
Write-Host "============================"
Write-Host ""

$documentation = @{
    GeneratedAt = Get-Date
    Path = $Path
    Classes = @()
    Files = @()
    Statistics = @{
        TotalClasses = 0
        TotalMethods = 0
        TotalProperties = 0
        TotalFields = 0
        UnityComponents = 0
    }
}

# Determine files to process
$files = @()

if (Test-Path -Path $Path -PathType Container) {
    # Directory
    if ($Recurse) {
        $files = Get-ChildItem -Path $Path -Filter '*.cs' -Recurse -File
    } else {
        $files = Get-ChildItem -Path $Path -Filter '*.cs' -File
    }
} else {
    # Single file
    $files = @(Get-Item -Path $Path)
}

Write-Host "Found $($files.Count) C# files to process"
Write-Host ""

# Process files
foreach ($file in $files) {
    $documentation.Files += $file.FullName
    
    $classes = Extract-ClassInfo -FilePath $file.FullName
    $documentation.Classes += $classes
    
    # Update statistics
    $documentation.Statistics.TotalClasses += $classes.Count
    foreach ($class in $classes) {
        $documentation.Statistics.TotalMethods += $class.Methods.Count
        $documentation.Statistics.TotalProperties += $class.Properties.Count
        $documentation.Statistics.TotalFields += $class.Fields.Count
        if ($class.IsUnityComponent) {
            $documentation.Statistics.UnityComponents++
        }
    }
}

# Output results
$outputPath = Join-Path -Path (Get-Location) -ChildPath "CSharpDocs_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

if ($OutputFormat -in 'JSON', 'Both') {
    $jsonPath = "$outputPath.json"
    $documentation | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Host "JSON documentation saved to: $jsonPath"
}

if ($OutputFormat -in 'Markdown', 'Both') {
    $mdPath = "$outputPath.md"
    $markdown = ConvertTo-MarkdownDoc -Documentation $documentation
    $markdown | Out-File -FilePath $mdPath -Encoding UTF8
    Write-Host "Markdown documentation saved to: $mdPath"
}

Write-Host ""
Write-Host "Documentation extraction complete!"
Write-Host "Processed:"
Write-Host "  - $($documentation.Statistics.TotalClasses) classes"
Write-Host "  - $($documentation.Statistics.TotalMethods) methods"
Write-Host "  - $($documentation.Statistics.TotalProperties) properties"
Write-Host "  - $($documentation.Statistics.TotalFields) fields"
Write-Host "  - $($documentation.Statistics.UnityComponents) Unity components"

# Return documentation object
return $documentation