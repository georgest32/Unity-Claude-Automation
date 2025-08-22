<# 
unity_claude_automation.ps1 (rev6)
Project: Sound-and-Shoal (Unity 2021.1.14f1)

Major changes vs rev4/5:
- Single-session recompile using Assets/Editor/Automation/AutoRecompile.cs:
  * Forces a guaranteed script compile by toggling a unique define.
  * Survives domain reload via SessionState + InitializeOnLoadMethod.
  * Exits the Editor itself when the compile wave completes (exit 0) or times out (exit 124).
- PS 5.1–safe everywhere (no ??, no -Raw -Tail combos).
- Stricter success/fail detection using both exported console and Editor.log.
- Detailed, timestamped logs per step into AutomationLogs\automation_YYYYMMDD.log.
#>

[CmdletBinding()]
param(
  [switch]$Loop,
  [switch]$RunOnce,

  [ValidateSet('Continue','Fix','Explain','Triage','Plan','Review','Debugging','Custom')]
  [string]$PromptType = 'Continue',

  [string]$AdditionalInstructions,

  [switch]$NeedMoreSpec,
  [switch]$SelfDiagnoseNow,

  [string]$Model = 'sonnet-3.5',
  [string]$ClaudeExe = 'claude',

  [string]$UnityExe = 'C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe',
  [string]$ProjectPath = 'C:\UnityProjects\Sound-and-Shoal',
  [string]$BoilerplatePath = 'C:\UnityProjects\Sound-and-Shoal\CLAUDE_PROMPT_DIRECTIVES.txt',

  [string]$ConsoleDumpPath = 'C:\UnityProjects\Sound-and-Shoal\ConsoleLogs.txt',
  [string]$SplitOutDir = 'C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\ConsoleLogs_Split',

  [int]$UnityRecompileTimeoutSec = 300,
  [int]$UnityShortTimeoutSec = 90,
  [int]$UnityLongTimeoutSec = 300,
  [int]$ClaudeTimeoutSec = 3600,

  [switch]$QuietLicenseCheck,

  # Control installing the Editor watcher script
  [switch]$SkipInstallAutoRecompile,
  [switch]$ReinstallAutoRecompile
)

# --- Globals -------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$script:StartTime   = Get-Date
$script:LogDir      = Join-Path $ProjectPath 'AutomationLogs'
$script:EditorLogPath = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'
$script:CycleIndex  = 0
$script:FailedFixStreak = 0
$script:MaxFailedFixBeforeReview = 5

# Where we install the persistent Editor script that forces & watches compilation
$script:AutoEditorDir  = Join-Path $ProjectPath 'Assets\Editor\Automation'
$script:AutoEditorFile = Join-Path $script:AutoEditorDir 'AutoRecompile.cs'

# --- Logging -------------------------------------------------------------------
function Write-Log {
  param(
    [string]$Message, 
    [ValidateSet('INFO','WARN','ERROR','OK','DEBUG')][string]$Level='INFO'
  )
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $line = "[$ts] [$Level] $Message"

  switch ($Level) {
    'ERROR' { Write-Host $line -ForegroundColor Red }
    'WARN'  { Write-Host $line -ForegroundColor Yellow }
    'OK'    { Write-Host $line -ForegroundColor Green }
    'DEBUG' { Write-Host $line -ForegroundColor DarkGray }
    default { Write-Host $line }
  }

  try {
    New-Item -ItemType Directory -Force -Path $script:LogDir | Out-Null
    $f = Join-Path $script:LogDir ("automation_{0}.log" -f (Get-Date -Format 'yyyyMMdd'))
    Add-Content -Path $f -Value $line -ErrorAction SilentlyContinue
  } catch {}
}

function Get-FileTailAsString {
  param([string]$Path, [int]$Tail = 2000)
  if (-not $Path -or -not (Test-Path $Path)) { return "" }
  try {
    $lines = Get-Content -Path $Path -ErrorAction SilentlyContinue
    if ($null -eq $lines) { return "" }
    $count = $lines.Count
    if ($count -is [int] -and $count -gt 0) {
      $start = [Math]::Max(0, $count - $Tail)
      $slice = $lines[$start..($count-1)]
      return ($slice -join "`n")
    } else {
      return ($lines -join "`n")
    }
  } catch { return "" }
}

