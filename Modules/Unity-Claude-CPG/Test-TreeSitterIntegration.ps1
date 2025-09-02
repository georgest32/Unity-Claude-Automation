# Test-TreeSitterIntegration.ps1
# Test script for Tree-sitter integration with CPG module

#Requires -Version 5.1

param(
    [switch]$InstallParsers,
    [switch]$RunPerformanceTests,
    [switch]$SaveResults
)

# Import modules
$modulePath = Join-Path $PSScriptRoot "Unity-Claude-TreeSitter.psm1"
$cpgPath = Join-Path $PSScriptRoot "Unity-Claude-CPG.psd1"
$enumPath = Join-Path $PSScriptRoot "Unity-Claude-CPG-Enums.ps1"

Write-Host "Testing Tree-sitter Integration with CPG Module" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Load enums first
if (Test-Path $enumPath) {
    Write-Host "Loading enum definitions..." -ForegroundColor Gray
    . $enumPath
} else {
    Write-Error "Enum file not found: $enumPath"
    exit 1
}

# Import modules
Write-Host "Importing modules..." -ForegroundColor Gray
Import-Module $modulePath -Force -Verbose
Import-Module $cpgPath -Force

$results = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
    }
}

# Test 1: Initialize Tree-sitter
Write-Host "`nTest 1: Initialize Tree-sitter" -ForegroundColor Yellow
try {
    $initResult = Initialize-TreeSitter -Verbose
    
    if ($initResult.NodePath) {
        Write-Host "  [PASS] Tree-sitter initialized successfully" -ForegroundColor Green
        Write-Host "    Node.js: $($initResult.NodePath)"
        Write-Host "    Tree-sitter CLI: $($initResult.TreeSitterPath ?? 'Not found - using Node.js bindings')"
        Write-Host "    Installed parsers: $($initResult.InstalledParsers.Count)"
        
        $results.Tests += @{
            Name = "Initialize Tree-sitter"
            Status = "Passed"
            Details = $initResult
        }
        $results.Summary.Passed++
    } else {
        throw "Initialization failed - Node.js not found"
    }
}
catch {
    Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    $results.Tests += @{
        Name = "Initialize Tree-sitter"
        Status = "Failed"
        Error = $_.Exception.Message
    }
    $results.Summary.Failed++
}
$results.Summary.Total++

# Test 2: Install parsers if requested
if ($InstallParsers) {
    Write-Host "`nTest 2: Install Language Parsers" -ForegroundColor Yellow
    try {
        $installResult = Install-TreeSitterParsers -Languages All -Verbose
        
        if ($installResult) {
            Write-Host "  [PASS] Language parsers installed successfully" -ForegroundColor Green
            $results.Tests += @{
                Name = "Install Language Parsers"
                Status = "Passed"
            }
            $results.Summary.Passed++
        } else {
            throw "Parser installation failed"
        }
    }
    catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Install Language Parsers"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
}

# Test 3: Create test files for different languages
Write-Host "`nTest 3: Create Test Files" -ForegroundColor Yellow
$testDir = Join-Path $PSScriptRoot "test-files"
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

# JavaScript test file
$jsContent = @'
// test.js
function calculateSum(a, b) {
    return a + b;
}

class Calculator {
    constructor() {
        this.result = 0;
    }
    
    add(value) {
        this.result += value;
        return this;
    }
    
    getResult() {
        return this.result;
    }
}

const calc = new Calculator();
console.log(calc.add(5).add(10).getResult());
'@

$jsFile = Join-Path $testDir "test.js"
$jsContent | Out-File -FilePath $jsFile -Encoding UTF8

# Python test file
$pyContent = @'
# test.py
import os
import sys

def process_data(input_data):
    """Process input data and return results."""
    results = []
    for item in input_data:
        if item > 0:
            results.append(item * 2)
    return results

class DataProcessor:
    def __init__(self, name):
        self.name = name
        self.data = []
    
    def add_data(self, value):
        self.data.append(value)
    
    def process(self):
        return process_data(self.data)

if __name__ == "__main__":
    processor = DataProcessor("Test")
    processor.add_data(10)
    print(processor.process())
