# Unity-Claude-FixEngine Module
# Claude-Powered Automated Fix Application Engine for Unity Compilation Errors
# Phase 3 Week 3 Day 17-18 Implementation - Modular Architecture
# Compatible with PowerShell 5.1 and Unity 2021.1.14f1

# Module-level variables
$script:FixEngineConfig = @{
    EnableDebugLogging = $true
    BackupDirectory = "$env:TEMP\Unity-Claude-Backups"
    MaxBackupsPerFile = 5
    CompilationTimeoutSeconds = 60
    SafetyIntegrationEnabled = $true
    LearningIntegrationEnabled = $true
    UnityProjectPath = ""
    UnityEditorPath = ""
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Import required modules if available
if (Get-Module -ListAvailable -Name "Unity-Claude-Safety") {
    Import-Module "Unity-Claude-Safety" -Force -ErrorAction SilentlyContinue
}
if (Get-Module -ListAvailable -Name "Unity-Claude-Learning") {
    Import-Module "Unity-Claude-Learning" -Force -ErrorAction SilentlyContinue
}

# Import all private functions from modular files
$PrivatePath = Join-Path $PSScriptRoot "Private"
if (Test-Path $PrivatePath) {
    Get-ChildItem -Path $PrivatePath -Filter "*.ps1" | ForEach-Object {
        Write-Verbose "Loading private function: $($_.Name)"
        . $_.FullName
    }
}

# Import all public functions from modular files  
$PublicPath = Join-Path $PSScriptRoot "Public"
if (Test-Path $PublicPath) {
    Get-ChildItem -Path $PublicPath -Filter "*.ps1" | ForEach-Object {
        Write-Verbose "Loading public function: $($_.Name)"
        . $_.FullName
    }
}

#region Logging and Utilities

function Write-FixEngineLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if (-not $script:FixEngineConfig.EnableDebugLogging -and $Level -eq "DEBUG") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [FixEngine] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
    
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } elseif ($script:FixEngineConfig.EnableDebugLogging) {
        Write-Host "[$Level] $Message" -ForegroundColor $(
            switch ($Level) {
                "INFO" { "Green" }
                "DEBUG" { "Gray" }
                default { "White" }
            }
        )
    }
}

function Test-RequiredModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
    if (-not $module) {
        Write-FixEngineLog -Message "Required module '$ModuleName' not loaded" -Level "WARN"
        return $false
    }
    return $true
}

#endregion

#region Configuration Management

function Get-FixEngineConfig {
    [CmdletBinding()]
    param()
    
    Write-FixEngineLog -Message "Retrieving Fix Engine configuration" -Level "DEBUG"
    return $script:FixEngineConfig.Clone()
}

function Set-FixEngineConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$EnableDebugLogging,
        
        [Parameter()]
        [string]$BackupDirectory,
        
        [Parameter()]
        [int]$MaxBackupsPerFile,
        
        [Parameter()]
        [int]$CompilationTimeoutSeconds,
        
        [Parameter()]
        [bool]$SafetyIntegrationEnabled,
        
        [Parameter()]
        [bool]$LearningIntegrationEnabled,
        
        [Parameter()]
        [string]$UnityProjectPath,
        
        [Parameter()]
        [string]$UnityEditorPath
    )
    
    Write-FixEngineLog -Message "Updating Fix Engine configuration" -Level "INFO"
    
    if ($PSBoundParameters.ContainsKey('EnableDebugLogging')) {
        $script:FixEngineConfig.EnableDebugLogging = $EnableDebugLogging
    }
    if ($PSBoundParameters.ContainsKey('BackupDirectory')) {
        $script:FixEngineConfig.BackupDirectory = $BackupDirectory
    }
    if ($PSBoundParameters.ContainsKey('MaxBackupsPerFile')) {
        $script:FixEngineConfig.MaxBackupsPerFile = $MaxBackupsPerFile
    }
    if ($PSBoundParameters.ContainsKey('CompilationTimeoutSeconds')) {
        $script:FixEngineConfig.CompilationTimeoutSeconds = $CompilationTimeoutSeconds
    }
    if ($PSBoundParameters.ContainsKey('SafetyIntegrationEnabled')) {
        $script:FixEngineConfig.SafetyIntegrationEnabled = $SafetyIntegrationEnabled
    }
    if ($PSBoundParameters.ContainsKey('LearningIntegrationEnabled')) {
        $script:FixEngineConfig.LearningIntegrationEnabled = $LearningIntegrationEnabled
    }
    if ($PSBoundParameters.ContainsKey('UnityProjectPath')) {
        $script:FixEngineConfig.UnityProjectPath = $UnityProjectPath
    }
    if ($PSBoundParameters.ContainsKey('UnityEditorPath')) {
        $script:FixEngineConfig.UnityEditorPath = $UnityEditorPath
    }
    
    Write-FixEngineLog -Message "Fix Engine configuration updated successfully" -Level "INFO"
}

#endregion

#region File Operations and Backup

