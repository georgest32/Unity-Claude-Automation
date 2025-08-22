function Format-UnityErrorAsIssue {
    <#
    .SYNOPSIS
    Formats Unity compilation errors as GitHub issues
    
    .DESCRIPTION
    Converts Unity compilation error objects into formatted GitHub issue titles and bodies.
    Extracts error details, creates markdown-formatted content, and generates appropriate labels.
    
    .PARAMETER UnityError
    The Unity error object containing error details
    
    .PARAMETER IncludeContext
    Include surrounding code context in the issue body (default: true)
    
    .PARAMETER IncludeSystemInfo
    Include Unity version and system information (default: true)
    
    .EXAMPLE
    $error = Get-UnityErrors | Select-Object -First 1
    $issue = Format-UnityErrorAsIssue -UnityError $error
    New-GitHubIssue -Title $issue.Title -Body $issue.Body -Labels $issue.Labels
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$UnityError,
        
        [Parameter()]
        [bool]$IncludeContext = $true,
        
        [Parameter()]
        [bool]$IncludeSystemInfo = $true
    )
    
    begin {
        Write-Verbose "Starting Format-UnityErrorAsIssue"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Format-UnityErrorAsIssue: Processing Unity error for GitHub issue format"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    process {
        try {
            # Extract error components
            $errorType = "Compilation Error"
            $errorCode = ""
            $errorMessage = ""
            $scriptPath = ""
            $lineNumber = 0
            
            # Parse error text (typical format: "Assets/Scripts/File.cs(10,5): error CS0103: The name 'x' does not exist")
            if ($UnityError.ErrorText -match '^(.+?)\((\d+),(\d+)\):\s*error\s+(\w+):\s*(.+)$') {
                $scriptPath = $Matches[1]
                $lineNumber = [int]$Matches[2]
                $errorCode = $Matches[4]
                $errorMessage = $Matches[5]
            }
            elseif ($UnityError.Message) {
                $errorMessage = $UnityError.Message
                if ($UnityError.File) { $scriptPath = $UnityError.File }
                if ($UnityError.Line) { $lineNumber = $UnityError.Line }
                if ($UnityError.Code) { $errorCode = $UnityError.Code }
            }
            else {
                # Fallback to raw error text
                $errorMessage = $UnityError.ErrorText -replace '[\r\n]+', ' '
            }
            
            # Generate issue title (max 100 chars for readability)
            $title = if ($errorCode) {
                "Unity $errorCode`: $errorMessage"
            } else {
                "Unity Error: $errorMessage"
            }
            
            if ($title.Length -gt 100) {
                $title = $title.Substring(0, 97) + "..."
            }
            
            Write-Verbose "Generated title: $title"
            
            # Build issue body
            $bodyLines = @()
            $bodyLines += "## Unity Compilation Error"
            $bodyLines += ""
            
            # Error summary
            $bodyLines += "### Error Details"
            if ($errorCode) {
                $bodyLines += "- **Error Code**: ``$errorCode``"
            }
            $bodyLines += "- **Message**: $errorMessage"
            if ($scriptPath) {
                $bodyLines += "- **File**: ``$scriptPath``"
            }
            if ($lineNumber -gt 0) {
                $bodyLines += "- **Line**: $lineNumber"
            }
            $bodyLines += ""
            
            # Full error text in code block
            $bodyLines += "### Full Error Output"
            $bodyLines += "````"
            $bodyLines += $UnityError.ErrorText
            $bodyLines += "````"
            $bodyLines += ""
            
            # Include code context if available and requested
            if ($IncludeContext -and $scriptPath -and $lineNumber -gt 0) {
                $bodyLines += "### Code Context"
                
                # Try to read the file and show context
                $fullPath = if ($UnityError.FullPath) { 
                    $UnityError.FullPath 
                } else { 
                    # Attempt to construct full path
                    Join-Path (Get-Location) $scriptPath
                }
                
                if (Test-Path $fullPath -ErrorAction SilentlyContinue) {
                    try {
                        $fileContent = Get-Content $fullPath -ErrorAction Stop
                        $startLine = [Math]::Max(1, $lineNumber - 5)
                        $endLine = [Math]::Min($fileContent.Count, $lineNumber + 5)
                        
                        $bodyLines += "````csharp"
                        for ($i = $startLine - 1; $i -lt $endLine; $i++) {
                            $lineNum = $i + 1
                            $prefix = if ($lineNum -eq $lineNumber) { ">>> " } else { "    " }
                            $bodyLines += "$prefix$lineNum`: $($fileContent[$i])"
                        }
                        $bodyLines += "````"
                        $bodyLines += ""
                    }
                    catch {
                        Write-Warning "Could not read file context: $_"
                    }
                }
            }
            
            # Include system information if requested
            if ($IncludeSystemInfo) {
                $bodyLines += "### Environment"
                
                # Try to get Unity version
                $unityVersion = if ($UnityError.UnityVersion) {
                    $UnityError.UnityVersion
                } else {
                    # Try to extract from Editor.log if available
                    $editorLog = "C:\Users\$env:USERNAME\AppData\Local\Unity\Editor\Editor.log"
                    if (Test-Path $editorLog) {
                        $versionLine = Get-Content $editorLog -TotalCount 5 | Where-Object { $_ -match 'Unity\s+([\d\.]+)' }
                        if ($versionLine) {
                            $Matches[1]
                        } else {
                            "Unknown"
                        }
                    } else {
                        "Unknown"
                    }
                }
                
                $bodyLines += "- **Unity Version**: $unityVersion"
                $bodyLines += "- **Platform**: Windows"
                $bodyLines += "- **Timestamp**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                
                if ($UnityError.Project) {
                    $bodyLines += "- **Project**: $($UnityError.Project)"
                }
                $bodyLines += ""
            }
            
            # Add metadata for tracking
            $bodyLines += "### Metadata"
            $bodyLines += "<!-- Unity-Claude-Automation Generated Issue -->"
            $bodyLines += "<!-- Error-Hash: $(Get-UnityErrorSignature -UnityError $UnityError) -->"
            $bodyLines += ""
            
            # Determine labels based on error type
            $labels = @("unity", "compilation-error", "automated")
            
            if ($errorCode) {
                # Add label based on error code prefix
                switch -Regex ($errorCode) {
                    '^CS\d+' { $labels += "csharp" }
                    '^BCE\d+' { $labels += "boo" }
                    '^US\d+' { $labels += "unityscript" }
                    'NullReference' { $labels += "null-reference" }
                    'Missing' { $labels += "missing-component" }
                }
            }
            
            # Add severity label based on error patterns
            if ($errorMessage -match 'does not exist|cannot find|missing') {
                $labels += "missing-reference"
            }
            elseif ($errorMessage -match 'ambiguous|conflict') {
                $labels += "naming-conflict"
            }
            elseif ($errorMessage -match 'obsolete|deprecated') {
                $labels += "deprecation"
            }
            
            # Build the result object
            $result = [PSCustomObject]@{
                Title = $title
                Body = $bodyLines -join "`n"
                Labels = $labels
                ErrorCode = $errorCode
                ScriptPath = $scriptPath
                LineNumber = $lineNumber
                Signature = Get-UnityErrorSignature -UnityError $UnityError
            }
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [SUCCESS] Format-UnityErrorAsIssue: Formatted error as issue - Title: $title"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully formatted Unity error as GitHub issue"
            return $result
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Format-UnityErrorAsIssue: Failed to format - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to format Unity error as issue: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Format-UnityErrorAsIssue"
    }
}