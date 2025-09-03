# 🚀 Quick Codemagic Setup - Extract Real Errors

## WHERE to add this in Codemagic

1. **Log in to Codemagic** → Open your project
2. **Go to your workflow** → Edit settings
3. **Find the "Build" section** with your scripts
4. **Add the diagnostic extraction step** RIGHT AFTER your xcodebuild command

## WHAT to add

### After your existing build step, add this:

```yaml
- name: Extract ALL Swift diagnostics (file + line + error)
  script: |
    set -euo pipefail
    BUNDLE="$CM_BUILD_DIR/build.xcresult"
    
    if [[ ! -d "$BUNDLE" ]]; then
      echo "No xcresult bundle found"
      exit 0
    fi
    
    echo "=== EXTRACTING REAL ERRORS ==="
    xcrun xcresulttool get --format json --path "$BUNDLE" | python3 - <<'PY'
    import json,sys
    j=json.load(sys.stdin)
    def walk(x,out):
      if isinstance(x,dict):
        if x.get('issueType')=='error':
          msg=x.get('message',{}).get('text','')
          loc=x.get('documentLocationInCreatingWorkspace',{}) or {}
          url=loc.get('url',''); line=loc.get('line')
          out.append((msg,url,line))
        for v in x.values(): walk(v,out)
      elif isinstance(x,list):
        for v in x: walk(v,out)
    out=[]; walk(j,out)
    for i,(msg,url,line) in enumerate(out[:15],1):
      print(f"\nERROR #{i}:\n  ✖ {msg}")
      if url: print(f"  📁 file: {url}")
      if line: print(f"  📍 line: {line}")
    PY
```

## WHERE to find the results

1. **Run your build** in Codemagic
2. **When it fails**, expand the step called "Extract ALL Swift diagnostics"
3. **Copy the ERROR entries** - they'll look like:
   ```
   ERROR #1:
     ✖ Cannot find type 'SomeType' in scope
     📁 file: file:///path/to/YourFile.swift
     📍 line: 42
   ```
4. **Paste those errors here** and I'll give you the exact fixes!

## Complete example in codemagic.yaml

Your scripts section should look like:

```yaml
scripts:
  # ... other steps ...
  
  - name: Build for iOS Simulator
    script: |
      xcodebuild \
        -scheme AgentDashboard \
        -configuration Debug \
        -destination "id=$SIM_UDID" \
        -resultBundlePath "$CM_BUILD_DIR/build.xcresult" \
        build
  
  - name: Extract ALL Swift diagnostics (file + line + error)
    script: |
      # [paste the extraction script from above]
```

## That's it! 

Run the build, get the real errors with file + line numbers, and we can fix them immediately.