# Import-ResearchedPatterns.ps1
# Imports high-quality Unity debug patterns from online research
# Date: 2025-08-17

# Enable common parameters like -Verbose (don't declare a custom -Verbose)
[CmdletBinding()]
param(
    [switch]$DryRun
)

# Honor built-in -Verbose
if ($PSBoundParameters['Verbose']) { $VerbosePreference = 'Continue' }

Write-Host "`n=== UNITY DEBUG PATTERN IMPORT ===" -ForegroundColor Cyan
Write-Host "Importing researched Unity patterns into learning system" -ForegroundColor Yellow

# Idempotently add the local Modules folder to PSModulePath
$modulePath = Join-Path $PSScriptRoot 'Modules'
$sep = [System.IO.Path]::PathSeparator
$paths = ($env:PSModulePath -split [System.Text.RegularExpressions.Regex]::Escape($sep)) `
    | Where-Object { $_ -and $_.Trim() } `
    | ForEach-Object { [System.IO.Path]::GetFullPath($_) }
$normalizedModulePath = [System.IO.Path]::GetFullPath($modulePath)

if (-not ($paths -contains $normalizedModulePath)) {
    $env:PSModulePath = "$modulePath$sep$($env:PSModulePath)"
}

# Import the learning module (with error guard)
Write-Host "`nLoading Unity-Claude-Learning-Simple module..." -ForegroundColor Gray
try {
    Import-Module Unity-Claude-Learning-Simple -Force -ErrorAction Stop
} catch {
    Write-Host "❌ Failed to import module 'Unity-Claude-Learning-Simple'. $_" -ForegroundColor Red
    return
}

# Initialize storage (guarded)
Write-Host "Initializing pattern storage..." -ForegroundColor Gray
try {
    Initialize-LearningStorage -ErrorAction Stop | Out-Null
} catch {
    Write-Host "❌ Failed to initialize learning storage. $_" -ForegroundColor Red
    return
}