# Self-audit for -Raw -Tail misuse (safe if we lack a script path)
function Assert-NoRawTailMisuse {
  try {
    $thisPath = $null
    if ($PSBoundParameters.ContainsKey('PSCommandPath')) { $thisPath = $PSCommandPath }
    if (-not $thisPath -and $PSCommandPath) { $thisPath = $PSCommandPath }
    if (-not $thisPath -and $MyInvocation -and $MyInvocation.MyCommand) { $thisPath = $MyInvocation.MyCommand.Path }
    if (-not $thisPath -or -not (Test-Path $thisPath)) { return }

    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($thisPath, [ref]$tokens, [ref]$errors)
    $badUsages = @()
    foreach ($cmd in $ast.FindAll({param($node) $node -is [System.Management.Automation.Language.CommandAst]}, $true)) {
      $name = $cmd.GetCommandName()
      if ($name -eq 'Get-Content') {
        $raw = $false; $tail = $false
        foreach ($el in $cmd.CommandElements) {
          if ($el -is [System.Management.Automation.Language.CommandParameterAst]) {
            $pname = $el.ParameterName
            if ($pname -eq 'Raw') { $raw = $true }
            if ($pname -eq 'Tail') { $tail = $true }
          }
        }
        if ($raw -and $tail) { $badUsages += $cmd.Extent.Text }
      }
    }
    if ($badUsages.Count -gt 0) {
      foreach ($line in $badUsages) { Write-Log ("Preflight: Invalid Get-Content usage: {0}" -f $line) 'ERROR' }
      throw "Preflight: failing due to -Raw and -Tail used together."
    }
  } catch { throw }
}

# --- Editor-side AutoRecompile.cs source --------------------------------------
$script:AutoRecompileCs = @'
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Compilation;

public static class AutoRecompile
{
    private const string kFlag = "AUTO_WAIT_FOR_COMPILE";
    private const string kTokenPrefix = "AUTO_FORCE_RECOMPILE_";

    // CLI entry point: -executeMethod AutoRecompile.Kickoff
    public static void Kickoff()
    {
        // Mark session as expecting a compile and exit afterwards
        SessionState.SetBool(kFlag, true);

        // Force a guaranteed recompile by toggling a unique define token.
        var grp = EditorUserBuildSettings.selectedBuildTargetGroup;
        var defines = PlayerSettings.GetScriptingDefineSymbolsForGroup(grp) ?? string.Empty;

        // Remove any stale tokens from prior runs to avoid indefinite growth
        var cleaned = RemoveOldTokens(defines);

        var token = kTokenPrefix + System.DateTime.UtcNow.Ticks;
        var newDefines = string.IsNullOrEmpty(cleaned) ? token : (cleaned + ";" + token);
        PlayerSettings.SetScriptingDefineSymbolsForGroup(grp, newDefines);

        // Ensure changes are seen even if Auto Refresh is off
        AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);

        // Also request compilation explicitly (redundant but harmless)
        CompilationPipeline.RequestScriptCompilation();

        // Do NOT quit here; a domain reload will interrupt this method shortly.
        // Our watcher (below) is reinstalled after reload and will exit the editor when compile completes.
    }

    private static string RemoveOldTokens(string defines)
    {
        if (string.IsNullOrEmpty(defines)) return string.Empty;
        var parts = defines.Split(';');
        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        for (int i = 0; i < parts.Length; i++)
        {
            var p = parts[i].Trim();
            if (p.Length == 0) continue;
            if (p.StartsWith(kTokenPrefix)) continue; // drop old tokens
            if (sb.Length > 0) sb.Append(';');
            sb.Append(p);
        }
        return sb.ToString();
    }

    [InitializeOnLoadMethod]
    private static void InstallWatcher()
    {
        EditorApplication.update -= Watch;
        EditorApplication.update += Watch;
    }

    private static double sStart;
    private static bool sSawCompiling;

    private static void Watch()
    {
        if (!SessionState.GetBool(kFlag, false)) return;

        if (sStart <= 0) sStart = EditorApplication.timeSinceStartup;

        // Detect the wave: not compiling -> compiling -> not compiling
        if (EditorApplication.isCompiling) sSawCompiling = true;

        // Finished a compilation cycle?
        if (!EditorApplication.isCompiling && sSawCompiling)
        {
            SessionState.EraseBool(kFlag);
            EditorApplication.Exit(0); // success
        }

        // Safety timeout (~5 minutes)
        if (EditorApplication.timeSinceStartup - sStart > 300.0)
        {
            SessionState.EraseBool(kFlag);
            EditorApplication.Exit(124); // timeout
        }
    }
}
#endif
'@

