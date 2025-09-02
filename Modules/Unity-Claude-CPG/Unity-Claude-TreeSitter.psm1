# Unity-Claude-TreeSitter.psm1
# Tree-sitter integration for universal code parsing
# Part of the CPG enhancement for multi-language support

#Requires -Version 5.1

# Module variables
$script:TreeSitterPath = $null
$script:NodePath = $null
$script:ParsersPath = Join-Path $PSScriptRoot "parsers"
$script:TreeSitterScript = Join-Path $PSScriptRoot "tree-sitter-parser.js"

function Initialize-TreeSitter {
    [CmdletBinding()]
    param(
        [string]$CustomTreeSitterPath,
        [string]$CustomNodePath
    )
    
    Write-Verbose "Initializing Tree-sitter integration"
    
    # Check for Node.js
    if ($CustomNodePath) {
        $script:NodePath = $CustomNodePath
    } else {
        $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
        if ($nodeCmd) {
            $script:NodePath = $nodeCmd.Path
        } else {
            throw "Node.js not found. Please install Node.js or provide path with -CustomNodePath"
        }
    }
    
    # Check for tree-sitter CLI
    if ($CustomTreeSitterPath) {
        $script:TreeSitterPath = $CustomTreeSitterPath
    } else {
        $tsCmd = Get-Command tree-sitter -ErrorAction SilentlyContinue
        if ($tsCmd) {
            $script:TreeSitterPath = $tsCmd.Path
        } else {
            Write-Warning "Tree-sitter CLI not found. Will use Node.js bindings only."
        }
    }
    
    # Create parsers directory if it doesn't exist
    if (-not (Test-Path $script:ParsersPath)) {
        New-Item -ItemType Directory -Path $script:ParsersPath -Force | Out-Null
    }
    
    # Check for installed parsers
    $installedParsers = @()
    $parserPackages = @(
        "tree-sitter-javascript",
        "tree-sitter-typescript", 
        "tree-sitter-python",
        "tree-sitter-c-sharp"
    )
    
    foreach ($parser in $parserPackages) {
        $parserPath = Join-Path $script:ParsersPath "node_modules\$parser"
        if (Test-Path $parserPath) {
            $installedParsers += $parser
        }
    }
    
    Write-Verbose "Node.js path: $script:NodePath"
    Write-Verbose "Tree-sitter CLI path: $script:TreeSitterPath"
    Write-Verbose "Installed parsers: $($installedParsers -join ', ')"
    
    return @{
        NodePath = $script:NodePath
        TreeSitterPath = $script:TreeSitterPath
        ParsersPath = $script:ParsersPath
        InstalledParsers = $installedParsers
    }
}

function Install-TreeSitterParsers {
    [CmdletBinding()]
    param(
        [ValidateSet("JavaScript", "TypeScript", "Python", "CSharp", "All")]
        [string[]]$Languages = "All"
    )
    
    Write-Verbose "Installing Tree-sitter parsers for: $($Languages -join ', ')"
    
    # Map language names to npm packages
    $parserMap = @{
        "JavaScript" = "tree-sitter-javascript"
        "TypeScript" = "tree-sitter-typescript"
        "Python" = "tree-sitter-python"
        "CSharp" = "tree-sitter-c-sharp"
    }
    
    if ($Languages -contains "All") {
        $packagesToInstall = $parserMap.Values
    } else {
        $packagesToInstall = @()
        foreach ($lang in $Languages) {
            if ($parserMap.ContainsKey($lang)) {
                $packagesToInstall += $parserMap[$lang]
            }
        }
    }
    
    # Install tree-sitter base package first
    $packagesToInstall = @("tree-sitter") + $packagesToInstall
    
    $currentDir = Get-Location
    try {
        Set-Location $script:ParsersPath
        
        # Create package.json if it doesn't exist
        if (-not (Test-Path "package.json")) {
            $packageJson = @{
                name = "tree-sitter-parsers"
                version = "1.0.0"
                description = "Tree-sitter language parsers for Unity-Claude-CPG"
                private = $true
            } | ConvertTo-Json
            
            $packageJson | Out-File -FilePath "package.json" -Encoding UTF8
        }
        
        # Install packages
        $npmCmd = "npm install " + ($packagesToInstall -join " ")
        Write-Verbose "Running: $npmCmd"
        
        $result = & cmd /c $npmCmd 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully installed Tree-sitter parsers" -ForegroundColor Green
        } else {
            Write-Warning "Error installing parsers: $result"
        }
        
        return $LASTEXITCODE -eq 0
    }
    finally {
        Set-Location $currentDir
    }
}

