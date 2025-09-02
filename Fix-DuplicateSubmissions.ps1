# Fix-DuplicateSubmissions.ps1
# Fixes the CLIOrchestrator to prevent duplicate processing of JSON files

$filePath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1'

Write-Host "Fixing duplicate submission issue in OrchestrationManager.psm1..." -ForegroundColor Cyan

# Backup the current file
$backupPath = $filePath + '.backup_dupefix_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
Copy-Item $filePath $backupPath
Write-Host "Backed up to: $backupPath" -ForegroundColor Gray

# Read the current content
$content = Get-Content $filePath -Raw

# Add a script-scoped variable to track processed files at the top of the module
$moduleHeader = @'
# Unity-Claude CLIOrchestrator - Orchestration Manager Module
# Provides core orchestration functionality for Unity-Claude automation system

# Track processed files to prevent duplicate submissions
$script:ProcessedResponseFiles = @{}
$script:ProcessedResponseFilesCleanupTime = [DateTime]::MinValue

'@

# Function to get/manage processed files
$trackingFunctions = @'

function Get-ProcessedResponseFiles {
    <#
    .SYNOPSIS
        Gets the list of processed response files
    #>
    if (-not $script:ProcessedResponseFiles) {
        $script:ProcessedResponseFiles = @{}
    }
    
    # Clean up old entries every hour
    if ([DateTime]::Now -gt $script:ProcessedResponseFilesCleanupTime.AddHours(1)) {
        $cutoffTime = [DateTime]::Now.AddHours(-24)
        $keysToRemove = @()
        foreach ($key in $script:ProcessedResponseFiles.Keys) {
            if ($script:ProcessedResponseFiles[$key] -lt $cutoffTime) {
                $keysToRemove += $key
            }
        }
        foreach ($key in $keysToRemove) {
            $script:ProcessedResponseFiles.Remove($key)
        }
        $script:ProcessedResponseFilesCleanupTime = [DateTime]::Now
        if ($keysToRemove.Count -gt 0) {
            Write-Host "  Cleaned up $($keysToRemove.Count) old processed file entries" -ForegroundColor Gray
        }
    }
    
    return $script:ProcessedResponseFiles
}

function Test-ResponseFileProcessed {
    <#
    .SYNOPSIS
        Checks if a response file has already been processed
    #>
    param(
        [string]$FilePath
    )
    
    $processedFiles = Get-ProcessedResponseFiles
    $fileKey = [System.IO.Path]::GetFileName($FilePath)
    
    if ($processedFiles.ContainsKey($fileKey)) {
        # Check if file has been modified since last processing
        $fileInfo = Get-Item $FilePath -ErrorAction SilentlyContinue
        if ($fileInfo) {
            $lastProcessed = $processedFiles[$fileKey]
            if ($fileInfo.LastWriteTime -gt $lastProcessed) {
                # File has been modified, allow reprocessing
                return $false
            }
        }
        return $true
    }
    
    return $false
}

function Set-ResponseFileProcessed {
    <#
    .SYNOPSIS
        Marks a response file as processed
    #>
    param(
        [string]$FilePath
    )
    
    $processedFiles = Get-ProcessedResponseFiles
    $fileKey = [System.IO.Path]::GetFileName($FilePath)
    $processedFiles[$fileKey] = [DateTime]::Now
    Write-Host "    Marked as processed: $fileKey" -ForegroundColor DarkGray
}

'@

# Replace the content - add tracking at the beginning
if ($content -notmatch 'script:ProcessedResponseFiles') {
    # Add the module header and tracking functions after any existing comments but before the first function
    $firstFunctionIndex = $content.IndexOf('function Start-CLIOrchestration')
    if ($firstFunctionIndex -gt 0) {
        $beforeFunctions = $content.Substring(0, $firstFunctionIndex)
        $afterFunctions = $content.Substring($firstFunctionIndex)
        
        # Remove any existing module comments
        if ($beforeFunctions -match '^#.*?\n\n') {
            $beforeFunctions = ''
        }
        
        $newContent = $moduleHeader + "`n" + $trackingFunctions + "`n" + $afterFunctions
    } else {
        $newContent = $moduleHeader + "`n" + $trackingFunctions + "`n" + $content
    }
} else {
    Write-Host "Tracking already exists, updating Invoke-AutonomousDecisionMaking function only..." -ForegroundColor Yellow
    $newContent = $content
}

