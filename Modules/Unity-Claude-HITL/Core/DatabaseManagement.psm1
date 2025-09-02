# DatabaseManagement.psm1
# Human-in-the-Loop Database Management Component
# Version 2.0.0 - 2025-08-26
# Part of refactored Unity-Claude-HITL module

# Import core configuration
$coreModule = Join-Path $PSScriptRoot "HITLCore.psm1"
if (Test-Path $coreModule) {
    Import-Module $coreModule -Force -Global -ErrorAction SilentlyContinue
}

#region Database Management Functions

function Initialize-ApprovalDatabase {
    <#
    .SYNOPSIS
        Initializes the SQLite database for approval tracking.
    
    .DESCRIPTION
        Creates the necessary tables for approval tracking, escalation rules, and audit logs.
        Based on research findings for optimal schema design.
    
    .PARAMETER DatabasePath
        Path to the SQLite database file. Defaults to module configuration.
    
    .EXAMPLE
        Initialize-ApprovalDatabase
        Initialize-ApprovalDatabase -DatabasePath "C:\Data\approvals.db"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$DatabasePath = $(if ($script:HITLConfig) { $script:HITLConfig.DatabasePath } else { "$env:USERPROFILE\.unity-claude\hitl.db" })
    )
    
    Write-Verbose "Initializing approval database at: $DatabasePath"
    
    try {
        # Ensure directory exists
        $dbDir = Split-Path -Path $DatabasePath -Parent
        if (-not (Test-Path $dbDir)) {
            New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
        }
        
        # Database schema based on research findings
        $schema = @"
-- Approval Requests (Enhanced based on research)
CREATE TABLE IF NOT EXISTS approval_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workflow_id TEXT NOT NULL,
    thread_id TEXT NOT NULL,
    request_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    changes_summary TEXT,
    impact_analysis TEXT,
    urgency_level TEXT DEFAULT 'medium',
    requested_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    escalation_level INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending',
    approved_by TEXT,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    approval_token TEXT UNIQUE,
    mobile_friendly INTEGER DEFAULT 1,
    metadata TEXT
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_status_created ON approval_requests(status, created_at);
CREATE INDEX IF NOT EXISTS idx_workflow_thread ON approval_requests(workflow_id, thread_id);
CREATE INDEX IF NOT EXISTS idx_expires_at ON approval_requests(expires_at);
CREATE INDEX IF NOT EXISTS idx_approval_token ON approval_requests(approval_token);

-- Escalation Rules (Research-Based)
CREATE TABLE IF NOT EXISTS escalation_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_name TEXT UNIQUE NOT NULL,
    request_type TEXT NOT NULL,
    urgency_level TEXT NOT NULL,
    initial_timeout_minutes INTEGER DEFAULT 1440,
    escalation_levels TEXT NOT NULL,
    escalation_timeout_minutes INTEGER DEFAULT 720,
    fallback_action TEXT DEFAULT 'reject',
    auto_approve_threshold TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit Log
CREATE TABLE IF NOT EXISTS approval_audit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    approval_id INTEGER,
    action TEXT NOT NULL,
    actor TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT,
    ip_address TEXT,
    user_agent TEXT,
    FOREIGN KEY (approval_id) REFERENCES approval_requests(id)
);

-- Configuration Storage
CREATE TABLE IF NOT EXISTS hitl_configuration (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"@
        
        # Execute schema using PowerShell SQLite support
        if (Get-Command -Name Invoke-SqliteQuery -ErrorAction SilentlyContinue) {
            Invoke-SqliteQuery -DataSource $DatabasePath -Query $schema
        } else {
            # Fallback: Create database file and log schema for manual execution
            New-Item -Path $DatabasePath -ItemType File -Force | Out-Null
            Write-Warning "SQLite module not available. Database file created but schema must be initialized manually."
            Write-Host "Schema SQL saved to: $DatabasePath.schema.sql"
            $schema | Out-File -FilePath "$DatabasePath.schema.sql" -Encoding UTF8
        }
        
        Write-Host "Approval database initialized successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to initialize approval database: $($_.Exception.Message)"
        return $false
    }
}

function Test-DatabaseConnection {
    <#
    .SYNOPSIS
        Tests database connectivity and schema.
    
    .PARAMETER DatabasePath
        Path to the SQLite database file.
    
    .EXAMPLE
        Test-DatabaseConnection -DatabasePath $config.DatabasePath
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$DatabasePath = $(if ($script:HITLConfig) { $script:HITLConfig.DatabasePath } else { "$env:USERPROFILE\.unity-claude\hitl.db" })
    )
    
    try {
        if (-not (Test-Path $DatabasePath)) {
            Write-Warning "Database file does not exist: $DatabasePath"
            return $false
        }
        
        # Test basic connectivity
        if (Get-Command -Name Invoke-SqliteQuery -ErrorAction SilentlyContinue) {
            $result = Invoke-SqliteQuery -DataSource $DatabasePath -Query "SELECT COUNT(*) as TableCount FROM sqlite_master WHERE type='table';"
            Write-Verbose "Database contains $($result.TableCount) tables"
            return $true
        } else {
            Write-Warning "SQLite module not available for connectivity test"
            return $false
        }
    }
    catch {
        Write-Error "Database connectivity test failed: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Export Module Members

Export-ModuleMember -Function @(
    'Initialize-ApprovalDatabase',
    'Test-DatabaseConnection'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCANeQpJxJlDRL4l
# eQiJGiA34csGPAFLsalWuRsjkQAezKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINAUtQMeRfJfHLwaz6o0/Hwy
# VCGlIhke/39CUYiKBkatMA0GCSqGSIb3DQEBAQUABIIBAIbVocPSzM3qGXF4+LEy
# pcaFDlpyO5Uj+NRGzMHV8V1KG39HMdZlx7AJbFC3woWoTB7le8FgkbXSt2jQ8RRY
# lX47madyyo1ZJ+J+IjCR7A4hyOBXOV80GdGEof4z4OdDzG11qoD/Mz6gVyaUqHZG
# /FhoBodsKu8jiyupeGBOUCgBLDrzEvYjWN4SnFhLBIgiyxfbLnfc+FNyflzA9wBh
# v7sKjVXj9NdHiFhpzjkZdI7aSdSabQSdBa6QBGvTQdVdpzkHLqwmBYqzQeNIvmcS
# W4yScxWqvhlFFLUBcZF2Zzrq/Sv6JzNOlKBRvgBO+1mkms3XhDj5qTjDU+0Jh3qm
# qqc=
# SIG # End signature block