function Invoke-TreeSitterParse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [ValidateSet("JavaScript", "TypeScript", "Python", "CSharp", "PowerShell")]
        [string]$Language,
        
        [ValidateSet("XML", "JSON", "CST", "Default")]
        [string]$OutputFormat = "JSON",
        
        [switch]$UseCliParser
    )
    
    Write-Verbose "Parsing file: $FilePath with language: $Language"
    
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    # Use CLI parser if requested and available
    if ($UseCliParser -and $script:TreeSitterPath) {
        return Invoke-TreeSitterCliParse @PSBoundParameters
    }
    
    # Otherwise use Node.js bindings
    return Invoke-TreeSitterNodeParse @PSBoundParameters
}

function Invoke-TreeSitterCliParse {
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [string]$Language,
        [string]$OutputFormat
    )
    
    Write-Verbose "Using Tree-sitter CLI for parsing"
    
    $formatArg = switch ($OutputFormat) {
        "XML" { "-x" }
        "CST" { "--cst" }
        default { "" }
    }
    
    $parseCmd = "$script:TreeSitterPath parse `"$FilePath`" $formatArg"
    Write-Verbose "Running: $parseCmd"
    
    $output = & cmd /c $parseCmd 2>&1
    
    if ($OutputFormat -eq "JSON") {
        # Convert output to JSON since tree-sitter doesn't support native JSON
        return ConvertTreeSitterOutputToJson -Output $output -Language $Language
    }
    
    return $output
}

function Invoke-TreeSitterNodeParse {
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [string]$Language,
        [string]$OutputFormat
    )
    
    Write-Verbose "Using Node.js bindings for parsing"
    
    # Create Node.js script if it doesn't exist
    if (-not (Test-Path $script:TreeSitterScript)) {
        Write-TreeSitterNodeScript
    }
    
    # Map language to parser package
    $parserMap = @{
        "JavaScript" = "tree-sitter-javascript"
        "TypeScript" = "tree-sitter-typescript"
        "Python" = "tree-sitter-python"
        "CSharp" = "tree-sitter-c-sharp"
        "PowerShell" = "tree-sitter-powershell"  # If available
    }
    
    $parserPackage = $parserMap[$Language]
    if (-not $parserPackage) {
        throw "Unsupported language: $Language"
    }
    
    # Run Node.js script
    $nodeArgs = @(
        $script:TreeSitterScript,
        $FilePath,
        $parserPackage,
        $OutputFormat
    )
    
    Write-Verbose "Running Node.js with args: $($nodeArgs -join ' ')"
    
    $output = & $script:NodePath $nodeArgs 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "Tree-sitter parsing failed: $output"
    }
    
    if ($OutputFormat -eq "JSON") {
        return $output | ConvertFrom-Json
    }
    
    return $output
}

function Write-TreeSitterNodeScript {
    Write-Verbose "Creating Node.js tree-sitter script"
    
    $scriptContent = @'
// tree-sitter-parser.js
// Node.js script for parsing code with tree-sitter

const fs = require('fs');
const path = require('path');

// Parse command line arguments
const [,, filePath, parserPackage, outputFormat] = process.argv;

if (!filePath || !parserPackage) {
    console.error('Usage: node tree-sitter-parser.js <file> <parser-package> [format]');
    process.exit(1);
}

// Load parser
const Parser = require(path.join(__dirname, 'parsers', 'node_modules', 'tree-sitter'));
let Language;

try {
    const parserPath = path.join(__dirname, 'parsers', 'node_modules', parserPackage);
    
    // Handle TypeScript special case (has .typescript and .tsx)
    if (parserPackage === 'tree-sitter-typescript') {
        const ts = require(parserPath);
        Language = filePath.endsWith('.tsx') ? ts.tsx : ts.typescript;
    } else {
        Language = require(parserPath);
    }
} catch (e) {
    console.error(`Failed to load parser ${parserPackage}: ${e.message}`);
    process.exit(1);
}

// Read file
let sourceCode;
try {
    sourceCode = fs.readFileSync(filePath, 'utf8');
} catch (e) {
    console.error(`Failed to read file ${filePath}: ${e.message}`);
    process.exit(1);
}

// Parse code
const parser = new Parser();
parser.setLanguage(Language);
const tree = parser.parse(sourceCode);

// Output based on format
function nodeToJson(node) {
    const children = [];
    for (let i = 0; i < node.childCount; i++) {
        children.push(nodeToJson(node.child(i)));
    }
    
    return {
        type: node.type,
        startPosition: node.startPosition,
        endPosition: node.endPosition,
        startIndex: node.startIndex,
        endIndex: node.endIndex,
        text: node.text.substring(0, 100), // Limit text for large nodes
        isNamed: node.isNamed,
        children: children
    };
}

switch (outputFormat) {
    case 'JSON':
        const jsonOutput = nodeToJson(tree.rootNode);
        console.log(JSON.stringify(jsonOutput, null, 2));
        break;
    
    case 'XML':
        // Convert to XML format
        function nodeToXml(node, indent = '') {
            let xml = `${indent}<${node.type}`;
            if (node.isNamed) xml += ' named="true"';
            xml += `>\n`;
            
            if (node.childCount === 0) {
                const text = node.text.replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;');
                xml += `${indent}  ${text}\n`;
            } else {
                for (let i = 0; i < node.childCount; i++) {
                    xml += nodeToXml(node.child(i), indent + '  ');
                }
            }
            
            xml += `${indent}</${node.type}>\n`;
            return xml;
        }
        console.log(nodeToXml(tree.rootNode));
        break;
    
    case 'CST':
    default:
        // Default S-expression format
        console.log(tree.rootNode.toString());
        break;
}
'@
    
    $scriptContent | Out-File -FilePath $script:TreeSitterScript -Encoding UTF8
}

function ConvertTreeSitterOutputToJson {
    [CmdletBinding()]
    param(
        [string[]]$Output,
        [string]$Language
    )
    
    Write-Verbose "Converting tree-sitter output to JSON"
    
    # Parse S-expression format and convert to JSON
    # This is a simplified conversion - real implementation would need proper parsing
    
    $json = @{
        language = $Language
        parseTree = $Output -join "`n"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    return $json | ConvertTo-Json -Depth 10
}

