# Claude Integration - Unity-Claude Automation
*Claude CLI and API integration specifics, SendKeys automation, and response processing*
*Last Updated: 2025-08-19*

## 🔧 API Integration Learnings

### 7. API Key Management (✅ RESOLVED)
**Issue**: Secure storage of Anthropic API key
**Discovery**: Environment variables sufficient for development
**Evidence**: $env:ANTHROPIC_API_KEY standard practice
**Resolution**: Use env var for dev, consider Credential Manager for production
**Critical Learning**: Never hardcode keys; always check for key existence

### 8. Token Usage and Costs (📝 DOCUMENTED)
**Issue**: Understanding API costs
**Discovery**: Detailed token usage in responses
**Evidence**: Input tokens ~$3/million, output ~$15/million
**Resolution**: Calculate and display costs; implement limits if needed
**Critical Learning**: Always show token usage to users for transparency

### 9. Response Parsing (✅ RESOLVED)
**Issue**: Extracting code from Claude responses
**Discovery**: Responses contain markdown code blocks
**Evidence**: Regex pattern `\`\`\`powershell([\s\S]*?)\`\`\`` works reliably
**Resolution**: Parse markdown blocks; validate before execution
**Critical Learning**: Never execute extracted code without validation

## 🎯 SendKeys Automation Learnings

### 10. Window Focus Management (⚠️ CRITICAL)
**Issue**: SendKeys requires correct window focus
**Discovery**: Alt+Tab ordering critical for success
**Evidence**: Scripts fail if Claude window not next in Alt+Tab order
**Resolution**: Document window setup; add delay for user positioning
**Critical Learning**: Always give user time to arrange windows

### 11. Typing Speed vs Reliability (✅ RESOLVED)
**Issue**: Fast typing causes character drops
**Discovery**: Terminal input buffers can overflow
**Evidence**: 10ms delay reliable; 0ms causes issues
**Resolution**: Default 10ms delay; make configurable
**Critical Learning**: Reliability over speed for SendKeys

### 12. Special Character Handling (📝 DOCUMENTED)
**Issue**: Special chars break SendKeys
**Discovery**: Brackets, quotes need escaping
**Evidence**: `{`, `}`, `[`, `]` have special meaning in SendKeys
**Resolution**: Escape special characters before sending
**Critical Learning**: Always sanitize text for SendKeys

### 131. SendKeys Window Detection Specificity (Day 13 - ✅ RESOLVED)
**Issue**: SendKeys targeting wrong PowerShell window causing random command execution
**Discovery**: Window title matching too broad - captures PowerShell ISE, VS Code terminals, etc.
**Evidence**: "claude" search matched PowerShell processes with "claude" in path/arguments
**Location**: CLIAutomation.psm1 Submit-InputToClaudeViaKeys function
**Root Cause**: Generic process name search includes unrelated PowerShell processes
**Technical Details**:
- Get-Process searches all processes by name pattern
- PowerShell ISE often has "claude" in recent file paths  
- VS Code terminals may contain "claude" in working directory
- SendKeys execution in wrong window can cause destructive commands
**Resolution**: Remove PowerShell processes from search list and require explicit Claude title match:
```powershell
# Only search Claude-specific processes first
$claudeProcesses = Get-Process -Name "claude" -ErrorAction SilentlyContinue
# For terminals, require explicit "claude" in title
if ($title -match "claude|Claude") { ... }
```
**Critical Learning**: Be very specific with window detection to avoid SendKeys targeting wrong applications

## 📡 Claude CLI Integration Patterns

### CLI Setup and Verification
```powershell
# Check Claude CLI installation
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Error "Claude CLI not found. Install from: https://github.com/anthropics/claude-cli"
    return
}

# Verify Claude CLI version
$claudeVersion = claude --version
Write-Host "Claude CLI Version: $claudeVersion"
```

### SendKeys Window Setup Requirements
**Manual Setup Process**:
1. Open Claude Code CLI with `claude chat`
2. Position Claude window as next in Alt+Tab order after PowerShell
3. Ensure Claude window is ready to receive input
4. Run automation script with proper delay

**Window Detection Pattern**:
```powershell
function Find-ClaudeWindow {
    # Primary: Look for Claude-specific processes
    $claudeProcesses = Get-Process -Name "claude" -ErrorAction SilentlyContinue
    
    if ($claudeProcesses) {
        foreach ($process in $claudeProcesses) {
            $windowTitle = $process.MainWindowTitle
            if ($windowTitle -and $windowTitle -match "claude|Claude") {
                return $process
            }
        }
    }
    
    # Fallback: Terminal windows with Claude in title
    $allProcesses = Get-Process | Where-Object { $_.MainWindowTitle }
    foreach ($process in $allProcesses) {
        if ($process.MainWindowTitle -match "claude|Claude" -and 
            $process.ProcessName -notin @("powershell", "powershell_ise", "Code")) {
            return $process
        }
    }
    
    return $null
}
```

