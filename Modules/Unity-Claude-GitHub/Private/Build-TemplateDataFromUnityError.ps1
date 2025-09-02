function Build-TemplateDataFromUnityError {
    <#
    .SYNOPSIS
    Builds template data hashtable from Unity error object
    
    .DESCRIPTION
    Extracts and formats Unity error information into a hashtable
    suitable for template variable substitution.
    
    .PARAMETER UnityError
    Unity error object to process
    
    .PARAMETER IncludeCodeContext
    Include code context in template data (default: true)
    
    .EXAMPLE
    $data = Build-TemplateDataFromUnityError -UnityError $error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UnityError,
        
        [Parameter()]
        [bool]$IncludeCodeContext = $true
    )
    
    begin {
        Write-Debug "BUILD-TEMPLATE-DATA: Starting template data construction"
    }
    
    process {
        try {
            # Initialize template data hashtable
            $templateData = @{}
            
            # Extract basic error information
            $errorCode = ""
            $errorMessage = ""
            $scriptPath = ""
            $lineNumber = 0
            $columnNumber = 0
            
            # Parse from error text if available
            if ($UnityError.ErrorText) {
                Write-Debug "BUILD-TEMPLATE-DATA: Parsing error text: $($UnityError.ErrorText)"
                
                # Standard Unity error format: "Assets/Scripts/File.cs(10,5): error CS0103: Message"
                if ($UnityError.ErrorText -match '^(.+?)\((\d+),(\d+)\):\s*error\s+(\w+):\s*(.+)$') {
                    $scriptPath = $Matches[1]
                    $lineNumber = [int]$Matches[2]
                    $columnNumber = [int]$Matches[3]
                    $errorCode = $Matches[4]
                    $errorMessage = $Matches[5]
                    Write-Debug "BUILD-TEMPLATE-DATA: Parsed standard format successfully"
                }
                # Alternative parsing for different formats
                elseif ($UnityError.ErrorText -match 'error\s+(\w+):\s*(.+)$') {
                    $errorCode = $Matches[1]
                    $errorMessage = $Matches[2]
                    Write-Debug "BUILD-TEMPLATE-DATA: Parsed alternative format"
                }
            }
            
            # Override with explicit properties if available
            if ($UnityError.Code) { $errorCode = $UnityError.Code }
            if ($UnityError.Message) { $errorMessage = $UnityError.Message }
            if ($UnityError.File) { $scriptPath = $UnityError.File }
            if ($UnityError.Line) { $lineNumber = $UnityError.Line }
            if ($UnityError.Column) { $columnNumber = $UnityError.Column }
            
            Write-Debug "BUILD-TEMPLATE-DATA: Final values - Code: $errorCode, File: $scriptPath, Line: $lineNumber"
            
            # Build core template data
            $templateData['errorCode'] = $errorCode
            $templateData['errorMessage'] = $errorMessage
            $templateData['scriptPath'] = $scriptPath
            $templateData['lineNumber'] = $lineNumber
            $templateData['columnNumber'] = $columnNumber
            $templateData['fullErrorText'] = $UnityError.ErrorText
            
            # Add derived information
            $templateData['fileName'] = if ($scriptPath) { Split-Path $scriptPath -Leaf } else { "" }
            $templateData['fileDirectory'] = if ($scriptPath) { Split-Path $scriptPath -Parent } else { "" }
            $templateData['errorSignature'] = Get-UnityErrorSignature -UnityError $UnityError
            
            # Add Unity and system information
            $templateData['unityVersion'] = if ($UnityError.UnityVersion) { 
                $UnityError.UnityVersion 
            } else { 
                Get-UnityVersionFromEditorLog 
            }
            $templateData['platform'] = "Windows"
            $templateData['timestamp'] = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            
            # Add project information
            $templateData['projectName'] = if ($UnityError.Project) { 
                $UnityError.Project 
            } else { 
                Get-CurrentUnityProjectName 
            }
            
            # Error categorization
            $templateData['errorCategory'] = Get-UnityErrorCategory -ErrorCode $errorCode -ErrorMessage $errorMessage
            $templateData['severity'] = Get-UnityErrorSeverity -UnityError $UnityError
            
            # Add code context if requested and available
            if ($IncludeCodeContext -and $scriptPath -and $lineNumber -gt 0) {
                Write-Debug "BUILD-TEMPLATE-DATA: Attempting to include code context"
                $codeContext = Get-UnityErrorCodeContext -ScriptPath $scriptPath -LineNumber $lineNumber
                $templateData['codeContext'] = $codeContext
                
                if ($codeContext) {
                    Write-Debug "BUILD-TEMPLATE-DATA: Code context included successfully"
                } else {
                    Write-Debug "BUILD-TEMPLATE-DATA: No code context available"
                }
            }
            
            # Add stack trace information if available
            if ($UnityError.StackTrace) {
                $templateData['stackTrace'] = $UnityError.StackTrace
            } elseif ($UnityError.CallStack) {
                $templateData['stackTrace'] = $UnityError.CallStack
            } else {
                $templateData['stackTrace'] = ""
            }
            
            # Add Unity-specific information
            if ($UnityError.GameObject) { $templateData['gameObject'] = $UnityError.GameObject }
            if ($UnityError.Component) { $templateData['component'] = $UnityError.Component }
            if ($UnityError.Scene) { $templateData['sceneName'] = $UnityError.Scene }
            
            Write-Debug "BUILD-TEMPLATE-DATA: Template data construction completed"
            Write-Debug "  Total properties: $($templateData.Keys.Count)"
            
            return $templateData
        }
        catch {
            Write-Error "Failed to build template data from Unity error: $_"
            throw
        }
    }
    
    end {
        Write-Debug "BUILD-TEMPLATE-DATA: Completed Build-TemplateDataFromUnityError"
    }
}