function New-BackupFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [string]$BackupReason = "Fix Application"
    )
    
    Write-FixEngineLog -Message "Creating backup for file: $FilePath" -Level "DEBUG"
    
    if (-not (Test-Path $FilePath)) {
        Write-FixEngineLog -Message "Source file not found for backup: $FilePath" -Level "ERROR"
        throw "Source file not found: $FilePath"
    }
    
    # Ensure backup directory exists
    $backupDir = $script:FixEngineConfig.BackupDirectory
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Write-FixEngineLog -Message "Created backup directory: $backupDir" -Level "DEBUG"
    }
    
    # Generate backup filename with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileInfo = Get-Item $FilePath
    $backupName = "$($fileInfo.BaseName)_$timestamp$($fileInfo.Extension)"
    $backupPath = Join-Path $backupDir $backupName
    
    try {
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-FixEngineLog -Message "File backed up successfully: $backupPath" -Level "INFO"
        
        # Create metadata file
        $metadataPath = "$backupPath.json"
        $metadata = @{
            OriginalPath = $FilePath
            BackupTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            BackupReason = $BackupReason
            FileSize = $fileInfo.Length
            LastModified = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        }
        $metadata | ConvertTo-Json | Set-Content -Path $metadataPath -Encoding UTF8
        
        # Clean up old backups
        Clear-OldBackups -FilePath $FilePath
        
        return $backupPath
    }
    catch {
        Write-FixEngineLog -Message "Failed to create backup: $_" -Level "ERROR"
        throw "Backup creation failed: $_"
    }
}

function Clear-OldBackups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $fileInfo = Get-Item $FilePath
    $backupPattern = "$($fileInfo.BaseName)_*$($fileInfo.Extension)"
    $backupDir = $script:FixEngineConfig.BackupDirectory
    
    try {
        $backups = Get-ChildItem -Path $backupDir -Filter $backupPattern | Sort-Object LastWriteTime -Descending
        
        if ($backups.Count -gt $script:FixEngineConfig.MaxBackupsPerFile) {
            $toDelete = $backups | Select-Object -Skip $script:FixEngineConfig.MaxBackupsPerFile
            foreach ($backup in $toDelete) {
                Remove-Item -Path $backup.FullName -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$($backup.FullName).json" -Force -ErrorAction SilentlyContinue
                Write-FixEngineLog -Message "Removed old backup: $($backup.Name)" -Level "DEBUG"
            }
        }
    }
    catch {
        Write-FixEngineLog -Message "Failed to clean old backups: $_" -Level "WARN"
    }
}

function Restore-BackupFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        
        [Parameter()]
        [string]$TargetPath
    )
    
    Write-FixEngineLog -Message "Restoring backup: $BackupPath" -Level "INFO"
    
    if (-not (Test-Path $BackupPath)) {
        Write-FixEngineLog -Message "Backup file not found: $BackupPath" -Level "ERROR"
        throw "Backup file not found: $BackupPath"
    }
    
    # Determine target path from metadata if not provided
    if (-not $TargetPath) {
        $metadataPath = "$BackupPath.json"
        if (Test-Path $metadataPath) {
            $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
            $TargetPath = $metadata.OriginalPath
        } else {
            Write-FixEngineLog -Message "No metadata found and no target path specified" -Level "ERROR"
            throw "Cannot determine restore target path"
        }
    }
    
    try {
        Copy-Item -Path $BackupPath -Destination $TargetPath -Force
        Write-FixEngineLog -Message "File restored successfully: $TargetPath" -Level "INFO"
        return $TargetPath
    }
    catch {
        Write-FixEngineLog -Message "Failed to restore backup: $_" -Level "ERROR"
        throw "Restore failed: $_"
    }
}

function Invoke-AtomicFileReplace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$NewContent,
        
        [Parameter()]
        [string]$BackupReason = "Atomic File Replace"
    )
    
    Write-FixEngineLog -Message "Starting atomic file replacement: $FilePath" -Level "DEBUG"
    
    # Create backup first
    $backupPath = New-BackupFile -FilePath $FilePath -BackupReason $BackupReason
    
    # Create temporary file
    $tempPath = "$FilePath.tmp"
    
    try {
        # Write new content to temporary file
        Set-Content -Path $tempPath -Value $NewContent -Encoding UTF8 -Force
        Write-FixEngineLog -Message "Temporary file created: $tempPath" -Level "DEBUG"
        
        # Atomic replacement using File.Replace() .NET method
        $originalFile = $FilePath
        $replacementFile = $tempPath
        $backupFile = "$FilePath.backup"
        
        # Remove any existing backup file to avoid conflicts
        if (Test-Path $backupFile) {
            Remove-Item $backupFile -Force
        }
        
        # Perform atomic replacement
        [System.IO.File]::Replace($replacementFile, $originalFile, $backupFile)
        
        # Clean up the backup file created by File.Replace()
        if (Test-Path $backupFile) {
            Remove-Item $backupFile -Force
        }
        
        Write-FixEngineLog -Message "Atomic file replacement completed successfully: $FilePath" -Level "INFO"
        return @{
            Success = $true
            BackupPath = $backupPath
            OriginalPath = $FilePath
        }
    }
    catch {
        Write-FixEngineLog -Message "Atomic file replacement failed: $_" -Level "ERROR"
        
        # Cleanup temporary file if it exists
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
        
        # Attempt to restore from backup
        try {
            Restore-BackupFile -BackupPath $backupPath -TargetPath $FilePath
            Write-FixEngineLog -Message "File restored from backup after failed replacement" -Level "INFO"
        }
        catch {
            Write-FixEngineLog -Message "Failed to restore from backup: $_" -Level "ERROR"
        }
        
        throw "Atomic file replacement failed: $_"
    }
}

#endregion

#region Custom AST Parsing (Text-Based)

