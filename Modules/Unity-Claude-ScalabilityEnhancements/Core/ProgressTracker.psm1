# Unity-Claude-ScalabilityEnhancements - Progress Tracker Component
# Progress tracking, cancellation tokens, and callback management

using namespace System.Threading

#region Progress Tracking & Cancellation

class ProgressTracker {
    [string]$OperationName
    [long]$TotalItems
    [long]$CompletedItems
    [datetime]$StartTime
    [datetime]$LastUpdate
    [hashtable]$Statistics
    [System.Collections.Generic.List[scriptblock]]$ProgressCallbacks
    [System.Threading.CancellationTokenSource]$CancellationTokenSource
    
    ProgressTracker([string]$operationName, [long]$totalItems) {
        $this.OperationName = $operationName
        $this.TotalItems = $totalItems
        $this.CompletedItems = 0
        $this.StartTime = [datetime]::Now
        $this.LastUpdate = [datetime]::Now
        $this.Statistics = @{
            ItemsPerSecond = 0.0
            EstimatedTimeRemaining = [TimeSpan]::Zero
            PercentComplete = 0.0
        }
        $this.ProgressCallbacks = [System.Collections.Generic.List[scriptblock]]::new()
        $this.CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
    }
    
    [void] UpdateProgress([long]$completedItems) {
        $this.CompletedItems = $completedItems
        $this.LastUpdate = [datetime]::Now
        
        $elapsedTime = $this.LastUpdate - $this.StartTime
        $this.Statistics.PercentComplete = if ($this.TotalItems -gt 0) { ($this.CompletedItems / $this.TotalItems) * 100 } else { 0 }
        $this.Statistics.ItemsPerSecond = if ($elapsedTime.TotalSeconds -gt 0) { $this.CompletedItems / $elapsedTime.TotalSeconds } else { 0 }
        
        if ($this.Statistics.ItemsPerSecond -gt 0 -and $this.CompletedItems -lt $this.TotalItems) {
            $remainingItems = $this.TotalItems - $this.CompletedItems
            $remainingSeconds = $remainingItems / $this.Statistics.ItemsPerSecond
            $this.Statistics.EstimatedTimeRemaining = [TimeSpan]::FromSeconds($remainingSeconds)
        } else {
            $this.Statistics.EstimatedTimeRemaining = [TimeSpan]::Zero
        }
        
        # Invoke progress callbacks
        foreach ($callback in $this.ProgressCallbacks) {
            try {
                & $callback $this.GetProgressReport()
            }
            catch {
                # Continue processing even if callback fails
            }
        }
    }
    
    [hashtable] GetProgressReport() {
        return @{
            OperationName = $this.OperationName
            TotalItems = $this.TotalItems
            CompletedItems = $this.CompletedItems
            PercentComplete = [math]::Round($this.Statistics.PercentComplete, 2)
            ItemsPerSecond = [math]::Round($this.Statistics.ItemsPerSecond, 2)
            ElapsedTime = ([datetime]::Now - $this.StartTime)
            EstimatedTimeRemaining = $this.Statistics.EstimatedTimeRemaining
            LastUpdate = $this.LastUpdate
            IsCancellationRequested = $this.CancellationTokenSource.Token.IsCancellationRequested
        }
    }
    
    [void] RegisterCallback([scriptblock]$callback) {
        $this.ProgressCallbacks.Add($callback)
    }
    
    [void] Cancel() {
        $this.CancellationTokenSource.Cancel()
    }
    
    [bool] IsCancellationRequested() {
        return $this.CancellationTokenSource.Token.IsCancellationRequested
    }
}

function New-ProgressTracker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OperationName,
        
        [Parameter(Mandatory=$true)]
        [long]$TotalItems
    )
    
    try {
        $tracker = [ProgressTracker]::new($OperationName, $TotalItems)
        return $tracker
    }
    catch {
        Write-Error "Failed to create progress tracker: $_"
        return $null
    }
}

function Update-OperationProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$ProgressTracker,
        
        [Parameter(Mandatory=$true)]
        [long]$CompletedItems
    )
    
    try {
        $ProgressTracker.UpdateProgress($CompletedItems)
        return @{ Success = $true }
    }
    catch {
        Write-Error "Failed to update progress: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Get-ProgressReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$ProgressTracker
    )
    
    try {
        return $ProgressTracker.GetProgressReport()
    }
    catch {
        Write-Error "Failed to get progress report: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function New-CancellationToken {
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds = 0
    )
    
    try {
        $tokenSource = if ($TimeoutSeconds -gt 0) {
            [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSeconds))
        } else {
            [System.Threading.CancellationTokenSource]::new()
        }
        
        return @{
            TokenSource = $tokenSource
            Token = $tokenSource.Token
            Success = $true
        }
    }
    catch {
        Write-Error "Failed to create cancellation token: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-CancellationRequested {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Threading.CancellationToken]$CancellationToken
    )
    
    return $CancellationToken.IsCancellationRequested
}

function Cancel-Operation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$ProgressTracker
    )
    
    try {
        $ProgressTracker.Cancel()
        return @{ Success = $true; Message = "Operation cancelled" }
    }
    catch {
        Write-Error "Failed to cancel operation: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Register-ProgressCallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$ProgressTracker,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$Callback
    )
    
    try {
        $ProgressTracker.RegisterCallback($Callback)
        return @{ Success = $true }
    }
    catch {
        Write-Error "Failed to register progress callback: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-ProgressTracker',
    'Update-OperationProgress',
    'Get-ProgressReport',
    'New-CancellationToken',
    'Test-CancellationRequested',
    'Cancel-Operation',
    'Register-ProgressCallback'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCi326+pzx/Ucf0
# mYmyxPJs8vIGXBdhBm1Bohf1Ep3pSaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIa6PAQOLL63GKcd+qDnryMM
# Xbz40N8//Xbbwk9A9uCTMA0GCSqGSIb3DQEBAQUABIIBAG/GFP8hlxVdOYua/DwS
# 8KvQymWHUm0sVz+w2vy6d3BrFawIB0HMqif0tTeUornaKdvOoQs/VRcKdWxtZ2sL
# tXBXwkgvSEMbZM2FCn6ISSi9FxVRKQz9uRjhf2RhqHJghgUtHN+vNkDCyVVD1o1f
# LxLsBni6pdnYQlSA6Lvt3Ilv+kDWBAXkJaofY1BFojYOv3RhcKb4MClflS7HIZNY
# vcLAYeMLpp5prmPbkVBPE5qaO0Em60uCFFWzJcF2AJxnDEpe8KF46I3m7t2knsbl
# 2xBRS393k5r1awM/5QJaNoaiAHTWDfFn/FbP4KLkBLGBYX4wzgDWymSE1zAikoCk
# pcI=
# SIG # End signature block
