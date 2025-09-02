#requires -Version 5.1

function Test-Function1 {
    param([string])
    
    Write-Host "Test Function 1"
    Test-Function2 -Parameter1 
}

function Test-Function2 {
    param([string])
    
    Write-Host "Test Function 2: "
}

Export-ModuleMember -Function @('Test-Function1', 'Test-Function2')