# --- Install/verify the Editor watcher script ---------------------------------
function Install-AutoRecompile {
  if ($SkipInstallAutoRecompile) { 
    Write-Log "InstallAutoRecompile: skipped by flag."
    return 
  }
  New-Item -ItemType Directory -Force -Path $script:AutoEditorDir | Out-Null

  $writeIt = $true
  if ((Test-Path $script:AutoEditorFile) -and -not $ReinstallAutoRecompile) {
    try {
      $existing = (Get-Content -Path $script:AutoEditorFile -ErrorAction Stop) -join "`n"
      $writeIt = ($existing -ne $script:AutoRecompileCs)
    } catch { $writeIt = $true }
  }

  if ($writeIt) {
    Set-Content -Path $script:AutoEditorFile -Value $script:AutoRecompileCs -Encoding UTF8
    Write-Log ("InstallAutoRecompile: wrote {0}" -f $script:AutoEditorFile) 'OK'
  } else {
    Write-Log "InstallAutoRecompile: already up-to-date." 'OK'
  }
}

# --- Preflight -----------------------------------------------------------------
function Preflight {
  Write-Log "Preflight: starting checks..."
  if (-not (Test-Path $UnityExe))    { throw "Unity not found: $UnityExe" }
  if (-not (Test-Path $ProjectPath)) { throw "Project not found: $ProjectPath" }
  if (-not (Test-Path $BoilerplatePath)) { Write-Log "Boilerplate not found (continuing without it)." 'WARN' }

  Assert-NoRawTailMisuse

  $claudeCmd = Get-Command $ClaudeExe -ErrorAction SilentlyContinue
  if (-not $claudeCmd) { Write-Log "Claude CLI not found on PATH (continuing; fixes will be skipped)." 'WARN' }

  if (-not $env:ANTHROPIC_API_KEY) { Write-Log "ANTHROPIC_API_KEY not set (continuing; fixes will be skipped)." 'WARN' }

  if (-not $QuietLicenseCheck) {
    $licenseHelper = Join-Path $ProjectPath 'unity_license_automation.ps1'
    if (Test-Path $licenseHelper) {
      try { & $licenseHelper -Mode Check | Out-Null } catch { Write-Log "License preflight: helper not OK (continuing)." 'WARN' }
    }
  }

  $apiKeyShort = 'unset'
  if ($env:ANTHROPIC_API_KEY -and $env:ANTHROPIC_API_KEY.Length -ge 6) { $apiKeyShort = $env:ANTHROPIC_API_KEY.Substring(0,6) }
  Write-Log ("[OK] Preflight: Unity OK, Project OK, CLI={0}, API key prefix: {1}..." -f ($(if ($claudeCmd) {'yes'} else {'no'})),$apiKeyShort) 'OK'
}

# --- Unity invocation helper ---------------------------------------------------
function Invoke-Unity {
  param(
    [string[]]$Args,
    [int]$TimeoutSec = 120,
    [string]$LogLabel = ''
  )
  $snap = Join-Path $script:LogDir ("unity_{0}_{1}.log" -f ($LogLabel -replace '\s',''), (Get-Date -Format 'yyyyMMdd_HHmmss'))
  $finalArgs = @('-batchmode','-nographics','-projectPath',('"{0}"' -f $ProjectPath)) + $Args + @('-logFile',('"{0}"' -f $snap))

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $UnityExe
  $psi.Arguments = ($finalArgs -join ' ')
  $psi.RedirectStandardOutput = $false
  $psi.RedirectStandardError = $false
  $psi.UseShellExecute = $true
  $psi.CreateNoWindow = $true

  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi

  Write-Log ("Invoke-Unity[{0}]: {1} {2}" -f $LogLabel,$psi.FileName,$psi.Arguments) 'DEBUG'
  [void]$p.Start()
  if (-not $p.WaitForExit($TimeoutSec * 1000)) {
    try { $p.Kill() } catch {}
    Write-Log ("Invoke-Unity[{0}]: timeout after {1}s; killed. Log={2}" -f $LogLabel,$TimeoutSec,$snap) 'ERROR'
    return [pscustomobject]@{ ExitCode=124; Log=$snap }
  }

  Write-Log ("Invoke-Unity[{0}]: exit={1}, log={2}" -f $LogLabel,$p.ExitCode,$snap)
  return [pscustomobject]@{ ExitCode=$p.ExitCode; Log=$snap }
}

