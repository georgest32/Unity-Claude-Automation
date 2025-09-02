function Resolve-ConflictingRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations
    )
    
    Write-DecisionLog "Resolving conflicts among $($Recommendations.Count) recommendations" "DEBUG"
    
    if ($Recommendations.Count -le 1) {
        Write-DecisionLog "No conflicts to resolve - single or no recommendation" "DEBUG"
        return $Recommendations
    }
    
    # Group recommendations by type
    $groupedRecommendations = $Recommendations | Group-Object -Property Type
    $conflictingGroups = $groupedRecommendations | Where-Object { $_.Count -gt 1 }
    
    if ($conflictingGroups.Count -eq 0) {
        Write-DecisionLog "No conflicting recommendations found - all unique types" "DEBUG"
        return $Recommendations
    }
    
    $resolvedRecommendations = @()
    
    # Process each group
    foreach ($group in $groupedRecommendations) {
        if ($group.Count -eq 1) {
            # No conflict for this type
            $resolvedRecommendations += $group.Group[0]
        } else {
            # Resolve conflict by highest confidence
            Write-DecisionLog "Resolving conflict for type '$($group.Name)' - $($group.Count) recommendations" "INFO"
            
            $bestRecommendation = $group.Group | Sort-Object -Property Confidence -Descending | Select-Object -First 1
            $resolvedRecommendations += $bestRecommendation
            
            Write-DecisionLog "Selected recommendation with confidence $($bestRecommendation.Confidence) for type '$($group.Name)'" "INFO"
        }
    }
    
    # Ensure we don't have mutually exclusive recommendations
    $mutuallyExclusive = @{
        "FIX" = @("COMPILE", "TEST")
        "COMPILE" = @("FIX")
        "RESTART" = @("FIX", "COMPILE", "TEST")
    }
    
    $finalRecommendations = @()
    $excludedTypes = @()
    
    # Sort by priority (lower number = higher priority)
    $sortedRecommendations = $resolvedRecommendations | Sort-Object -Property {
        switch ($_.Type) {
            "ERROR" { 1 }
            "FIX" { 2 }
            "TEST" { 3 }
            "COMPILE" { 4 }
            "RESTART" { 5 }
            "COMPLETE" { 6 }
            "CONTINUE" { 7 }
            default { 10 }
        }
    }
    
    foreach ($rec in $sortedRecommendations) {
        if ($rec.Type -notin $excludedTypes) {
            $finalRecommendations += $rec
            
            # Exclude mutually exclusive types
            if ($mutuallyExclusive.ContainsKey($rec.Type)) {
                $excludedTypes += $mutuallyExclusive[$rec.Type]
                Write-DecisionLog "Excluding types $($mutuallyExclusive[$rec.Type] -join ', ') due to selection of $($rec.Type)" "DEBUG"
            }
        } else {
            Write-DecisionLog "Excluding recommendation type '$($rec.Type)' due to mutual exclusion" "DEBUG"
        }
    }
    
    Write-DecisionLog "Conflict resolution complete: $($finalRecommendations.Count) recommendations remaining" "SUCCESS"
    return $finalRecommendations
}