# Debug syllable counting

# Load module
Import-Module .\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1 -Force -WarningAction SilentlyContinue

# Get the internal function
$module = Get-Module Unity-Claude-DocumentationQualityAssessment
& $module { 
    $testWords = @("simple", "comprehensive", "automation", "a", "the", "documentation", "artificial", "intelligence")
    
    foreach ($word in $testWords) {
        $syllables = Estimate-SyllableCount -Word $word
        Write-Host "$word : $syllables syllables"
    }
    
    Write-Host ""
    Write-Host "Testing full calculation:"
    $text = "This is a simple test."
    $cleanText = $text -replace '[^\w\s\.]', ' ' -replace '\s+', ' '
    $words = $cleanText -split '\s+' | Where-Object { $_ -match '\w' }
    $sentences = $cleanText -split '[.!?]+' | Where-Object { $_.Trim() -match '\w' }
    
    $totalSyllables = 0
    foreach ($word in $words) {
        $syl = Estimate-SyllableCount -Word $word
        Write-Host "  $word : $syl"
        $totalSyllables += $syl
    }
    
    Write-Host ""
    Write-Host "Total words: $($words.Count)"
    Write-Host "Total sentences: $($sentences.Count)"
    Write-Host "Total syllables: $totalSyllables"
    Write-Host "Words per sentence: $($words.Count / $sentences.Count)"
    Write-Host "Syllables per word: $($totalSyllables / $words.Count)"
    
    $wordsPerSentence = $words.Count / $sentences.Count
    $syllablesPerWord = $totalSyllables / $words.Count
    
    $fleschScore = 206.835 - (1.015 * $wordsPerSentence) - (84.6 * $syllablesPerWord)
    Write-Host "Flesch score: $fleschScore"
}