# --- Export console (reflection with fallback to Editor.log) -------------------
$script:ExportConsoleCs = @'
using System;
using System.IO;
using System.Reflection;
using UnityEditor;
public static class __Auto_ExportConsole {
  public static void Run() {
    string outPath = Environment.GetEnvironmentVariable("UNITY_CONSOLE_DUMP_PATH");
    if (string.IsNullOrEmpty(outPath)) outPath = "ConsoleLogs.txt";
    try {
      var logEntriesType = Type.GetType("UnityEditor.LogEntries, UnityEditor.dll");
      if (logEntriesType != null) {
        var startGettingEntries = logEntriesType.GetMethod("StartGettingEntries", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        var endGettingEntries = logEntriesType.GetMethod("EndGettingEntries", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        var getCount = logEntriesType.GetMethod("GetCount", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        var getEntryInternal = logEntriesType.GetMethod("GetEntryInternal", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        if (startGettingEntries != null && getCount != null && getEntryInternal != null) {
          startGettingEntries.Invoke(null, null);
          int count = (int)getCount.Invoke(null, null);
          using (var sw = new StreamWriter(outPath, false)) {
            for (int i = 0; i < count; i++) {
              object[] args = new object[] { i, null };
              getEntryInternal.Invoke(null, args);
              var entry = args[1];
              if (entry != null) {
                var condition = entry.GetType().GetField("condition").GetValue(entry) as string;
                sw.WriteLine(condition);
              }
            }
          }
          if (endGettingEntries != null) endGettingEntries.Invoke(null, null);
          EditorApplication.Exit(0);
          return;
        }
      }
    } catch {}
    var editorLog = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData) + @"\Unity\Editor\Editor.log";
    try {
      if (File.Exists(editorLog)) {
        File.Copy(editorLog, outPath, true);
      } else {
        File.WriteAllText(outPath, "Editor.log not found: " + editorLog);
      }
    } catch (Exception ex) {
      File.WriteAllText(outPath, "Failed to export console: " + ex.Message);
    }
    EditorApplication.Exit(0);
  }
}
'@

function New-TempEditorScript { 
  param([string]$FileName,[string]$Content)
  $tmpDir = Join-Path $ProjectPath 'Assets\Editor\__AutomationTemp__'
  New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
  $path = Join-Path $tmpDir $FileName
  Set-Content -Path $path -Value $Content -Encoding UTF8
  Write-Log ("TempEditorScript: wrote {0}" -f $FileName)
  return $path
}
function Remove-TempEditorScript { 
  param([string]$FileName)
  $tmpDir = Join-Path $ProjectPath 'Assets\Editor\__AutomationTemp__'
  $path = Join-Path $tmpDir $FileName
  if (Test-Path $path) { Remove-Item -Path $path -Force -ErrorAction SilentlyContinue; Write-Log ("TempEditorScript: cleaned {0}" -f $FileName) }
}

function Export-Console {
  Write-Log ("Step: Export Unity Console -> {0}" -f $ConsoleDumpPath)
  $env:UNITY_CONSOLE_DUMP_PATH = $ConsoleDumpPath
  $cs = New-TempEditorScript -FileName 'ExportConsole.cs' -Content $script:ExportConsoleCs
  $res = Invoke-Unity -Args @('-executeMethod','__Auto_ExportConsole.Run','-quit') -TimeoutSec $UnityLongTimeoutSec -LogLabel 'ExportConsole'
  Remove-TempEditorScript -FileName 'ExportConsole.cs'
  if ($res.ExitCode -ne 0) { Write-Log "ExportConsole: non-zero exit (continuing; file may still exist)" 'WARN' }
  return (Test-Path $ConsoleDumpPath)
}

# --- Force recompile (single Unity session; no -quit) --------------------------
function Step-ForceRecompile {
  Write-Log "Step: Force recompile (single-session watcher)..."
  Install-AutoRecompile
  # IMPORTANT: no -quit here; AutoRecompile watcher will exit Editor when compile completes
  $res = Invoke-Unity -Args @('-executeMethod','AutoRecompile.Kickoff') -TimeoutSec $UnityRecompileTimeoutSec -LogLabel 'ForceRecompile'
  if ($res.ExitCode -eq 0) {
    Write-Log "ForceRecompile: compile wave completed (exit 0)." 'OK'
  } elseif ($res.ExitCode -eq 124) {
    Write-Log "ForceRecompile: timeout waiting for compile wave (exit 124)." 'ERROR'
  } else {
    Write-Log ("ForceRecompile: non-zero exit code {0}" -f $res.ExitCode) 'WARN'
  }
  return $res.ExitCode
}

# --- Error parsing -------------------------------------------------------------
function Parse-ErrorsFromText {
  param([string]$text)
  if (-not $text) {
    return @{ HasErrors=$false; ErrorCount=0; HasTestSummary=$false; AllTestsPassed=$false }
  }
  $hasCs = ($text -match '(?mi)^\s*error\s+CS\d{3,5}\s*:') -or ($text -match '(?mi)\bCS\d{3,5}\b')
  $hasScriptsHaveErrors = ($text -match '(?mi)^\s*Scripts have compiler errors\.')
  $hasCompilationFailed = ($text -match '(?mi)\bCompilation failed\b|\bCompilerUtility: Compilation failed\b')
  $hasUnhandled = ($text -match '(?mi)\bUnhandled exception\b|\bNullReferenceException\b|\bIndexOutOfRangeException\b')
  $hasRoslynCrash = ($text -match '(?mi)\bRoslyn\b.*\bcrash\b|\bMicrosoft\.CodeAnalysis\b.*\bexception\b')
  $hasExit2 = ($text -match '(?mi)\bExitCode:\s*2\b')

  $err = ($hasCs -or $hasScriptsHaveErrors -or $hasCompilationFailed -or $hasUnhandled -or $hasRoslynCrash -or $hasExit2)
  $csCount = ([regex]::Matches($text,'(?mi)\berror\s+CS\d{3,5}\s*:')).Count

  # (Optional) simple test summary parse
  $hasTestSummary = ($text -match '(?mi)Passed:\s*\d+.*Failed:\s*\d+')
  $allPassed = $false
  if ($hasTestSummary) {
    $m = [regex]::Match($text,'(?mi)Passed:\s*(\d+).*Failed:\s*(\d+)')
    if ($m.Success) {
      $p = [int]$m.Groups[1].Value; $f = [int]$m.Groups[2].Value
      if ($f -eq 0 -and $p -gt 0) { $allPassed = $true }
    }
  }
  return @{ HasErrors=$err; ErrorCount=$csCount; HasTestSummary=$hasTestSummary; AllTestsPassed=$allPassed }
}

function Parse-Console {
  Write-Log "Step: Parse console for errors..."
  $text = ""
  if (Test-Path $ConsoleDumpPath) {
    $text = (Get-Content -Path $ConsoleDumpPath -ErrorAction SilentlyContinue) -join "`n"
  } else {
    Write-Log "ParseConsole: Console dump not found; using Editor.log tail as fallback." 'WARN'
    $text = Get-FileTailAsString -Path $script:EditorLogPath -Tail 2000
  }
  $r = Parse-ErrorsFromText -text $text

  # Also check Editor.log tail for "Scripts have compiler errors." & "Compilation failed"
  $tail = Get-FileTailAsString -Path $script:EditorLogPath -Tail 1500
  if (($tail -match '(?mi)^\s*Scripts have compiler errors\.') -or ($tail -match '(?mi)\bCompilation failed\b')) {
    $r.HasErrors = $true
  }

  Write-Log ("ParseConsole: HasErrors={0} CSCount={1} HasTestSummary={2} AllTestsPassed={3}" -f $r.HasErrors,$r.ErrorCount,$r.HasTestSummary,$r.AllTestsPassed)
  return $r
}

# --- Claude integration (optional if CLI/API key present) ---------------------
function Build-Prompt {
  param([string]$PromptType,[string]$Additional,[switch]$NeedMoreSpec)
  $boiler = ""
  try { if (Test-Path $BoilerplatePath) { $boiler = (Get-Content -Path $BoilerplatePath -ErrorAction Stop) -join "`n" } } catch {}
  $header = ("[prompt-type]: {0}`n" -f $PromptType)

  $notes = ""
  if (Test-Path $ConsoleDumpPath) { $notes += "Console logs dumped to: $ConsoleDumpPath`n" }
  if ($NeedMoreSpec) { $notes += "User indicates ambiguity; prioritize asking for missing specs.`n" }

  $tail = Get-FileTailAsString -Path $script:EditorLogPath -Tail 400
  $prompt = $boiler + "`n" + $header + $notes + "`n" + "Recent Editor.log tail:`n" + $tail
  if ($Additional) { $prompt += "`nAdditionalNotes:`n" + $Additional }

  $bytes = [System.Text.Encoding]::UTF8.GetByteCount($prompt)
  Write-Log ("BuildPrompt: type={0} bytes={1}" -f $PromptType,$bytes)
  return $prompt
}

function Invoke-Claude {
  param([string]$Prompt,[string]$Model,[int]$TimeoutSec = 3600)
  $claudeCmd = Get-Command $ClaudeExe -ErrorAction SilentlyContinue
  if (-not $claudeCmd -or -not $env:ANTHROPIC_API_KEY) {
    return @{ Ok=$false; Text=''; RecommendationType=''; RecommendationDetails=''; StdoutPath='' }
  }

  Write-Log "Step: Invoke Claude..."
  $outPath = Join-Path $script:LogDir ("claude_response_{0}.json" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
  $rawOutPath = Join-Path $script:LogDir ("claude_response_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $ClaudeExe
  $psi.Arguments = "--print --output-format json --model `"$Model`""
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true

  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  [void]$p.Start()

  $sw = $p.StandardInput
  $sw.Write($Prompt)
  $sw.Close()

  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  [void]$p.WaitForExit($TimeoutSec * 1000)

  Set-Content -Path $outPath -Value $stdout -Encoding UTF8
  Set-Content -Path $rawOutPath -Value $stderr -Encoding UTF8

  $text = ""
  try {
    $json = $stdout | ConvertFrom-Json -ErrorAction Stop
    if ($json -and $json.message) { $text = [string]$json.message } else { $text = $stdout }
  } catch { $text = $stdout }

  Set-Content -Path ($rawOutPath -replace '\.txt$','_stdout.txt') -Value $text -Encoding UTF8

  $recType = ''
  $recDetails = ''
  $m = [regex]::Match($text, '(?mi)^\s*RECOMMENDED:\s*([A-Z\- ]+)\s*-\s*(.+)$')
  if ($m.Success) { $recType = $m.Groups[1].Value.Trim(); $recDetails = $m.Groups[2].Value.Trim() }

  if ($recType -ne '') { Write-Log ("Claude: Recommendation -> {0} - {1}" -f $recType,$recDetails) }

  return @{ Ok=$true; Text=$text; RecommendationType=$recType; RecommendationDetails=$recDetails; StdoutPath=$outPath }
}

function Extract-TestNamesFromRecommendation {
  param([string]$Details)
  if (-not $Details) { return @() }
  $names = New-Object System.Collections.ArrayList
  $quoted = [regex]::Matches($Details, '"([^"]+)"')
  if ($quoted.Count -gt 0) {
    foreach ($q in $quoted) {
      $leaf = $q.Groups[1].Value
      $parts = $leaf -split '->'
      $clean = $parts[$parts.Length-1].Trim()
      [void]$names.Add($clean)
    }
  }
  return ,$names.ToArray()
}

function Run-UnityTests {
  param([string[]]$Names)
  if (-not $Names -or $Names.Count -eq 0) { return $true }
  Write-Log ("Run-UnityTests: {0}" -f ($Names -join ', '))
  # Wire in your test runner here if needed
  return $true
}

# --- Health check orchestration ------------------------------------------------
function Check-CompileHealth {
  # 1) Force a recompile in a single session (survives reload)
  $ec = Step-ForceRecompile
  if ($ec -eq 124) {
    return @{ HasErrors=$true; ErrorCount=0; HasTestSummary=$false; AllTestsPassed=$false }
  }

  # 2) Export console
  [void](Export-Console)

  # 3) Parse logs
  $parse = Parse-Console
  return $parse
}

# --- Main ----------------------------------------------------------------------
try {
  Preflight
  if ($Loop) { Write-Log "Mode: Loop - press Ctrl+C to stop." } else { Write-Log "Mode: RunOnce" }

  do {
    $script:CycleIndex = $script:CycleIndex + 1
    Write-Log ("Cycle: start (#{0})" -f $script:CycleIndex)

    $parse = Check-CompileHealth

    if (-not $parse.HasErrors) {
      Write-Log "Compile health: CLEAN (no compiler errors detected)." 'OK'
      if ($RunOnce -and -not $Loop) {
        Write-Log "RunOnce mode: exiting successfully." 'OK'
        break
      } else {
        Start-Sleep -Seconds 2
        continue
      }
    }

    Write-Log ("Compile health: ERRORS detected (CSCount={0})" -f $parse.ErrorCount) 'WARN'

    $decided = $PromptType
    if ($script:FailedFixStreak -ge $script:MaxFailedFixBeforeReview -and $PromptType -ne 'Review') {
      $decided = 'Review'
    } elseif ($PromptType -eq 'Continue' -and $parse.HasErrors) {
      $decided = 'Debugging'
    }
    Write-Log ("Prompt type -> {0}" -f $decided)

    $prompt = Build-Prompt -PromptType $decided -Additional $AdditionalInstructions -NeedMoreSpec:$NeedMoreSpec
    $promptPath = Join-Path $script:LogDir ("prompt_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    Set-Content -Path $promptPath -Value $prompt -Encoding UTF8
    Write-Log ("Saved prompt -> {0}" -f $promptPath)

    $claude = Invoke-Claude -Prompt $prompt -Model $Model -TimeoutSec $ClaudeTimeoutSec
    if (-not $claude.Ok) {
      Write-Log "Claude invocation skipped/failed; will retry next cycle." 'WARN'
      Write-Log "Cycle: end"
      Start-Sleep -Seconds 2
      continue
    }

    if ($claude.RecommendationType -match '(?i)TEST' -and -not $parse.HasErrors) {
      $testNames = Extract-TestNamesFromRecommendation -Details $claude.RecommendationDetails
      if ($testNames.Count -gt 0) {
        $testsOk = Run-UnityTests -Names $testNames
        if (-not $testsOk) { Write-Log "Targeted tests failed; forcing next prompt to Debugging" 'WARN'; $PromptType = 'Debugging' }
      } else {
        Write-Log "TEST recommended, but no test names parsed." 'WARN'
      }
    }

    Write-Log "Cycle: end"
    Start-Sleep -Seconds 2

  } while ($Loop)

  exit 0

} catch {
  Write-Log $_.Exception.Message 'ERROR'
  if ($PSBoundParameters['Verbose']) { Write-Log $_.ScriptStackTrace 'ERROR' }
  exit 1
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBWREehs2eTfoAPGT/KiSLmqz
# oO6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU7vfnQ8YGpQuaoPhA+LKmT46xczwwDQYJKoZIhvcNAQEBBQAEggEAJUe1
# PVRuc7gT6ZFEIZngQQSbdbljW1SW32sBfAtcpGv1xDTwCkYyatz2EH0WXOmPskH5
# jHjZSsCpUClTs4Ef1YjO9usurUbWReCM54cR0JmAJPo6mYqwB/+yMPnT34hzFTmd
# +Z6sGPujoX7vEg4/QKHFC29FmK6Qgy/12xYx4uaRaeEOswEq9QNBppWhQsNM8jLN
# cYCV85xrEyySQavjNXQ3ZI4NQuPfAbragkKsylaJHfHTPowYCwV6Z+URmGof9rhV
# iMt2WFGhaJdBNI8uw5IVAcWyknNqa2TiTAIMBk+di/4ROGqQudDSxMMxm6KD8tLf
# 8Pf1TWGd6vq+ABWA+A==
# SIG # End signature block