'@

$pyFile = Join-Path $testDir "test.py"
$pyContent | Out-File -FilePath $pyFile -Encoding UTF8

# TypeScript test file
$tsContent = @'
// test.ts
interface User {
    id: number;
    name: string;
    email: string;
}

class UserService {
    private users: User[] = [];
    
    addUser(user: User): void {
        this.users.push(user);
    }
    
    getUser(id: number): User | undefined {
        return this.users.find(u => u.id === id);
    }
    
    getAllUsers(): User[] {
        return this.users;
    }
}

const service = new UserService();
service.addUser({ id: 1, name: "Test User", email: "test@example.com" });
'@

$tsFile = Join-Path $testDir "test.ts"
$tsContent | Out-File -FilePath $tsFile -Encoding UTF8

# C# test file
$csContent = @'
// test.cs
using System;
using System.Collections.Generic;

namespace TestApp
{
    public interface IDataService
    {
        void SaveData(string data);
        string LoadData();
    }
    
    public class DataService : IDataService
    {
        private List<string> dataStore = new List<string>();
        
        public void SaveData(string data)
        {
            dataStore.Add(data);
        }
        
        public string LoadData()
        {
            return string.Join(",", dataStore);
        }
    }
    
    class Program
    {
        static void Main(string[] args)
        {
            var service = new DataService();
            service.SaveData("Test");
            Console.WriteLine(service.LoadData());
        }
    }
}
'@

$csFile = Join-Path $testDir "test.cs"
$csContent | Out-File -FilePath $csFile -Encoding UTF8

Write-Host "  [PASS] Test files created successfully" -ForegroundColor Green
$results.Tests += @{
    Name = "Create Test Files"
    Status = "Passed"
    Files = @($jsFile, $pyFile, $tsFile, $csFile)
}
$results.Summary.Passed++
$results.Summary.Total++

# Test 4: Parse JavaScript file
Write-Host "`nTest 4: Parse JavaScript File" -ForegroundColor Yellow
try {
    # Check if parser is installed
    $parserPath = Join-Path $PSScriptRoot "parsers\node_modules\tree-sitter-javascript"
    if (-not (Test-Path $parserPath)) {
        Write-Warning "JavaScript parser not installed. Skipping test."
        Write-Host "  Run with -InstallParsers to install language parsers"
    } else {
        $parseResult = Invoke-TreeSitterParse -FilePath $jsFile -Language JavaScript -OutputFormat JSON -Verbose
        
        if ($parseResult) {
            Write-Host "  [PASS] JavaScript file parsed successfully" -ForegroundColor Green
            Write-Host "    Parse tree nodes found" -ForegroundColor Gray
            
            $results.Tests += @{
                Name = "Parse JavaScript File"
                Status = "Passed"
                NodeCount = ($parseResult | ConvertTo-Json | Out-String).Length
            }
            $results.Summary.Passed++
        } else {
            throw "No parse result returned"
        }
    }
}
catch {
    Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    $results.Tests += @{
        Name = "Parse JavaScript File"
        Status = "Failed"
        Error = $_.Exception.Message
    }
    $results.Summary.Failed++
}
$results.Summary.Total++

