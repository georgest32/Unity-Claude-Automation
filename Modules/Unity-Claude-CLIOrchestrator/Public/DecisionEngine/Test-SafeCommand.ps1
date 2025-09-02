function Test-SafeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $result = @{
        IsSafe = $true
        Reason = "Command is safe"
        Warnings = @()
    }
    
    try {
        # List of dangerous commands
        $dangerousCommands = @(
            'Remove-Item.*-Recurse.*-Force',
            'rm\s+-rf',
            'del\s+/s\s+/q',
            'format',
            'shutdown',
            'restart-computer',
            'stop-computer',
            'disable-computerrestore',
            'wmic.*delete',
            'reg\s+delete',
            'netsh.*reset',
            'diskpart',
            'fdisk'
        )
        
        # Check for dangerous patterns
        foreach ($pattern in $dangerousCommands) {
            if ($Command -match $pattern) {
                $result.IsSafe = $false
                $result.Reason = "Command contains dangerous pattern: $pattern"
                Write-DecisionLog "UNSAFE COMMAND: $pattern detected in: $Command" "ERROR"
                return $result
            }
        }
        
        # Check for suspicious file operations
        $suspiciousPatterns = @(
            'C:\\Windows',
            'C:\\Program Files',
            'C:\\System',
            '\\System32',
            'HKLM:',
            'HKEY_LOCAL_MACHINE'
        )
        
        foreach ($pattern in $suspiciousPatterns) {
            if ($Command -match [regex]::Escape($pattern)) {
                $result.Warnings += "Command operates on system location: $pattern"
                Write-DecisionLog "WARNING: System location detected: $pattern" "WARN"
            }
        }
        
        Write-DecisionLog "Command safety validation passed: $($Command.Substring(0, [Math]::Min(50, $Command.Length)))" "DEBUG"
        return $result
        
    } catch {
        $result.IsSafe = $false
        $result.Reason = "Command validation error: $($_.Exception.Message)"
        return $result
    }
}