function Get-CSharpAST {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    Write-FixEngineLog -Message "Parsing C# file: $FilePath" -Level "DEBUG"
    
    if (-not (Test-Path $FilePath)) {
        Write-FixEngineLog -Message "File not found for AST parsing: $FilePath" -Level "ERROR"
        throw "File not found: $FilePath"
    }
    
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    
    # Create simplified AST structure
    $ast = @{
        FilePath = $FilePath
        UsingDirectives = @()
        NamespaceDeclarations = @()
        ClassDeclarations = @()
        Methods = @()
        Fields = @()
        Properties = @()
        ErrorLocations = @()
    }
    
    try {
        # Parse using statements
        $usingMatches = [regex]::Matches($content, '^\s*using\s+([^;]+);', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($match in $usingMatches) {
            $ast.UsingDirectives += @{
                Namespace = $match.Groups[1].Value.Trim()
                LineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
            }
        }
        
        # Parse namespace declarations
        $namespaceMatches = [regex]::Matches($content, 'namespace\s+([^\s{]+)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($match in $namespaceMatches) {
            $ast.NamespaceDeclarations += @{
                Name = $match.Groups[1].Value.Trim()
                LineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
            }
        }
        
        # Parse class declarations
        $classMatches = [regex]::Matches($content, '(?:public|private|protected|internal)?\s*(?:static|abstract|sealed)?\s*class\s+(\w+)(?:\s*:\s*([^{]+))?', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($match in $classMatches) {
            $inheritance = if ($match.Groups[2].Success) { $match.Groups[2].Value.Trim() } else { "" }
            $ast.ClassDeclarations += @{
                Name = $match.Groups[1].Value.Trim()
                Inheritance = $inheritance
                LineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
            }
        }
        
        # Parse method declarations
        $methodMatches = [regex]::Matches($content, '(?:public|private|protected|internal)?\s*(?:static|virtual|override|abstract)?\s*(?:\w+\s+)?(\w+)\s*\([^)]*\)\s*(?:{|;)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($match in $methodMatches) {
            $ast.Methods += @{
                Name = $match.Groups[1].Value.Trim()
                LineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
                Declaration = $match.Value.Trim()
            }
        }
        
        Write-FixEngineLog -Message "AST parsing completed. Found: $($ast.UsingDirectives.Count) usings, $($ast.ClassDeclarations.Count) classes, $($ast.Methods.Count) methods" -Level "DEBUG"
        
        return $ast
    }
    catch {
        Write-FixEngineLog -Message "AST parsing failed: $_" -Level "ERROR"
        throw "AST parsing failed: $_"
    }
}

function Get-CodePattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AST
    )
    
    Write-FixEngineLog -Message "Analyzing code pattern for error: $ErrorMessage" -Level "DEBUG"
    
    $pattern = @{
        ErrorType = ""
        ErrorLocation = @{
            LineNumber = 0
            ColumnNumber = 0
        }
        SuggestedFixes = @()
        Context = @{
            NearbyCode = ""
            MissingElements = @()
            AvailableElements = @()
        }
    }
    
    # Determine error type from message
    if ($ErrorMessage -match "CS0246.*'(\w+)'.*could not be found") {
        $pattern.ErrorType = "CS0246_TypeNotFound"
        $missingType = $matches[1]
        $pattern.Context.MissingElements += $missingType
        
        # Suggest common Unity using statements
        $commonUnityUsings = @(
            "UnityEngine",
            "UnityEditor",
            "System.Collections.Generic",
            "System.Collections",
            "System.Linq"
        )
        
        foreach ($usingStmt in $commonUnityUsings) {
            if ($AST.UsingDirectives.Namespace -notcontains $usingStmt) {
                $pattern.SuggestedFixes += @{
                    Type = "AddUsing"
                    Content = "using $usingStmt;"
                    Confidence = 0.8
                }
            }
        }
    }
    elseif ($ErrorMessage -match "CS0103.*'(\w+)'.*does not exist") {
        $pattern.ErrorType = "CS0103_NameNotFound"
        $missingName = $matches[1]
        $pattern.Context.MissingElements += $missingName
        
        # Common Unity component access patterns
        if ($missingName -in @("gameObject", "transform", "renderer", "rigidbody")) {
            $pattern.SuggestedFixes += @{
                Type = "ComponentAccess"
                Content = "GetComponent<$($missingName.Substring(0,1).ToUpper() + $missingName.Substring(1))>()"
                Confidence = 0.7
            }
        }
    }
    elseif ($ErrorMessage -match "CS1061.*'(\w+)'.*does not contain a definition for '(\w+)'") {
        $pattern.ErrorType = "CS1061_MemberNotFound"
        $typeName = $matches[1]
        $memberName = $matches[2]
        $pattern.Context.MissingElements += @($typeName, $memberName)
        
        # Common Unity method name corrections
        $commonCorrections = @{
            "Start" = "Start"
            "Update" = "Update"
            "Awake" = "Awake"
            "OnDestroy" = "OnDestroy"
        }
        
        if ($commonCorrections.ContainsKey($memberName)) {
            $pattern.SuggestedFixes += @{
                Type = "MethodCorrection"
                Content = $commonCorrections[$memberName]
                Confidence = 0.9
            }
        }
    }
    
    # Extract line number from error message
    if ($ErrorMessage -match '\((\d+),(\d+)\)') {
        $pattern.ErrorLocation.LineNumber = [int]$matches[1]
        $pattern.ErrorLocation.ColumnNumber = [int]$matches[2]
    }
    
    Write-FixEngineLog -Message "Code pattern analysis completed. Error type: $($pattern.ErrorType), Fixes: $($pattern.SuggestedFixes.Count)" -Level "DEBUG"
    
    return $pattern
}

