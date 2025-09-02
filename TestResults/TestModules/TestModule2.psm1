#requires -Version 5.1

Import-Module TestModule1 -Force

function Test-Function3 {
    param([string])
    
    Test-Function1 -Parameter1 
    Write-Host "Test Function 3"
}

function Test-Function4 {
    Write-Host "Test Function 4"
}

Export-ModuleMember -Function @('Test-Function3', 'Test-Function4')
