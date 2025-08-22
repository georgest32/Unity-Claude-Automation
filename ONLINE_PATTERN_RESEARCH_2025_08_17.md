# Online Unity Debug Pattern Research
Date: 2025-08-17
Time: Current Session
Previous Context: Searched for Unity debug patterns and UNT codes online
Topics: Unity Analyzer codes, Common errors, Performance patterns

## Research Summary
After 5 comprehensive web searches, I've compiled a valuable collection of Unity-specific debug patterns and best practices.

## 1. Microsoft Unity Analyzer (UNT) Codes

### Official Repository
- **Source**: github.com/microsoft/Microsoft.Unity.Analyzers
- **Purpose**: Roslyn analyzers for Unity-specific issues
- **Integration**: Ships with Visual Studio and VS Code Unity extensions

### Key UNT Codes Found
- **UNT0001**: Unity objects should not use null coalescing
- **UNT0003**: Use generic form of GetComponent
- **UNT0004**: Time.deltaTime usage with Update
- **UNT0005**: Time.fixedDeltaTime usage with FixedUpdate  
- **UNT0010**: Don't use 'new' for MonoBehaviours
- **UNT0011**: Don't use 'new' for ScriptableObjects
- **UNT0014**: Invalid method called on GameObject
- **UNT0017**: SetPixels invocation is slow
- **UNT0018**: System.Reflection features are slow
- **UNT0021**: Unity message should be protected
- **UNT0022**: Inefficient position and rotation assignment
- **UNT0027**: Do not use PropertyDrawer on fields
- **UNT0028**: Use non-allocating physics APIs
- **UNT0029**: Pattern matching with null on Unity objects
- **UNT0030**: Calling Destroy on Transform
- **UNT0031**: Inappropriate assertion method usage
- **UNT0035**: Vector2 to Vector3 conversion

### USP Codes (Unity Suppressors)
- **USP0003**: Unity messages not flagged as unused
- **USP0020**: Unity runtime invokes Unity messages
- **USP0021**: Prefer reference equality
- **USP0022**: Unity objects shouldn't use null coalescing

## 2. Common Unity Compilation Errors

### CS0246: Type or namespace not found
**Causes**:
- Missing using directive
- Misspelled namespace/class name
- Missing assembly reference
- Incorrect namespace

**Fixes**:
- Add appropriate using statement (e.g., using UnityEngine;)
- Verify spelling and capitalization
- Check assembly references
- Use IntelliSense/auto-complete

### CS0103: Name doesn't exist in current context
**Causes**:
- Variable not declared
- Variable out of scope
- Typo in variable name
- Using variable before declaration

**Fixes**:
- Declare variable before use
- Check variable scope
- Verify spelling
- Move declaration to appropriate scope

### CS1061: Type doesn't contain definition
**Causes**:
- Method/property doesn't exist
- Wrong object type
- Private member accessed externally
- Static vs instance confusion

**Fixes**:
- Verify method/property exists
- Check object type
- Make member public if needed
- Use correct static/instance access

## 3. NullReferenceException Patterns

### Common Causes
1. **GameObject.Find() failures**:
   - Object doesn't exist
   - Object inactive
   - Name typo/spacing
   - Wrong scene

2. **GetComponent() returns null**:
   - Component missing
   - Wrong GameObject
   - Wrong component type

3. **Script execution order**:
   - Awake/Start timing issues
   - Race conditions

### Best Practices
1. **Always null check**:
   ```csharp
   if (component != null) // or just if (component)
   ```

2. **Use RequireComponent**:
   ```csharp
   [RequireComponent(typeof(Rigidbody))]
   ```

3. **Cache references early**:
   ```csharp
   void Awake() {
       rb = GetComponent<Rigidbody>();
   }
   ```

4. **Avoid GameObject.Find()**:
   - Use Inspector references
   - Use tags: FindWithTag()
   - Use singleton patterns

## 4. Performance Optimization Patterns

### Update Loop Optimization
1. **Minimize Update() work**:
   - Move logic out when possible
   - Use InvokeRepeating for infrequent updates
   - Consider coroutines

2. **Proper method selection**:
   - Update(): Game logic
   - FixedUpdate(): Physics (50-100 calls/sec)
   - LateUpdate(): After all Updates

3. **Custom UpdateManager**:
   - Subscribe/unsubscribe pattern
   - Reduces interop calls

### Object Pooling
1. **When to use**:
   - Bullets, particles, effects
   - Frequently created/destroyed objects
   - Short-lived objects

2. **Benefits**:
   - Reduces GC overhead
   - Eliminates instantiation cost
   - Better memory management

### Caching Strategies
1. **Component caching**:
   ```csharp
   private Transform t;
   void Start() { t = transform; }
   ```

2. **Property ID caching**:
   ```csharp
   int speedHash = Animator.StringToHash("Speed");
   ```

3. **Search result caching**:
   - Store Find results
   - Cache GetComponent results

## 5. High-Value Patterns to Import

Based on research, these patterns provide the most value:

### Critical Errors
1. CS0246 + "GameObject" → Add "using UnityEngine;"
2. CS0246 + "MonoBehaviour" → Add "using UnityEngine;"
3. CS0246 + "Vector3" → Add "using UnityEngine;"
4. CS0103 + variable → Check declaration and scope
5. CS1061 + GetComponent → Verify component exists

### NullReference Prevention
6. GameObject.Find returns null → Use null check, consider alternatives
7. GetComponent returns null → Add RequireComponent, null check
8. "Object reference not set" → Initialize in Awake/Start

### Performance Issues
9. GetComponent in Update → Cache in Start/Awake
10. Instantiate/Destroy frequently → Use object pooling
11. GameObject.Find in Update → Cache reference once
12. Transform access repeatedly → Cache Transform component

### Unity Best Practices
13. new MonoBehaviour() → Use AddComponent<T>()
14. new ScriptableObject() → Use CreateInstance<T>()
15. obj ?? fallback → Use obj ? obj : fallback
16. Time.deltaTime in FixedUpdate → Use Time.fixedDeltaTime
17. SetPixels() → Use SetPixels32() for performance

## Recommendations

### Immediate Actions
1. Import the 17 high-value patterns above
2. Add Microsoft Unity Analyzer patterns (UNT codes)
3. Create categories: Compilation, NullReference, Performance, BestPractices

### Future Enhancement
1. Monitor actual project errors to build custom patterns
2. Integrate with Unity's built-in analyzers
3. Create severity levels for patterns
4. Add context-specific fixes

## Pattern Quality Assessment
These online-sourced patterns are:
- **High Quality**: From official Unity docs and Microsoft
- **Well-Tested**: Used by thousands of developers
- **Actionable**: Provide specific fixes
- **Relevant**: Address common Unity pain points

Much better quality than symbolic_main.db patterns!