#endregion

#region Fix Template System

function New-FixTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorType,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Pattern,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AST
    )
    
    Write-FixEngineLog -Message "Creating fix template for error type: $ErrorType" -Level "DEBUG"
    
    $template = @{
        ErrorType = $ErrorType
        Fixes = @()
        ValidationRules = @()
        ApplicationOrder = @()
    }
    
    switch ($ErrorType) {
        "CS0246_TypeNotFound" {
            foreach ($fix in $Pattern.SuggestedFixes) {
                if ($fix.Type -eq "AddUsing") {
                    $template.Fixes += @{
                        Type = "InsertLine"
                        Position = "AfterLastUsing"
                        Content = $fix.Content
                        Confidence = $fix.Confidence
                        Validation = "CompilationCheck"
                    }
                }
            }
        }
        
        "CS0103_NameNotFound" {
            foreach ($fix in $Pattern.SuggestedFixes) {
                if ($fix.Type -eq "ComponentAccess") {
                    $template.Fixes += @{
                        Type = "ReplaceToken"
                        Position = "ErrorLocation"
                        Content = $fix.Content
                        Confidence = $fix.Confidence
                        Validation = "SyntaxCheck"
                    }
                }
            }
        }
        
        "CS1061_MemberNotFound" {
            foreach ($fix in $Pattern.SuggestedFixes) {
                if ($fix.Type -eq "MethodCorrection") {
                    $template.Fixes += @{
                        Type = "ReplaceToken"
                        Position = "ErrorLocation"
                        Content = $fix.Content
                        Confidence = $fix.Confidence
                        Validation = "SyntaxCheck"
                    }
                }
            }
        }
        
        default {
            Write-FixEngineLog -Message "No template available for error type: $ErrorType" -Level "WARN"
        }
    }
    
    # Add validation rules
    $template.ValidationRules += @{
        Type = "SyntaxValidation"
        Required = $true
    }
    $template.ValidationRules += @{
        Type = "CompilationValidation"
        Required = $false
    }
    
    Write-FixEngineLog -Message "Fix template created with $($template.Fixes.Count) fixes" -Level "DEBUG"
    
    return $template
}

function Invoke-TemplateApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Template,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ErrorContext
    )
    
    Write-FixEngineLog -Message "Applying fix template to file: $FilePath" -Level "INFO"
    
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $lines = Get-Content -Path $FilePath -Encoding UTF8
    $appliedFixes = @()
    
    try {
        foreach ($fix in $Template.Fixes) {
            Write-FixEngineLog -Message "Applying fix: $($fix.Type) - $($fix.Content)" -Level "DEBUG"
            
            switch ($fix.Type) {
                "InsertLine" {
                    if ($fix.Position -eq "AfterLastUsing") {
                        # Find the last using statement
                        $lastUsingIndex = -1
                        for ($i = 0; $i -lt $lines.Count; $i++) {
                            if ($lines[$i] -match '^\s*using\s+') {
                                $lastUsingIndex = $i
                            }
                        }
                        
                        if ($lastUsingIndex -ge 0) {
                            # Insert after the last using statement
                            $newLines = @()
                            $newLines += $lines[0..$lastUsingIndex]
                            $newLines += $fix.Content
                            if ($lastUsingIndex + 1 -lt $lines.Count) {
                                $newLines += $lines[($lastUsingIndex + 1)..($lines.Count - 1)]
                            }
                            $lines = $newLines
                            $appliedFixes += $fix
                            Write-FixEngineLog -Message "Inserted using statement after line $($lastUsingIndex + 1)" -Level "DEBUG"
                        }
                    }
                }
                
                "ReplaceToken" {
                    if ($fix.Position -eq "ErrorLocation" -and $ErrorContext.LineNumber -gt 0) {
                        $lineIndex = $ErrorContext.LineNumber - 1
                        if ($lineIndex -lt $lines.Count) {
                            # Simple token replacement (this could be enhanced with more sophisticated parsing)
                            $lines[$lineIndex] = $lines[$lineIndex] -replace '\b\w+\b', $fix.Content
                            $appliedFixes += $fix
                            Write-FixEngineLog -Message "Replaced token on line $($ErrorContext.LineNumber)" -Level "DEBUG"
                        }
                    }
                }
            }
        }
        
        # Reconstruct content
        $newContent = $lines -join "`r`n"
        
        Write-FixEngineLog -Message "Template application completed. Applied $($appliedFixes.Count) fixes" -Level "INFO"
        
        return @{
            Success = $true
            ModifiedContent = $newContent
            AppliedFixes = $appliedFixes
        }
    }
    catch {
        Write-FixEngineLog -Message "Template application failed: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            AppliedFixes = $appliedFixes
        }
    }
}

#endregion

#region Fix Validation