# Define high-quality patterns from research
$patterns = @(
    # === COMPILATION ERRORS ===
    @{
        Issue     = "CS0246: The type or namespace name 'GameObject' could not be found"
        ErrorType = "CompilationError"
        Cause     = "Missing UnityEngine namespace import"
        Fix       = "Add 'using UnityEngine;' at the top of the script"
        Category  = "Missing Namespace"
    },
    @{
        Issue     = "CS0246: The type or namespace name 'MonoBehaviour' could not be found"
        ErrorType = "CompilationError"
        Cause     = "Missing UnityEngine namespace import"
        Fix       = "Add 'using UnityEngine;' at the top of the script"
        Category  = "Missing Namespace"
    },
    @{
        Issue     = "CS0246: The type or namespace name 'Vector3' could not be found"
        ErrorType = "CompilationError"
        Cause     = "Missing UnityEngine namespace import"
        Fix       = "Add 'using UnityEngine;' at the top of the script"
        Category  = "Missing Namespace"
    },
    @{
        Issue     = "CS0246: The type or namespace name 'Rigidbody' could not be found"
        ErrorType = "CompilationError"
        Cause     = "Missing UnityEngine namespace import"
        Fix       = "Add 'using UnityEngine;' at the top of the script"
        Category  = "Missing Namespace"
    },
    @{
        Issue     = "CS0103: The name does not exist in the current context"
        ErrorType = "CompilationError"
        Cause     = "Variable not declared or out of scope"
        Fix       = "Declare the variable before use or check its scope"
        Category  = "Variable Scope"
    },
    @{
        Issue     = "CS1061: Type does not contain a definition for GetComponent"
        ErrorType = "CompilationError"
        Cause     = "Calling GetComponent on wrong object type"
        Fix       = "Ensure you're calling GetComponent on a GameObject or Component"
        Category  = "Method Not Found"
    },

    # === NULL REFERENCE EXCEPTIONS ===
    @{
        Issue     = "NullReferenceException: Object reference not set to an instance of an object"
        ErrorType = "RuntimeError"
        Cause     = "Attempting to use an uninitialized object reference"
        Fix       = "Add null check: if (object != null) before using the object"
        Category  = "Null Reference"
    },
    @{
        Issue     = "GameObject.Find returned null"
        ErrorType = "RuntimeError"
        Cause     = "GameObject.Find couldn't locate the object (inactive, missing, or typo)"
        Fix       = "Verify object exists and is active, consider using tags or Inspector references instead"
        Category  = "Object Not Found"
    },
    @{
        Issue     = "GetComponent returned null"
        ErrorType = "RuntimeError"
        Cause     = "Component doesn't exist on the GameObject"
        Fix       = "Add [RequireComponent(typeof(ComponentType))] or check if component exists before use"
        Category  = "Component Missing"
    },

    # === UNITY ANALYZER PATTERNS (UNT) ===
    @{
        Issue     = "UNT0001: Unity objects should not use null coalescing"
        ErrorType = "UnityAnalyzer"
        Cause     = "Using ?? operator with Unity objects can cause issues"
        Fix       = "Replace 'obj ?? fallback' with 'obj ? obj : fallback'"
        Category  = "Unity Best Practice"
    },
    @{
        Issue     = "UNT0003: Unity objects should use generic form of GetComponent"
        ErrorType = "UnityAnalyzer"
        Cause     = "Using non-generic GetComponent is slower"
        Fix       = "Use GetComponent<T>() instead of GetComponent(typeof(T))"
        Category  = "Performance"
    },
    @{
        Issue     = "UNT0004: Time.deltaTime usage with Update"
        ErrorType = "UnityAnalyzer"
        Cause     = "Incorrect time value in Update loop"
        Fix       = "Use Time.deltaTime in Update() for frame-independent movement"
        Category  = "Time Management"
    },
    @{
        Issue     = "UNT0005: FixedUpdate should use fixedDeltaTime"
        ErrorType = "UnityAnalyzer"
        Cause     = "Using deltaTime in FixedUpdate causes timing issues"
        Fix       = "Use Time.fixedDeltaTime in FixedUpdate() for physics calculations"
        Category  = "Time Management"
    },
    @{
        Issue     = "UNT0010: MonoBehaviour should not be created with 'new'"
        ErrorType = "UnityAnalyzer"
        Cause     = "Creating MonoBehaviour with new keyword doesn't attach to GameObject"
        Fix       = "Use gameObject.AddComponent<T>() instead of new T()"
        Category  = "Object Creation"
    },
    @{
        Issue     = "UNT0011: ScriptableObject should not be created with 'new'"
        ErrorType = "UnityAnalyzer"
        Cause     = "Creating ScriptableObject with new doesn't initialize properly"
        Fix       = "Use ScriptableObject.CreateInstance<T>() instead of new T()"
        Category  = "Object Creation"
    },
    @{
        Issue     = "UNT0017: SetPixels invocation is slow"
        ErrorType = "UnityAnalyzer"
        Cause     = "SetPixels is slower than SetPixels32"
        Fix       = "Use SetPixels32() instead of SetPixels() for better performance"
        Category  = "Performance"
    },
    @{
        Issue     = "UNT0018: System.Reflection features are slow"
        ErrorType = "UnityAnalyzer"
        Cause     = "Reflection in Update loops causes performance issues"
        Fix       = "Cache reflection results outside of Update methods"
        Category  = "Performance"
    },
    @{
        Issue     = "UNT0022: Inefficient position and rotation assignment"
        ErrorType = "UnityAnalyzer"
        Cause     = "Setting position and rotation separately is inefficient"
        Fix       = "Use Transform.SetPositionAndRotation(pos, rot) for single call"
        Category  = "Performance"
    },
    @{
        Issue     = "UNT0028: Use non-allocating physics APIs"
        ErrorType = "UnityAnalyzer"
        Cause     = "Physics.Raycast allocates garbage"
        Fix       = "Use Physics.RaycastNonAlloc() or similar non-allocating APIs"
        Category  = "Performance"
    },

    # === PERFORMANCE PATTERNS ===
    @{
        Issue     = "GetComponent called in Update loop"
        ErrorType = "PerformanceIssue"
        Cause     = "Repeated GetComponent calls are expensive"
        Fix       = "Cache component reference in Start/Awake: private Component comp; void Start() { comp = GetComponent<Component>(); }"
        Category  = "Caching"
    },
    @{
        Issue     = "GameObject.Find called repeatedly"
        ErrorType = "PerformanceIssue"
        Cause     = "GameObject.Find is expensive and should be cached"
        Fix       = "Cache the reference once in Start/Awake instead of calling Find repeatedly"
        Category  = "Caching"
    },
    @{
        Issue     = "Instantiate/Destroy called frequently"
        ErrorType = "PerformanceIssue"
        Cause     = "Creating and destroying objects causes GC spikes"
        Fix       = "Implement object pooling: pre-instantiate objects and reuse them"
        Category  = "Object Pooling"
    },
    @{
        Issue     = "Transform component accessed repeatedly"
        ErrorType = "PerformanceIssue"
        Cause     = "Accessing transform property has overhead"
        Fix       = "Cache Transform reference: private Transform t; void Start() { t = transform; }"
        Category  = "Caching"
    },

    # === COMMON UNITY MISTAKES ===
    @{
        Issue     = "Comparing tags with == operator"
        ErrorType = "CodeSmell"
        Cause     = "String comparison with == is inefficient"
        Fix       = "Use CompareTag('TagName') instead of tag == 'TagName'"
        Category  = "Best Practice"
    },
    @{
        Issue     = "Using Resources.Load in Update"
        ErrorType = "PerformanceIssue"
        Cause     = "Loading resources every frame is extremely slow"
        Fix       = "Load resources once in Start/Awake and cache the reference"
        Category  = "Resource Management"
    },
    @{
        Issue     = "Not using StringBuilder for string concatenation"
        ErrorType = "PerformanceIssue"
        Cause     = "String concatenation in loops creates garbage"
        Fix       = "Use System.Text.StringBuilder for string operations in loops"
        Category  = "Memory Management"
    }
)

