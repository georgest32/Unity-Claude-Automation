# Test-Minimal-Queue.psm1
# Minimal test module to isolate ConcurrentQueue issue

function Test-NewConcurrentQueue {
    [CmdletBinding()]
    param()
    
    $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    return $queue
}

Export-ModuleMember -Function 'Test-NewConcurrentQueue'