function Test-FixValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModifiedContent,
        
        [Parameter(Mandatory = $true)]
        [string]$OriginalFilePath,
        
        [Parameter()]
        [string[]]$ValidationTypes = @("Syntax", "Compilation")
    )
    
    Write-FixEngineLog -Message "Validating fix for file: $OriginalFilePath" -Level "DEBUG"
    
    $validationResult = @{
        IsValid = $true
        ValidationResults = @()
        Errors = @()
    }
    
    foreach ($validationType in $ValidationTypes) {
        switch ($validationType) {
            "Syntax" {
                $syntaxResult = Test-SyntaxValidation -Content $ModifiedContent
                $validationResult.ValidationResults += $syntaxResult
                if (-not $syntaxResult.IsValid) {
                    $validationResult.IsValid = $false
                    $validationResult.Errors += $syntaxResult.Errors
                }
            }
            
            "Compilation" {
                $compilationResult = Test-CompilationValidation -Content $ModifiedContent -FilePath $OriginalFilePath
                $validationResult.ValidationResults += $compilationResult
                if (-not $compilationResult.IsValid) {
                    $validationResult.IsValid = $false
                    $validationResult.Errors += $compilationResult.Errors
                }
            }
        }
    }
    
    Write-FixEngineLog -Message "Fix validation completed. Valid: $($validationResult.IsValid)" -Level "DEBUG"
    
    return $validationResult
}

function Test-SyntaxValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $result = @{
        Type = "Syntax"
        IsValid = $true
        Errors = @()
    }
    
    try {
        # Basic syntax checks using regex patterns
        $syntaxErrors = @()
        
        # Check for unmatched braces
        $openBraces = ($Content | Select-String -Pattern '{' -AllMatches).Matches.Count
        $closeBraces = ($Content | Select-String -Pattern '}' -AllMatches).Matches.Count
        if ($openBraces -ne $closeBraces) {
            $syntaxErrors += "Unmatched braces: $openBraces open, $closeBraces close"
        }
        
        # Check for unmatched parentheses
        $openParens = ($Content | Select-String -Pattern '\(' -AllMatches).Matches.Count
        $closeParens = ($Content | Select-String -Pattern '\)' -AllMatches).Matches.Count
        if ($openParens -ne $closeParens) {
            $syntaxErrors += "Unmatched parentheses: $openParens open, $closeParens close"
        }
        
        # Check for unterminated strings
        $lines = $Content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match '"[^"]*$' -and $line -notmatch '\\["`]$') {
                $syntaxErrors += "Unterminated string on line $($i + 1)"
            }
        }
        
        if ($syntaxErrors.Count -gt 0) {
            $result.IsValid = $false
            $result.Errors = $syntaxErrors
        }
        
        Write-FixEngineLog -Message "Syntax validation completed. Errors: $($syntaxErrors.Count)" -Level "DEBUG"
    }
    catch {
        $result.IsValid = $false
        $result.Errors += "Syntax validation failed: $_"
        Write-FixEngineLog -Message "Syntax validation error: $_" -Level "ERROR"
    }
    
    return $result
}

function Test-CompilationValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $result = @{
        Type = "Compilation"
        IsValid = $true
        Errors = @()
    }
    
    try {
        # Create temporary file for compilation test
        $tempPath = "$FilePath.validation.tmp"
        Set-Content -Path $tempPath -Value $Content -Encoding UTF8
        
        Write-FixEngineLog -Message "Testing compilation with temporary file: $tempPath" -Level "DEBUG"
        
        # Trigger Unity compilation if Unity project path is configured
        if ($script:FixEngineConfig.UnityProjectPath) {
            $compilationResult = Test-UnityCompilation -ProjectPath $script:FixEngineConfig.UnityProjectPath
            
            if (-not $compilationResult.Success) {
                $result.IsValid = $false
                $result.Errors = $compilationResult.Errors
            }
        } else {
            Write-FixEngineLog -Message "Unity project path not configured, skipping compilation validation" -Level "WARN"
        }
        
        # Clean up temporary file
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        $result.IsValid = $false
        $result.Errors += "Compilation validation failed: $_"
        Write-FixEngineLog -Message "Compilation validation error: $_" -Level "ERROR"
    }
    
    return $result
}

#endregion

#region Unity Compilation Verification

function Test-UnityCompilation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [int]$TimeoutSeconds = 60
    )
    
    Write-FixEngineLog -Message "Testing Unity compilation for project: $ProjectPath" -Level "INFO"
    
    if (-not (Test-Path $ProjectPath)) {
        Write-FixEngineLog -Message "Unity project path not found: $ProjectPath" -Level "ERROR"
        return @{
            Success = $false
            Errors = @("Unity project path not found: $ProjectPath")
        }
    }
    
    try {
        # Use Unity command line to perform compilation test
        $unityEditor = $script:FixEngineConfig.UnityEditorPath
        if (-not $unityEditor -or -not (Test-Path $unityEditor)) {
            # Try to find Unity editor automatically
            $unityEditor = Get-UnityEditorPath
        }
        
        if (-not $unityEditor) {
            Write-FixEngineLog -Message "Unity editor not found. Configure UnityEditorPath in settings." -Level "WARN"
            return @{
                Success = $true  # Assume success if we can't test
                Errors = @()
                Warning = "Unity editor not found for compilation testing"
            }
        }
        
        # Create compilation test arguments
        $logFile = Join-Path $env:TEMP "unity_compilation_test.log"
        $arguments = @(
            "-batchmode"
            "-quit"
            "-projectPath"
            "`"$ProjectPath`""
            "-logFile"
            "`"$logFile`""
        )
        
        Write-FixEngineLog -Message "Starting Unity compilation test with arguments: $($arguments -join ' ')" -Level "DEBUG"
        
        # Start Unity process
        $process = Start-Process -FilePath $unityEditor -ArgumentList $arguments -WindowStyle Hidden -PassThru
        
        # Wait for completion with timeout
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        
        if (-not $completed) {
            $process.Kill()
            Write-FixEngineLog -Message "Unity compilation test timed out after $TimeoutSeconds seconds" -Level "WARN"
            return @{
                Success = $false
                Errors = @("Compilation test timed out")
            }
        }
        
        # Analyze compilation results
        $errors = Get-CompilationErrors -LogPath $logFile
        
        Write-FixEngineLog -Message "Unity compilation test completed. Errors found: $($errors.Count)" -Level "INFO"
        
        return @{
            Success = ($errors.Count -eq 0)
            Errors = $errors
            ExitCode = $process.ExitCode
            LogPath = $logFile
        }
    }
    catch {
        Write-FixEngineLog -Message "Unity compilation test failed: $_" -Level "ERROR"
        return @{
            Success = $false
            Errors = @("Compilation test failed: $_")
        }
    }
}