Write-Host "`nPatterns to import: $($patterns.Count)" -ForegroundColor Green

$importedCount = 0
$skippedCount  = 0
$categories    = @{}

foreach ($pattern in $patterns) {
    Write-Host "`nProcessing: $($pattern.Issue)" -ForegroundColor Yellow

    if (-not $DryRun) {
        try {
            # Build context hashtable
            $context = @{
                Category = $pattern.Category
                Cause    = $pattern.Cause
            }

            # Use splatting to avoid fragile line continuations
            $addParams = @{
                ErrorMessage = $pattern.Issue
                ErrorType    = $pattern.ErrorType
                Fix          = $pattern.Fix
                Context      = $context
            }

            $patternId = Add-ErrorPattern @addParams

            if ($patternId) {
                Write-Host "  ✅ Imported successfully (ID: $patternId)" -ForegroundColor Green
                Write-Verbose "  Category: $($pattern.Category)"
                Write-Verbose "  Type: $($pattern.ErrorType)"
                $importedCount++

                # Track categories
                if (-not $categories.ContainsKey($pattern.Category)) {
                    $categories[$pattern.Category] = 0
                }
                $categories[$pattern.Category]++
            } else {
                Write-Host "  ⚠️ Pattern may already exist" -ForegroundColor Yellow
                $skippedCount++
            }
        } catch {
            Write-Host "  ❌ Error importing: $($_.Exception.Message)" -ForegroundColor Red
            $skippedCount++
        }
    } else {
        Write-Host "  [DRY RUN] Would import this pattern" -ForegroundColor Cyan
        Write-Host "    Category: $($pattern.Category)" -ForegroundColor Gray
        Write-Host "    Type: $($pattern.ErrorType)" -ForegroundColor Gray
        Write-Host "    Fix: $($pattern.Fix)" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n=== IMPORT SUMMARY ===" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN - No patterns were actually imported" -ForegroundColor Yellow
    Write-Host "Patterns that would be imported: $($patterns.Count)" -ForegroundColor Gray
} else {
    Write-Host "Successfully imported: $importedCount patterns" -ForegroundColor Green
    if ($skippedCount -gt 0) {
        Write-Host "Skipped/Failed: $skippedCount patterns" -ForegroundColor Yellow
    }

    # Show categories
    if ($categories.Count -gt 0) {
        Write-Host "`nPatterns by Category:" -ForegroundColor Cyan
        foreach ($category in ($categories.Keys | Sort-Object)) {
            Write-Host "  $category : $($categories[$category])" -ForegroundColor Gray
        }
    }

    # Show current pattern count (robust JSON handling with try/catch present)
    try {
        $config = Get-LearningConfig -ErrorAction Stop
        if ($config -and $config.PatternsFile -and (Test-Path $config.PatternsFile)) {
            $jsonText = Get-Content $config.PatternsFile -Raw
            $jsonContent = if ($jsonText -and $jsonText.Trim()) {
                try { $jsonText | ConvertFrom-Json } catch { @() }
            } else {
                @()
            }
            $totalPatterns = @($jsonContent).Count
            Write-Host "`nTotal patterns in database: $totalPatterns" -ForegroundColor Green
        } else {
            Write-Host "`n(No patterns file found to summarize.)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "`n⚠️ Could not read learning config or patterns file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Test pattern matching with common Unity errors" -ForegroundColor Gray
Write-Host "2. Run Debug-FuzzyMatching.ps1 to verify pattern retrieval" -ForegroundColor Gray
Write-Host "3. Begin Phase 1 & 2 integration" -ForegroundColor Gray
Write-Host ""

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjZIOBfQVPqgBsLMnNuc33k00
# JFegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU9PXc3bENVjcOq06UlkPEBLoOouEwDQYJKoZIhvcNAQEBBQAEggEAgOsr
# eRk7LkAF8fEZeo79lMDN4NDrhJZ15oOM11x0ig/yECX4zbDGxnZmPaP4+RnDYyDs
# coAEmSx9IfPrtxnYcncmPk/DtUwPUETqe63i6RZrNQK0rnlN2wT3XFV7m/1NO2JM
# zaskxMHXq0BQpAyNVnM2HYg4LDcsQFkCDb3MHuX4Wpnic/hSoMqECxeJipeEwDdY
# rWxupJVH9eCEalo9AmchJ1nHOHwZHXH03XS49al62vnxco0F6qh4HVsmg7s0Mmwr
# 0J7VbzCbH73SjdOE0XcIB/ya0xV/eMszh93i384F9q0YiZK5e05aARJQ2ZTqIdBT
# Y6XGJ1EBu+wc1OufKA==
# SIG # End signature block
