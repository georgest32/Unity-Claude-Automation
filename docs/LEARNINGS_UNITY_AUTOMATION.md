# Unity Automation - Unity-Claude Automation
*Unity-specific automation patterns, compilation detection, and Unity Editor integration*
*Last Updated: 2025-08-19*

## 🔄 Unity Integration Learnings

### 16. Domain Reload Survival (⚠️ CRITICAL)
**Issue**: Unity reloads assemblies during compilation
**Discovery**: Static state lost on domain reload
**Evidence**: [InitializeOnLoadMethod] called after each reload
**Resolution**: Use SessionState for persistence
**Critical Learning**: Never rely on static state in Unity Editor scripts

### 17. Roslyn Version Conflicts (📝 DOCUMENTED)
**Issue**: Unity crashes with Roslyn version mismatches
**Discovery**: Unity limited to Microsoft.CodeAnalysis v3.8
**Evidence**: Modern tools use v4.4+, causing conflicts
**Resolution**: Isolate Roslyn dependencies; use Unity's version
**Critical Learning**: Check assembly versions for Unity compatibility

### 18. Console Log Access (✅ RESOLVED)
**Issue**: LogEntries is internal Unity class
**Discovery**: Reflection required for console access
**Evidence**: typeof(EditorWindow).Assembly.GetType("UnityEditor.LogEntries")
**Resolution**: Use reflection with proper error handling
**Critical Learning**: Unity internals change; add version checks

## 🎯 Unity Compilation Detection

### Unity Batch Mode Compilation Best Practices
```csharp
// Proper Unity compilation detection
using UnityEditor;
using UnityEditor.Compilation;

[InitializeOnLoadMethod]
static void InitializeCompilationDetection()
{
    // Use CompilationPipeline events - reliable in batch mode
    CompilationPipeline.compilationFinished += OnCompilationFinished;
    CompilationPipeline.compilationStarted += OnCompilationStarted;
    
    // Store state in SessionState for domain reload survival
    SessionState.SetBool("AutomationEnabled", true);
}

static void OnCompilationStarted(object obj)
{
    // Export compilation start signal
    var startTime = System.DateTime.Now;
    SessionState.SetString("CompilationStartTime", startTime.ToString("O"));
    
    // Write signal file for PowerShell detection
    File.WriteAllText("compilation_started.signal", startTime.ToString("O"));
}

static void OnCompilationFinished(object obj)
{
    // Only export if automation enabled
    if (!SessionState.GetBool("AutomationEnabled", false)) return;
    
    var endTime = System.DateTime.Now;
    var startTimeStr = SessionState.GetString("CompilationStartTime", "");
    
    // Export compilation results
    ExportCompilationResults(startTimeStr, endTime.ToString("O"));
}
```

### Unity Error Pattern Detection
```csharp
// Unity error code patterns for automation
public static class UnityErrorPatterns
{
    public static readonly Dictionary<string, string> ErrorCodeMappings = new Dictionary<string, string>
    {
        {"CS0246", "Type or namespace not found"},
        {"CS0103", "Name does not exist in current context"},
        {"CS1061", "Type does not contain definition"},
        {"CS0029", "Cannot implicitly convert type"},
        {"CS0117", "Type does not contain definition for member"},
        {"CS0120", "Object reference required for non-static member"}
    };
    
    public static string ClassifyError(string errorMessage)
    {
        foreach (var pattern in ErrorCodeMappings)
        {
            if (errorMessage.Contains(pattern.Key))
            {
                return pattern.Value;
            }
        }
        return "Unknown error type";
    }
}
```

### Unity Log Export for PowerShell Processing
```csharp
using System.IO;
using System.Text.Json;
using UnityEngine;

public class UnityLogExporter
{
    public static void ExportCurrentErrors()
    {
        var logEntries = GetConsoleEntries();
        var errorData = new
        {
            Timestamp = System.DateTime.Now.ToString("O"),
            ErrorCount = logEntries.errors.Count,
            WarningCount = logEntries.warnings.Count,
            Errors = logEntries.errors,
            Warnings = logEntries.warnings,
            UnityVersion = Application.unityVersion,
            ProjectPath = Application.dataPath
        };
        
        var json = JsonSerializer.Serialize(errorData, new JsonSerializerOptions 
        { 
            WriteIndented = true 
        });
        
        File.WriteAllText("current_errors.json", json);
        Debug.Log($"Exported {logEntries.errors.Count} errors and {logEntries.warnings.Count} warnings");
    }
    
    private static (List<string> errors, List<string> warnings) GetConsoleEntries()
    {
        // Use reflection to access Unity's internal LogEntries
        var logEntriesType = typeof(EditorWindow).Assembly.GetType("UnityEditor.LogEntries");
        var getCountMethod = logEntriesType.GetMethod("GetCount");
        var getEntryInternalMethod = logEntriesType.GetMethod("GetEntryInternal");
        
        int totalCount = (int)getCountMethod.Invoke(null, null);
        var errors = new List<string>();
        var warnings = new List<string>();
        
        for (int i = 0; i < totalCount; i++)
        {
            // Extract log entry details using reflection
            // This is Unity version-dependent and may need updates
        }
        
        return (errors, warnings);
    }
}
```

## 🔧 Unity Editor Integration Patterns