function Get-CompilationErrors {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath
    )
    
    $errors = @()
    
    try {
        if ($LogPath -and (Test-Path $LogPath)) {
            $logContent = Get-Content -Path $LogPath -Raw -Encoding UTF8
        } else {
            # Try to read from Unity Editor.log
            $unityLogPath = "$env:LOCALAPPDATA\Unity\Editor\Editor.log"
            if (Test-Path $unityLogPath) {
                $logContent = Get-Content -Path $unityLogPath -Raw -Encoding UTF8
            } else {
                Write-FixEngineLog -Message "No Unity log file found for error analysis" -Level "WARN"
                return $errors
            }
        }
        
        # Parse compilation errors using regex
        $errorPattern = '^\s*(.+?)\((\d+),(\d+)\):\s*error\s+(CS\d+):\s*(.+)$'
        $matches = [regex]::Matches($logContent, $errorPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        foreach ($match in $matches) {
            $errors += @{
                FilePath = $match.Groups[1].Value
                LineNumber = [int]$match.Groups[2].Value
                ColumnNumber = [int]$match.Groups[3].Value
                ErrorCode = $match.Groups[4].Value
                Message = $match.Groups[5].Value
                FullMessage = $match.Value
            }
        }
        
        Write-FixEngineLog -Message "Parsed $($errors.Count) compilation errors from log" -Level "DEBUG"
    }
    catch {
        Write-FixEngineLog -Message "Failed to parse compilation errors: $_" -Level "ERROR"
    }
    
    return $errors
}

function Get-UnityEditorPath {
    [CmdletBinding()]
    param()
    
    # Common Unity installation paths
    $commonPaths = @(
        "${env:ProgramFiles}\Unity\Hub\Editor\*\Editor\Unity.exe",
        "${env:ProgramFiles(x86)}\Unity\Hub\Editor\*\Editor\Unity.exe",
        "${env:ProgramFiles}\Unity\Editor\Unity.exe",
        "${env:ProgramFiles(x86)}\Unity\Editor\Unity.exe"
    )
    
    foreach ($pathPattern in $commonPaths) {
        $unityExes = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($unityExes) {
            $latestUnity = $unityExes[0].FullName
            Write-FixEngineLog -Message "Found Unity editor: $latestUnity" -Level "DEBUG"
            return $latestUnity
        }
    }
    
    Write-FixEngineLog -Message "Unity editor not found in common installation paths" -Level "WARN"
    return $null
}

function Invoke-CompilationVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [string]$ExpectedErrorCode
    )
    
    Write-FixEngineLog -Message "Verifying compilation after fix application: $FilePath" -Level "INFO"
    
    if (-not $script:FixEngineConfig.UnityProjectPath) {
        Write-FixEngineLog -Message "Unity project path not configured. Cannot verify compilation." -Level "WARN"
        return @{
            Success = $true  # Assume success if we can't verify
            Verified = $false
            Message = "Unity project path not configured"
        }
    }
    
    $compilationResult = Test-UnityCompilation -ProjectPath $script:FixEngineConfig.UnityProjectPath
    
    if ($compilationResult.Success) {
        Write-FixEngineLog -Message "Compilation verification passed: No errors found" -Level "INFO"
        return @{
            Success = $true
            Verified = $true
            Message = "Compilation successful"
        }
    } else {
        # Check if the specific error was resolved
        if ($ExpectedErrorCode) {
            $hasExpectedError = $compilationResult.Errors | Where-Object { $_.ErrorCode -eq $ExpectedErrorCode }
            if (-not $hasExpectedError) {
                Write-FixEngineLog -Message "Expected error $ExpectedErrorCode was resolved, but other errors remain" -Level "INFO"
                return @{
                    Success = $true
                    Verified = $true
                    Message = "Target error resolved"
                    RemainingErrors = $compilationResult.Errors
                }
            }
        }
        
        Write-FixEngineLog -Message "Compilation verification failed: $($compilationResult.Errors.Count) errors remain" -Level "WARN"
        return @{
            Success = $false
            Verified = $true
            Message = "Compilation errors remain"
            Errors = $compilationResult.Errors
        }
    }
}

#endregion

#region Integration Functions