function ConvertFrom-TreeSitterCST {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $CSTData,
        
        [Parameter(Mandatory)]
        [string]$Language
    )
    
    Write-Verbose "Converting CST to CPG format for language: $Language"
    
    # Load CPG module types
    $enumPath = Join-Path (Split-Path $PSScriptRoot) "Unity-Claude-CPG\Unity-Claude-CPG-Enums.ps1"
    if (Test-Path $enumPath) {
        . $enumPath
    }
    
    # Create CPG graph
    $graph = New-CPGraph -Name "$Language-CST-Graph"
    
    # Convert based on data type
    if ($CSTData -is [string]) {
        $CSTData = $CSTData | ConvertFrom-Json
    }
    
    # Process root node
    Process-CSTNode -Node $CSTData -Graph $graph -Language $Language
    
    return $graph
}

function Process-CSTNode {
    [CmdletBinding()]
    param(
        $Node,
        $Graph,
        [string]$Language,
        $ParentNode = $null
    )
    
    # Map CST node types to CPG node types
    $nodeTypeMap = @{
        # JavaScript/TypeScript
        "function_declaration" = [CPGNodeType]::Function
        "function_expression" = [CPGNodeType]::Function
        "arrow_function" = [CPGNodeType]::Function
        "class_declaration" = [CPGNodeType]::Class
        "variable_declaration" = [CPGNodeType]::Variable
        "identifier" = [CPGNodeType]::Variable
        "import_statement" = [CPGNodeType]::Module
        "export_statement" = [CPGNodeType]::Module
        
        # Python
        "function_definition" = [CPGNodeType]::Function
        "class_definition" = [CPGNodeType]::Class
        "assignment" = [CPGNodeType]::Variable
        "import_from_statement" = [CPGNodeType]::Module
        
        # C#
        "method_declaration" = [CPGNodeType]::Method
        "cs_class_declaration" = [CPGNodeType]::Class
        "interface_declaration" = [CPGNodeType]::Interface
        "field_declaration" = [CPGNodeType]::Field
        "property_declaration" = [CPGNodeType]::Property
        "using_directive" = [CPGNodeType]::Module
        
        # Generic
        "program" = [CPGNodeType]::File
        "module" = [CPGNodeType]::Module
    }
    
    # Determine CPG node type
    $cpgNodeType = if ($nodeTypeMap.ContainsKey($Node.type)) {
        $nodeTypeMap[$Node.type]
    } else {
        [CPGNodeType]::Unknown
    }
    
    # Skip unnamed nodes unless they're important
    if (-not $Node.isNamed -and $cpgNodeType -eq [CPGNodeType]::Unknown) {
        # Process children without creating a node
        if ($Node.children) {
            foreach ($child in $Node.children) {
                Process-CSTNode -Node $child -Graph $Graph -Language $Language -ParentNode $ParentNode
            }
        }
        return
    }
    
    # Create CPG node
    $cpgNode = New-CPGNode `
        -Name ($Node.text ?? $Node.type) `
        -Type $cpgNodeType `
        -Properties @{
            CSTType = $Node.type
            StartLine = $Node.startPosition.row + 1
            StartColumn = $Node.startPosition.column
            EndLine = $Node.endPosition.row + 1
            EndColumn = $Node.endPosition.column
            Language = $Language
        }
    
    Add-CPGNode -Graph $Graph -Node $cpgNode
    
    # Create edge to parent if exists
    if ($ParentNode) {
        $edge = New-CPGEdge `
            -SourceId $ParentNode.Id `
            -TargetId $cpgNode.Id `
            -Type Contains
        
        Add-CPGEdge -Graph $Graph -Edge $edge
    }
    
    # Process children
    if ($Node.children) {
        foreach ($child in $Node.children) {
            Process-CSTNode -Node $child -Graph $Graph -Language $Language -ParentNode $cpgNode
        }
    }
    
    return $cpgNode
}