### SendKeys Input Reliability
```powershell
function Send-TextToClaudeReliably {
    param(
        [string]$Text,
        [int]$DelayBetweenCharacters = 10
    )
    
    # Escape SendKeys special characters
    $escapedText = $Text -replace '([{}()\[\]%~^+])', '{$1}'
    
    # Send with character delay for reliability
    foreach ($char in $escapedText.ToCharArray()) {
        [System.Windows.Forms.SendKeys]::SendWait($char)
        Start-Sleep -Milliseconds $DelayBetweenCharacters
    }
    
    # Send Enter to submit
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
}
```

## 🔍 Response Processing Patterns

### Claude Response Structure Recognition
**Standard Patterns**:
```powershell
# RECOMMENDED patterns
$recommendedPattern = 'RECOMMENDED:\s*([A-Z]+)\s*-\s*(.+)'

# Code blocks
$codeBlockPattern = '```(?:powershell|ps1)?\s*([\s\S]*?)```'

# Action-oriented responses
$actionPattern = '(?:Please|Try|Run|Execute|Use)\s+(.+)'
```

### Response Classification Engine
```powershell
function Classify-ClaudeResponse {
    param([string]$Response)
    
    $classification = @{
        Type = "Information"
        Confidence = 0.0
        RecommendedAction = $null
        CodeBlocks = @()
        RequiresHumanInput = $false
    }
    
    # Check for RECOMMENDED pattern (highest priority)
    if ($Response -match 'RECOMMENDED:\s*([A-Z]+)\s*-\s*(.+)') {
        $classification.Type = "Recommendation"
        $classification.RecommendedAction = $Matches[2]
        $classification.Confidence = 0.95
        return $classification
    }
    
    # Check for code blocks
    $codeMatches = [regex]::Matches($Response, '```(?:powershell|ps1)?\s*([\s\S]*?)```')
    if ($codeMatches.Count -gt 0) {
        $classification.CodeBlocks = $codeMatches | ForEach-Object { $_.Groups[1].Value.Trim() }
        $classification.Type = "Instruction"
        $classification.Confidence = 0.8
    }
    
    return $classification
}
```

### Context Extraction for Follow-up
```powershell
function Extract-ContextFromResponse {
    param([string]$Response)
    
    $context = @{
        ErrorCodes = @()
        FilePaths = @()
        UnityTerms = @()
        ConversationCues = @()
        NextActions = @()
    }
    
    # Extract Unity error codes
    $errorMatches = [regex]::Matches($Response, 'CS\d{4}')
    $context.ErrorCodes = $errorMatches | ForEach-Object { $_.Value }
    
    # Extract file paths
    $pathMatches = [regex]::Matches($Response, '[A-Za-z]:\\[^""\s]+|[./][^""\s]+\.(?:cs|js|ts|json|md)')
    $context.FilePaths = $pathMatches | ForEach-Object { $_.Value }
    
    # Extract Unity-specific terms
    $unityTerms = @('MonoBehaviour', 'GameObject', 'Transform', 'ScriptableObject', 'Unity', 'Asset')
    foreach ($term in $unityTerms) {
        if ($Response -match $term) {
            $context.UnityTerms += $term
        }
    }
    
    return $context
}
```

## 🛡️ Safety and Validation Patterns

### Response Validation Before Execution
```powershell
function Test-ResponseSafety {
    param([string]$Response)
    
    # Dangerous patterns to avoid
    $dangerousPatterns = @(
        'Remove-Item.*-Recurse',
        'Format-Volume',
        'Stop-Process.*-Force',
        'Invoke-Expression',
        'powershell.*-EncodedCommand'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Response -match $pattern) {
            Write-Warning "Potentially dangerous command detected: $pattern"
            return $false
        }
    }
    
    return $true
}
```

### Command Extraction and Validation
```powershell
function Extract-SafeCommands {
    param([string]$Response)
    
    $commands = @()
    $codeBlocks = [regex]::Matches($Response, '```(?:powershell|ps1)?\s*([\s\S]*?)```')
    
    foreach ($match in $codeBlocks) {
        $code = $match.Groups[1].Value.Trim()
        
        # Validate safety
        if (Test-ResponseSafety -Response $code) {
            $commands += @{
                Code = $code
                Type = "PowerShell"
                SafetyChecked = $true
            }
        } else {
            Write-Warning "Skipping unsafe command block"
        }
    }
    
    return $commands
}
```

---
*This document covers Claude-specific integration patterns.*
*For broader automation patterns, see LEARNINGS_UNITY_AUTOMATION.md*