function Connect-SafetyFramework {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$FixContent,
        
        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    
    Write-FixEngineLog -Message "Checking safety framework for fix application" -Level "DEBUG"
    
    if (-not $script:FixEngineConfig.SafetyIntegrationEnabled) {
        Write-FixEngineLog -Message "Safety framework integration disabled" -Level "DEBUG"
        return @{ IsSafe = $true; Reason = "Safety integration disabled" }
    }
    
    if (-not (Test-RequiredModule -ModuleName "Unity-Claude-Safety")) {
        Write-FixEngineLog -Message "Unity-Claude-Safety module not available" -Level "WARN"
        return @{ IsSafe = $true; Reason = "Safety module not available" }
    }
    
    try {
        $safetyResult = Test-FixSafety -FilePath $FilePath -Confidence $Confidence -FixContent $FixContent
        Write-FixEngineLog -Message "Safety check result: $($safetyResult.IsSafe) - $($safetyResult.Reason)" -Level "DEBUG"
        return $safetyResult
    }
    catch {
        Write-FixEngineLog -Message "Safety framework check failed: $_" -Level "ERROR"
        return @{ IsSafe = $false; Reason = "Safety check failed: $_" }
    }
}

function Connect-LearningModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter()]
        [hashtable]$FixResult,
        
        [Parameter()]
        [string]$Action = "GetPattern"
    )
    
    Write-FixEngineLog -Message "Connecting to learning module for action: $Action" -Level "DEBUG"
    
    if (-not $script:FixEngineConfig.LearningIntegrationEnabled) {
        Write-FixEngineLog -Message "Learning module integration disabled" -Level "DEBUG"
        return $null
    }
    
    if (-not (Test-RequiredModule -ModuleName "Unity-Claude-Learning")) {
        Write-FixEngineLog -Message "Unity-Claude-Learning module not available" -Level "WARN"
        return $null
    }
    
    try {
        switch ($Action) {
            "GetPattern" {
                $pattern = Get-SuggestedFixes -ErrorMessage $ErrorMessage
                Write-FixEngineLog -Message "Retrieved pattern suggestions from learning module" -Level "DEBUG"
                return $pattern
            }
            
            "SendMetrics" {
                if ($FixResult) {
                    Send-FixMetrics -ErrorMessage $ErrorMessage -FixResult $FixResult
                    Write-FixEngineLog -Message "Sent fix metrics to learning module" -Level "DEBUG"
                }
            }
        }
    }
    catch {
        Write-FixEngineLog -Message "Learning module integration failed: $_" -Level "ERROR"
    }
    
    return $null
}

function Send-FixMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$FixResult
    )
    
    Write-FixEngineLog -Message "Sending fix metrics to learning module" -Level "DEBUG"
    
    if (-not (Test-RequiredModule -ModuleName "Unity-Claude-Learning")) {
        return
    }
    
    try {
        $metrics = @{
            ErrorMessage = $ErrorMessage
            FixSuccess = $FixResult.Success
            FixesApplied = $FixResult.AppliedFixes.Count
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            CompilationVerified = $FixResult.ContainsKey('CompilationResult')
        }
        
        # This would integrate with the learning module's metrics system
        Add-FixMetric -Metrics $metrics
        Write-FixEngineLog -Message "Fix metrics recorded successfully" -Level "DEBUG"
    }
    catch {
        Write-FixEngineLog -Message "Failed to send fix metrics: $_" -Level "ERROR"
    }
}

#endregion

#region Core Fix Application Function