# Test 5: Convert CST to CPG
Write-Host "`nTest 5: Convert CST to CPG" -ForegroundColor Yellow
try {
    $parserPath = Join-Path $PSScriptRoot "parsers\node_modules\tree-sitter-javascript"
    if (-not (Test-Path $parserPath)) {
        Write-Warning "JavaScript parser not installed. Skipping test."
    } else {
        $cstData = Invoke-TreeSitterParse -FilePath $jsFile -Language JavaScript -OutputFormat JSON
        $cpgGraph = ConvertFrom-TreeSitterCST -CSTData $cstData -Language JavaScript
        
        if ($cpgGraph) {
            $nodeCount = $cpgGraph.Nodes.Count
            $edgeCount = $cpgGraph.Edges.Count
            
            Write-Host "  [PASS] CST converted to CPG successfully" -ForegroundColor Green
            Write-Host "    Nodes: $nodeCount" -ForegroundColor Gray
            Write-Host "    Edges: $edgeCount" -ForegroundColor Gray
            
            # Show node type distribution
            $nodeTypes = $cpgGraph.Nodes.Values | Group-Object Type
            Write-Host "    Node types:" -ForegroundColor Gray
            foreach ($type in $nodeTypes) {
                Write-Host "      - $($type.Name): $($type.Count)" -ForegroundColor Gray
            }
            
            $results.Tests += @{
                Name = "Convert CST to CPG"
                Status = "Passed"
                NodeCount = $nodeCount
                EdgeCount = $edgeCount
                NodeTypes = $nodeTypes
            }
            $results.Summary.Passed++
        } else {
            throw "Conversion failed"
        }
    }
}
catch {
    Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    $results.Tests += @{
        Name = "Convert CST to CPG"
        Status = "Failed"
        Error = $_.Exception.Message
    }
    $results.Summary.Failed++
}
$results.Summary.Total++

# Test 6: Performance benchmark
if ($RunPerformanceTests) {
    Write-Host "`nTest 6: Performance Benchmark" -ForegroundColor Yellow
    try {
        $parserPath = Join-Path $PSScriptRoot "parsers\node_modules\tree-sitter-javascript"
        if (-not (Test-Path $parserPath)) {
            Write-Warning "JavaScript parser not installed. Skipping test."
        } else {
            $perfResults = Test-TreeSitterPerformance -TestFilePath $jsFile -Language JavaScript -Iterations 10
            
            $avgTime = ($perfResults | Where-Object Success | Select-Object -ExpandProperty ElapsedMs | Measure-Object -Average).Average
            
            if ($avgTime -lt 100) {  # Target: <100ms for small files
                Write-Host "  [PASS] Performance target met" -ForegroundColor Green
                $results.Tests += @{
                    Name = "Performance Benchmark"
                    Status = "Passed"
                    AverageMs = $avgTime
                }
                $results.Summary.Passed++
            } else {
                Write-Host "  [WARN] Performance below target" -ForegroundColor Yellow
                $results.Tests += @{
                    Name = "Performance Benchmark"
                    Status = "Warning"
                    AverageMs = $avgTime
                }
            }
        }
    }
    catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Performance Benchmark"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
}

# Display summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($results.Summary.Total)"
Write-Host "Passed: $($results.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Summary.Failed)" -ForegroundColor Red

$passRate = if ($results.Summary.Total -gt 0) {
    [Math]::Round(($results.Summary.Passed / $results.Summary.Total) * 100, 1)
} else { 0 }

Write-Host "Pass Rate: $passRate%"

# Save results if requested
if ($SaveResults) {
    $resultsFile = Join-Path $PSScriptRoot "TreeSitterIntegration-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray
}

# Return exit code
if ($results.Summary.Failed -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed. Please review the errors above." -ForegroundColor Yellow
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA8WagxoXvzdFbU
# rRmuv88FGaUmIJwq2Pg1HGD7GDIbYaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKAdx8BhCEepW/HdUBMWYqsA
# 85xQeFO4ahhFHWv2EQCfMA0GCSqGSIb3DQEBAQUABIIBAK3llxEgZN4cu5UnL6Lo
# Bzkme0v25mi8+ZXuQVlag1CMqOOrEAe68EUtbDa2BUffq/eg3ufA6hkFZ1RsRjGp
# HVC07MJJj/CQ+d+yemgzjtDyq29KVRpiVo/gbipJmMW5UHxOG63Quite8ivoKozx
# JCY6sxZQKRl2s8OEbrPryOa4fw/X2aGCgqCqr6akmwdltgz6mDlFER0l6g0Xgsjy
# Haqdekw+p3TLrz8iyUYe8mZMjMrMQKJovuFg2Ob8k+oihn6rrYhJUCB8lKukIskm
# WSkDVYoSujlMjULd36PnCLRiYaZvkrrrHUFBgXZv+ipYGkpxZIp2TCt7nbRvfc3X
# uCc=
# SIG # End signature block