# Update the Invoke-AutonomousDecisionMaking function to check for processed files
$updatedFunction = @'
            foreach ($responseFile in $responseFiles) {
                try {
                    # Check if this file has already been processed
                    if (Test-ResponseFileProcessed -FilePath $responseFile.FullName) {
                        Write-Verbose "  Skipping already processed file: $($responseFile.Name)"
                        continue
                    }
                    
                    $content = Get-Content $responseFile.FullName -Raw | ConvertFrom-Json
                    
                    # Check for RECOMMENDATION field
                    if ($content.RESPONSE -and $content.RESPONSE -match "RECOMMENDATION:") {
                        $recommendationText = $content.RESPONSE
                        
                        Write-Host "  Submitting recommendation from $($responseFile.Name)..." -ForegroundColor Cyan
                        Write-Host "    $recommendationText" -ForegroundColor Gray
                        
                        # Submit to Claude
                        if (Get-Command Submit-ToClaudeViaTypeKeys -ErrorAction SilentlyContinue) {
                            $submissionResult = Submit-ToClaudeViaTypeKeys -PromptText $recommendationText
                            
                            if ($submissionResult) {
                                Write-Host "    Recommendation submitted successfully!" -ForegroundColor Green
                                
                                # Mark this file as processed
                                Set-ResponseFileProcessed -FilePath $responseFile.FullName
                                
                                $decisionResults.ActionsExecuted++
                                $decisionResults.ExecutedActions += @{
                                    Type = "RecommendationSubmission"
                                    Source = $responseFile.Name
                                    Text = $recommendationText
                                    Result = "Success"
                                    Timestamp = Get-Date
                                }
                                
                                # Only submit one recommendation per cycle
                                break
                            } else {
                                Write-Host "    Submission failed" -ForegroundColor Red
                            }
                        }
                    }
                } catch {
                    Write-Host "    Error processing file: $_" -ForegroundColor Red
                }
            }
'@

# Replace the foreach loop in Invoke-AutonomousDecisionMaking
$pattern = 'foreach \(\$responseFile in \$responseFiles\) \{[\s\S]*?\n            \}'
$newContent = $newContent -replace $pattern, $updatedFunction

# Add the new tracking functions to the export list
if ($newContent -match 'Export-ModuleMember -Function (.+)') {
    $existingExports = $matches[1]
    if ($existingExports -notmatch 'Get-ProcessedResponseFiles') {
        $newExports = $existingExports + ', Get-ProcessedResponseFiles, Test-ResponseFileProcessed, Set-ResponseFileProcessed'
        $newContent = $newContent -replace "Export-ModuleMember -Function .+", "Export-ModuleMember -Function $newExports"
    }
}

# Save the fixed content
$newContent | Set-Content $filePath -Encoding UTF8

Write-Host "Fix applied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "1. Added script-scoped ProcessedResponseFiles hashtable to track processed files"
Write-Host "2. Added Get-ProcessedResponseFiles function for managing the tracking"
Write-Host "3. Added Test-ResponseFileProcessed to check if file was already processed"
Write-Host "4. Added Set-ResponseFileProcessed to mark files as processed"
Write-Host "5. Updated Invoke-AutonomousDecisionMaking to skip already processed files"
Write-Host "6. Files are tracked for 24 hours before being eligible for reprocessing"
Write-Host ""
Write-Host "The CLIOrchestrator will now only process each JSON file once!" -ForegroundColor Green