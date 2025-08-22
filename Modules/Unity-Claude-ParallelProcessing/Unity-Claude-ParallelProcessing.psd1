#
# Module manifest for module 'Unity-Claude-ParallelProcessing'
#
# Phase 1: Parallel Processing with Runspace Pools
# Week 1 Day 3-4: Thread Safety Infrastructure
# Generated on: 2025-08-20
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Unity-Claude-ParallelProcessing.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '7e4b8c2d-1f3a-4e9b-a2c7-8d5f3a1b4e6c'

# Author of this module
Author = 'Unity-Claude Automation System'

# Company or vendor of this module
CompanyName = 'Unity-Claude Automation'

# Copyright statement for this module
Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Parallel processing infrastructure for Unity-Claude automation system with thread-safe data structures, runspace pool management, and concurrent collections'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
DotNetFrameworkVersion = '4.5'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
    'Unity-Claude-ConcurrentCollections.psm1',
    '..\Unity-Claude-AutonomousAgent\Core\AgentLogging.psm1'
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    # Synchronized Data Structures
    'New-SynchronizedHashtable',
    'Get-SynchronizedValue',
    'Set-SynchronizedValue',
    'Remove-SynchronizedValue',
    'Lock-SynchronizedHashtable',
    'Unlock-SynchronizedHashtable',
    
    # Status Management
    'Initialize-ParallelStatusManager',
    'Get-ParallelStatus',
    'Set-ParallelStatus',
    'Update-ParallelStatus',
    'Clear-ParallelStatus',
    
    # Thread-Safe Operations
    'Invoke-ThreadSafeOperation',
    'Test-ThreadSafety',
    'Get-ThreadSafetyStats',
    
    # Concurrent Logging Infrastructure  
    'Initialize-ConcurrentLogging',
    'Write-ConcurrentLog',
    'Stop-ConcurrentLogging',
    
    # AgentLogging Functions (from NestedModule)
    'Write-AgentLog',
    'Initialize-AgentLogging',
    'Invoke-LogRotation',
    'Remove-OldLogFiles',
    'Get-AgentLogPath',
    'Get-AgentLogStatistics',
    'Clear-AgentLog'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Unity', 'Claude', 'Parallel', 'Threading', 'Runspace', 'Automation')

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Phase 1 Week 1: Thread safety infrastructure with synchronized hashtables and concurrent collections support'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7mi7va0vPozU61a1oQhrbbX0
# GF6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUqHnKxObCPyTosBZ5UjrcCvb0wkMwDQYJKoZIhvcNAQEBBQAEggEAj4oE
# 8ZdjtebHShiKERM4IC1S8EMn1Bjn1aY0Jvs0sg6cDjEmWFauflneySMGIBjIElKs
# NJ0SXGE0AA4io7ej2g+FlvDju/J8IoYow+8piq3UIeWr1U+GkcksUuHLKY4BkzZx
# ZAkC8r6rPlyig2vtl8qBSFF824Mg3bme87/dJvRMIuMp3ntpVHutc1cgU+AtHjev
# W6I0Ch3pXVBgFXKhT1bwDgQbqE4ahFtKqotIkOpj8PL88uMG9uGLzLlCQQ+61y6o
# mVjU1Mq4ARXzk66rBsOoB2PzICCFZNI/cwlLwjTbnT1ZbTplfMdtNhaACXBiYcG9
# 4QqRrfokH2maWpov9w==
# SIG # End signature block