function Test-TreeSitterPerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestFilePath,
        
        [ValidateSet("JavaScript", "TypeScript", "Python", "CSharp")]
        [string]$Language = "JavaScript",
        
        [int]$Iterations = 10
    )
    
    Write-Host "Running Tree-sitter performance test..." -ForegroundColor Cyan
    Write-Host "File: $TestFilePath"
    Write-Host "Language: $Language"
    Write-Host "Iterations: $Iterations"
    
    $results = @()
    
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Progress -Activity "Performance Test" -Status "Iteration $i of $Iterations" -PercentComplete (($i/$Iterations)*100)
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $result = Invoke-TreeSitterParse -FilePath $TestFilePath -Language $Language -OutputFormat JSON
            $stopwatch.Stop()
            
            $results += [PSCustomObject]@{
                Iteration = $i
                ElapsedMs = $stopwatch.ElapsedMilliseconds
                Success = $true
            }
        }
        catch {
            $stopwatch.Stop()
            $results += [PSCustomObject]@{
                Iteration = $i
                ElapsedMs = $stopwatch.ElapsedMilliseconds
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    Write-Progress -Activity "Performance Test" -Completed
    
    # Calculate statistics
    $successfulRuns = $results | Where-Object Success
    
    if ($successfulRuns.Count -gt 0) {
        $avgTime = ($successfulRuns.ElapsedMs | Measure-Object -Average).Average
        $minTime = ($successfulRuns.ElapsedMs | Measure-Object -Minimum).Minimum
        $maxTime = ($successfulRuns.ElapsedMs | Measure-Object -Maximum).Maximum
        
        Write-Host "`nPerformance Results:" -ForegroundColor Green
        Write-Host "  Average: $([Math]::Round($avgTime, 2))ms"
        Write-Host "  Minimum: ${minTime}ms"
        Write-Host "  Maximum: ${maxTime}ms"
        Write-Host "  Success Rate: $($successfulRuns.Count)/$Iterations"
        
        # Check if we meet the 36x speedup target (assuming baseline of 1000ms)
        $speedup = 1000 / $avgTime
        Write-Host "  Speedup Factor: $([Math]::Round($speedup, 1))x"
        
        if ($speedup -ge 36) {
            Write-Host "  Target Met: YES (36x speedup achieved)" -ForegroundColor Green
        } else {
            Write-Host "  Target Met: NO (36x speedup not achieved)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "All iterations failed!" -ForegroundColor Red
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-TreeSitter',
    'Install-TreeSitterParsers',
    'Invoke-TreeSitterParse',
    'ConvertFrom-TreeSitterCST',
    'Test-TreeSitterPerformance'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB9tN0gjuFawVCp
# O/dxpHJ2seUUPBP/nP2ETZw4DrCrwaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMwaiLxKkQTTBbm9SbHmSzRh
# i4lIeQPqV46kdXyeW0mkMA0GCSqGSIb3DQEBAQUABIIBAHfBiWWn6Xvs0jCXoJ1k
# C/mLURiHYt9/oXY/MsrnzrOZiw/3TdGzpyapJMFXUw5JPFwELNDcEFT1ZRK91qyh
# R+AjOlwo4YEc4YsJHzkisG2B3KJrfF3iuubhWNxhL7AqrJ2IiiRzdGkXgAlZUTDM
# PyTOnbLI3MAwczmVaewUmy8G5vXM1cczP+jJS6xNfIraIpZJ/Sl2fZoHGCVBs/VR
# /Spwg8dVVQzjhJ3Zk/eI02hVMpwlWbzXJP4mhWrFfaKSAUTTjjTtAm/OFeArndB+
# vFp8MNMiXfrGBlPEmMSteqBG73LK7BZbj+ivBalHq0VSuIAXZ1o69blHZDjBwWSp
# Cf4=
# SIG # End signature block