function Get-UnityVersionFromEditorLog {
    # Helper function to extract Unity version from Editor.log
    $editorLog = "C:\Users\$env:USERNAME\AppData\Local\Unity\Editor\Editor.log"
    if (Test-Path $editorLog) {
        $versionLine = Get-Content $editorLog -TotalCount 10 | Where-Object { $_ -match 'Unity\s+([\d\.]+)' }
        if ($versionLine) {
            return $Matches[1]
        }
    }
    return "Unknown"
}

function Get-CurrentUnityProjectName {
    # Helper function to get current Unity project name
    $currentPath = Get-Location
    $projectPath = $currentPath.Path
    
    # Look for Unity project indicators
    if (Test-Path (Join-Path $projectPath "Assets")) {
        return Split-Path $projectPath -Leaf
    }
    
    return "Unknown"
}

function Get-UnityErrorCategory {
    param($ErrorCode, $ErrorMessage)
    
    if ($ErrorCode -match '^CS\d+') { return "CSharp" }
    if ($ErrorMessage -match 'null reference') { return "NullReference" }
    if ($ErrorMessage -match 'missing component') { return "MissingComponent" }
    if ($ErrorMessage -match 'MonoBehaviour|GameObject') { return "Unity" }
    
    return "General"
}

function Get-UnityErrorSeverity {
    param($UnityError)
    
    $errorMessage = $UnityError.Message
    if (-not $errorMessage) { $errorMessage = $UnityError.ErrorText }
    
    if ($errorMessage -match 'critical|fatal|exception') { return "Critical" }
    if ($errorMessage -match 'warning') { return "Warning" }
    if ($errorMessage -match 'info|note') { return "Info" }
    
    return "Error"
}

function Get-UnityErrorCodeContext {
    param($ScriptPath, $LineNumber)
    
    try {
        # Try to read the file and extract context
        if (Test-Path $ScriptPath) {
            $fileContent = Get-Content $ScriptPath -ErrorAction Stop
            $startLine = [Math]::Max(1, $LineNumber - 3)
            $endLine = [Math]::Min($fileContent.Count, $LineNumber + 3)
            
            $contextLines = @()
            for ($i = $startLine - 1; $i -lt $endLine; $i++) {
                $lineNum = $i + 1
                $prefix = if ($lineNum -eq $LineNumber) { ">>> " } else { "    " }
                $contextLines += "$prefix$lineNum`: $($fileContent[$i])"
            }
            
            return $contextLines -join "`n"
        }
    } catch {
        Write-Debug "Failed to get code context: $_"
    }
    
    return $null
}

function Get-UnityErrorLabels {
    param($UnityError, $Config)
    
    $labels = @()
    $errorCode = $UnityError.Code
    $errorMessage = $UnityError.Message
    
    if (-not $errorCode -and $UnityError.ErrorText -match 'error\s+(\w+):') {
        $errorCode = $Matches[1]
    }
    
    # Get labels from configuration if available
    if ($Config.repositories -and $Config.global.defaultOwner -and $Config.global.defaultRepository) {
        $repoKey = "$($Config.global.defaultOwner)/$($Config.global.defaultRepository)"
        if ($Config.repositories.$repoKey -and $Config.repositories.$repoKey.labels.errorTypeMapping) {
            $mapping = $Config.repositories.$repoKey.labels.errorTypeMapping
            
            # Match error code patterns
            if ($errorCode -match '^CS\d+' -and $mapping.CS) {
                $labels += $mapping.CS
            } elseif ($errorMessage -match 'null reference' -and $mapping.NullReference) {
                $labels += $mapping.NullReference
            } elseif ($errorMessage -match 'missing component' -and $mapping.MissingComponent) {
                $labels += $mapping.MissingComponent
            }
        }
    }
    
    return $labels
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDqyB/wtjKISoH2
# 8lwFSiAitmOHoEe/ERoG6Sn8U8tfh6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFhi5kJCSTD5FpD9JFSvDiUY
# WQIX1+4za7IqDb4QnALSMA0GCSqGSIb3DQEBAQUABIIBAFX6fyoWtwjYj5BvGUUy
# B+dis8OwrMkGyAbU4KJrpu6FkpqxnvDeqys18T1de+O0xMjc7VTn7N6aH+50se/t
# t1Qni8z5HCoYQfL6kn/olEnzsQyVd45m8r0p6fCa3d/IG4gL1KTMX4x+n9CEcd+E
# rAeFqW05PawyPVNRk4mDB0fCTqTOhpOeYDHlPHkMCCQDY0FyvuQY8bm5qdbEUDqB
# IwBBl1vCduAvJw3RwfS7wDcqU9YfyJ/Q11Lf3KzD3l8kSu9AkSVsgfdkqTaXyUvW
# Yg5ZTM0TpeTkGa02lJ3F6qMTRsGaJU01XNohQ0tq4Qkkc46RQt/1gJoWaxmH255Y
# yFQ=
# SIG # End signature block