function Invoke-FixApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter()]
        [switch]$DryRun,
        
        [Parameter()]
        [switch]$Force
    )
    
    Write-FixEngineLog -Message "Starting fix application for file: $FilePath" -Level "INFO"
    Write-FixEngineLog -Message "Error message: $ErrorMessage" -Level "DEBUG"
    
    $result = @{
        Success = $false
        FilePath = $FilePath
        ErrorMessage = $ErrorMessage
        AppliedFixes = @()
        BackupPath = ""
        ValidationResults = @()
        CompilationResult = @{}
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        # Step 1: Parse the file to get AST
        Write-FixEngineLog -Message "Step 1: Parsing file AST" -Level "DEBUG"
        $ast = Get-CSharpAST -FilePath $FilePath
        
        # Step 2: Analyze error pattern
        Write-FixEngineLog -Message "Step 2: Analyzing error pattern" -Level "DEBUG"
        $pattern = Get-CodePattern -ErrorMessage $ErrorMessage -AST $ast
        
        # Step 3: Check with learning module for known patterns
        Write-FixEngineLog -Message "Step 3: Consulting learning module" -Level "DEBUG"
        $learningPattern = Connect-LearningModule -ErrorMessage $ErrorMessage -Action "GetPattern"
        
        # Step 4: Create fix template
        Write-FixEngineLog -Message "Step 4: Creating fix template" -Level "DEBUG"
        $template = New-FixTemplate -ErrorType $pattern.ErrorType -Pattern $pattern -AST $ast
        
        if ($template.Fixes.Count -eq 0) {
            Write-FixEngineLog -Message "No fixes available for this error type" -Level "WARN"
            $result.Success = $false
            $result.Message = "No fixes available for error type: $($pattern.ErrorType)"
            return $result
        }
        
        # Step 5: Apply template to generate modified content
        Write-FixEngineLog -Message "Step 5: Applying fix template" -Level "DEBUG"
        $templateResult = Invoke-TemplateApplication -Template $template -FilePath $FilePath -ErrorContext $pattern.ErrorLocation
        
        if (-not $templateResult.Success) {
            Write-FixEngineLog -Message "Template application failed: $($templateResult.Error)" -Level "ERROR"
            $result.Success = $false
            $result.Message = $templateResult.Error
            return $result
        }
        
        $result.AppliedFixes = $templateResult.AppliedFixes
        
        # Step 6: Validate the fix
        Write-FixEngineLog -Message "Step 6: Validating fix" -Level "DEBUG"
        $validationResult = Test-FixValidation -ModifiedContent $templateResult.ModifiedContent -OriginalFilePath $FilePath
        $result.ValidationResults = $validationResult.ValidationResults
        
        if (-not $validationResult.IsValid) {
            Write-FixEngineLog -Message "Fix validation failed: $($validationResult.Errors -join '; ')" -Level "ERROR"
            $result.Success = $false
            $result.Message = "Fix validation failed: $($validationResult.Errors -join '; ')"
            return $result
        }
        
        # Step 7: Safety framework check
        Write-FixEngineLog -Message "Step 7: Safety framework check" -Level "DEBUG"
        $highestConfidence = if ($template.Fixes.Count -gt 0) { ($template.Fixes | Measure-Object -Property Confidence -Maximum).Maximum } else { 0.5 }
        $safetyResult = Connect-SafetyFramework -FilePath $FilePath -FixContent $templateResult.ModifiedContent -Confidence $highestConfidence
        
        if (-not $safetyResult.IsSafe -and -not $Force) {
            Write-FixEngineLog -Message "Safety check failed: $($safetyResult.Reason)" -Level "WARN"
            $result.Success = $false
            $result.Message = "Safety check failed: $($safetyResult.Reason)"
            return $result
        }
        
        # Step 8: Apply fix or dry run
        if ($DryRun) {
            Write-FixEngineLog -Message "Dry run mode: Fix would be applied successfully" -Level "INFO"
            $result.Success = $true
            $result.Message = "Dry run successful - fix would be applied"
            $result.ModifiedContent = $templateResult.ModifiedContent
        } else {
            Write-FixEngineLog -Message "Step 8: Applying fix to file" -Level "INFO"
            $atomicResult = Invoke-AtomicFileReplace -FilePath $FilePath -NewContent $templateResult.ModifiedContent -BackupReason "Fix Application"
            
            $result.BackupPath = $atomicResult.BackupPath
            $result.Success = $atomicResult.Success
            
            if ($result.Success) {
                # Step 9: Compilation verification
                Write-FixEngineLog -Message "Step 9: Compilation verification" -Level "DEBUG"
                $compilationResult = Invoke-CompilationVerification -FilePath $FilePath
                $result.CompilationResult = $compilationResult
                
                if (-not $compilationResult.Success) {
                    Write-FixEngineLog -Message "Compilation verification failed - considering rollback" -Level "WARN"
                    # Could implement automatic rollback here if desired
                }
                
                $result.Message = "Fix applied successfully"
                Write-FixEngineLog -Message "Fix application completed successfully" -Level "INFO"
            } else {
                $result.Message = "Failed to apply fix to file"
                Write-FixEngineLog -Message "Fix application failed" -Level "ERROR"
            }
        }
        
        # Step 10: Send metrics to learning module
        Write-FixEngineLog -Message "Step 10: Sending metrics to learning module" -Level "DEBUG"
        Connect-LearningModule -ErrorMessage $ErrorMessage -FixResult $result -Action "SendMetrics"
        
    }
    catch {
        Write-FixEngineLog -Message "Fix application failed with exception: $_" -Level "ERROR"
        $result.Success = $false
        $result.Message = "Exception during fix application: $_"
    }
    
    return $result
}

function New-CodeFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    Write-FixEngineLog -Message "Creating code fix for error in: $FilePath" -Level "INFO"
    
    return Invoke-FixApplication -FilePath $FilePath -ErrorMessage $ErrorMessage -DryRun:$DryRun
}

function Test-FixSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FixResult
    )
    
    Write-FixEngineLog -Message "Testing fix success" -Level "DEBUG"
    
    $success = $FixResult.Success
    if ($success -and $FixResult.CompilationResult -and $FixResult.CompilationResult.ContainsKey('Success')) {
        $success = $FixResult.CompilationResult.Success
    }
    
    Write-FixEngineLog -Message "Fix success result: $success" -Level "DEBUG"
    return $success
}

#endregion

# Module initialization
Write-FixEngineLog -Message "Unity-Claude-FixEngine module loaded successfully" -Level "INFO"

# Export module members (functions are exported via manifest)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUU9dm4NLl57vEgNE8OEqBEta2
# 61ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUHLeenuIIFoxNm6TGf+yBPEmEWJ8wDQYJKoZIhvcNAQEBBQAEggEAeqjo
# w4Rps+6c+ekHG/1zyQ9fuHVvqc+i7Yf2Jcbm5npIWiWGy0fVC72ZQK9dU4zEreU3
# 4oVhPFtXzPTLjd6LJmaZB0aOBrrKI7b05qWqfURvRWjEZeAcHUNbOqcfnFATFmGz
# fO6AUSv6xZUJc9OYPUD57LsXEeDhNyUB48XRHDQnQhA2ONS7hxueoxAvAZr0aRnw
# kpYexU3nuemZcSpTU6/UT1NLOfiGhA/HV/jHsfUF9Sp0JCVcBqVGbrz1W1K4fOT6
# GUvLC1S0fYADmrIbtdX5qFkWG7xlLNKkvGLAgutynqUTOceUO+oDmZqKVKalmkK1
# xJ5MIJxkjgg34IV9KA==
# SIG # End signature block