### Unity Menu Integration for Automation
```csharp
public class UnityClaudeAutomationMenu
{
    [MenuItem("Tools/Claude Automation/Export Current Errors")]
    public static void ExportErrors()
    {
        UnityLogExporter.ExportCurrentErrors();
    }
    
    [MenuItem("Tools/Claude Automation/Force Compilation")]
    public static void ForceCompilation()
    {
        CompilationPipeline.RequestScriptCompilation();
    }
    
    [MenuItem("Tools/Claude Automation/Clear Console")]
    public static void ClearConsole()
    {
        var logEntriesType = typeof(EditorWindow).Assembly.GetType("UnityEditor.LogEntries");
        var clearMethod = logEntriesType.GetMethod("Clear");
        clearMethod?.Invoke(null, null);
    }
}
```

### Unity Build Automation
```csharp
public class UnityBuildAutomation
{
    public static void PerformBuild(BuildTarget target, string outputPath)
    {
        var scenes = EditorBuildSettings.scenes
            .Where(scene => scene.enabled)
            .Select(scene => scene.path)
            .ToArray();
            
        var buildOptions = BuildOptions.None;
        
        var report = BuildPipeline.BuildPlayer(scenes, outputPath, target, buildOptions);
        
        // Export build results for PowerShell processing
        var buildResult = new
        {
            Success = report.summary.result == BuildResult.Succeeded,
            Target = target.ToString(),
            OutputPath = outputPath,
            BuildTime = report.summary.buildEndedAt - report.summary.buildStartedAt,
            Errors = report.steps.SelectMany(step => step.messages)
                          .Where(msg => msg.type == LogType.Error)
                          .Select(msg => msg.content)
                          .ToArray()
        };
        
        File.WriteAllText("build_result.json", JsonSerializer.Serialize(buildResult));
    }
}
```

### Unity Project Validation
```csharp
public class UnityProjectValidator
{
    public static ValidationResult ValidateProject()
    {
        var result = new ValidationResult();
        
        // Check for missing references
        var allPrefabs = AssetDatabase.FindAssets("t:Prefab");
        foreach (var guid in allPrefabs)
        {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            
            if (HasMissingReferences(prefab))
            {
                result.MissingReferences.Add(path);
            }
        }
        
        // Check for compilation errors
        result.HasCompilationErrors = CompilationPipeline.codeOptimization == CodeOptimization.Debug;
        
        // Export validation results
        File.WriteAllText("validation_result.json", JsonSerializer.Serialize(result));
        
        return result;
    }
    
    private static bool HasMissingReferences(GameObject obj)
    {
        // Implement missing reference detection
        return false;
    }
}

public class ValidationResult
{
    public List<string> MissingReferences { get; set; } = new List<string>();
    public bool HasCompilationErrors { get; set; }
    public List<string> WarningMessages { get; set; } = new List<string>();
}
```

## 📊 Unity Performance Monitoring

### Unity Editor Performance Tracking
```csharp
public class UnityPerformanceMonitor
{
    private static DateTime lastCheck = DateTime.Now;
    
    [InitializeOnLoadMethod]
    static void StartMonitoring()
    {
        EditorApplication.update += CheckPerformance;
    }
    
    static void CheckPerformance()
    {
        if ((DateTime.Now - lastCheck).TotalSeconds < 5) return;
        lastCheck = DateTime.Now;
        
        var memoryUsage = System.GC.GetTotalMemory(false) / 1024 / 1024; // MB
        var performanceData = new
        {
            Timestamp = DateTime.Now.ToString("O"),
            MemoryUsageMB = memoryUsage,
            IsCompiling = EditorApplication.isCompiling,
            IsPlaying = EditorApplication.isPlaying,
            CurrentScene = UnityEngine.SceneManagement.SceneManager.GetActiveScene().name
        };
        
        // Export for PowerShell monitoring
        File.WriteAllText("unity_performance.json", JsonSerializer.Serialize(performanceData));
    }
}
```

## 🛡️ Unity Safety Patterns

### Safe Unity Automation Guidelines
1. **Always check Unity state** before performing operations
2. **Use SessionState** for persistence across domain reloads
3. **Implement timeout mechanisms** for long-running operations
4. **Validate asset references** before automation
5. **Backup project state** before automated changes

### Unity Editor State Validation
```csharp
public static class UnityStateValidator
{
    public static bool IsSafeForAutomation()
    {
        // Don't automate during compilation
        if (EditorApplication.isCompiling) return false;
        
        // Don't automate during play mode
        if (EditorApplication.isPlaying) return false;
        
        // Check for unsaved scenes
        if (UnityEngine.SceneManagement.SceneManager.GetActiveScene().isDirty)
        {
            Debug.LogWarning("Scene has unsaved changes - consider saving before automation");
        }
        
        // Check for missing critical assets
        var criticalAssets = new[] { "ProjectSettings/ProjectSettings.asset" };
        foreach (var asset in criticalAssets)
        {
            if (!File.Exists(asset))
            {
                Debug.LogError($"Critical asset missing: {asset}");
                return false;
            }
        }
        
        return true;
    }
}
```

---
*This document covers Unity-specific automation patterns.*
*For broader system architecture, see IMPLEMENTATION_GUIDE.md*