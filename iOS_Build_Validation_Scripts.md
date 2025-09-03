# iOS Build Validation Scripts for Codemagic
**Date**: 2025-09-03
**Purpose**: Enhanced build validation and error extraction for iOS AgentDashboard

## Pre-Build Validation Script

Add this to your codemagic.yaml before the build step:

```yaml
- name: Pre-build validation and import fixes
  script: |
    set -euxo pipefail
    echo "🔍 Pre-build validation starting..."
    
    # Fix any remaining import Dependencies statements
    echo "📝 Fixing import Dependencies statements..."
    find iOS-App -name "*.swift" -print0 \
      | xargs -0 perl -0777 -pi -e 's/\bimport\s+Dependencies\b/import ComposableArchitecture/g'
    
    # Verify no duplicate AppFeature files
    echo "🔍 Checking for duplicate AppFeature files..."
    APPFEATURE_COUNT=$(find iOS-App -name "*AppFeature*.swift" | wc -l)
    echo "Found $APPFEATURE_COUNT AppFeature files:"
    find iOS-App -name "*AppFeature*.swift"
    
    # Verify no duplicate DashboardView files  
    echo "🔍 Checking for duplicate DashboardView files..."
    DASHBOARD_COUNT=$(find iOS-App -name "*DashboardView*.swift" | wc -l)
    echo "Found $DASHBOARD_COUNT DashboardView files:"
    find iOS-App -name "*DashboardView*.swift"
    
    echo "✅ Pre-build validation complete"
```

## Build Error Extraction Script

Add this AFTER your build step to get detailed error information:

```yaml
- name: Extract detailed Swift compilation errors
  script: |
    set -euo pipefail
    echo "🔍 Extracting compilation errors from build results..."
    
    BUNDLE="$CM_BUILD_DIR/build.xcresult"
    [[ -d "$BUNDLE" ]] || { echo "No build.xcresult found"; exit 0; }
    
    echo "📊 Build result bundle found at: $BUNDLE"
    xcrun xcresulttool get --path "$BUNDLE" --format json | python3 - <<'PY'
import json, sys

def extract_errors(data):
    errors_found = False
    
    def walk(obj, path=""):
        nonlocal errors_found
        if isinstance(obj, dict):
            if obj.get('issueType') == 'error':
                errors_found = True
                message = obj.get('message', {}).get('text', 'Unknown error')
                location = obj.get('documentLocationInCreatingWorkspace', {})
                file_url = location.get('url', 'Unknown file')
                line_number = location.get('line', 'Unknown line')
                
                print('❌ COMPILATION ERROR:')
                print(f'   Message: {message}')
                print(f'   File: {file_url}')
                print(f'   Line: {line_number}')
                print()
                
            for key, value in obj.items():
                walk(value, f"{path}.{key}")
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                walk(item, f"{path}[{i}]")
    
    try:
        walk(json.load(sys.stdin))
        if not errors_found:
            print("✅ No compilation errors found in build results")
    except json.JSONDecodeError:
        print("❌ Failed to parse build results JSON")
    except Exception as e:
        print(f"❌ Error processing build results: {e}")

extract_errors({})
PY

    echo "🔍 Error extraction complete"
```

## Duplicate Type Detection Script

Add this for ongoing duplicate detection:

```yaml
- name: Detect duplicate top-level types
  script: |
    set -euo pipefail
    echo "🔍 Scanning for duplicate type definitions..."
    
    # Create temporary file for type extraction
    TEMP_TYPES=$(mktemp)
    
    # Extract all top-level type declarations (struct, class, enum)
    find iOS-App -name "*.swift" -exec grep -Hn "^\s*\(struct\|class\|enum\)\s\+[A-Za-z_][A-Za-z0-9_]*" {} \; > "$TEMP_TYPES"
    
    # Extract just the type names and find duplicates
    awk '{
        match($0, /^\s*(struct|class|enum)\s+([A-Za-z_][A-Za-z0-9_]*)/, arr)
        if (arr[2] != "") {
            gsub(/:.*$/, "", $1)  # Remove line content after filename:line
            print $1 " " arr[2]
        }
    }' "$TEMP_TYPES" | sort > "$TEMP_TYPES.parsed"
    
    # Find duplicate type names
    awk '{print $2}' "$TEMP_TYPES.parsed" | sort | uniq -d | while read typename; do
        if [ -n "$typename" ]; then
            echo "⚠️  DUPLICATE TYPE: $typename"
            grep " $typename$" "$TEMP_TYPES.parsed"
            echo
        fi
    done
    
    # Cleanup
    rm -f "$TEMP_TYPES" "$TEMP_TYPES.parsed"
    echo "✅ Duplicate type scan complete"
```

## Debug Logging Verification

Add this to verify debug logging is working:

```yaml
- name: Verify debug logging setup
  script: |
    echo "🔍 Verifying debug logging setup..."
    
    # Check for debug print statements in key files
    echo "📊 Checking APIClient.swift for debug logs..."
    grep -n "print.*APIClient" iOS-App/AgentDashboard/AgentDashboard/Network/APIClient.swift || echo "No APIClient debug logs found"
    
    echo "📱 Checking ContentView.swift for debug logs..."  
    grep -n "print.*ContentView" iOS-App/AgentDashboard/AgentDashboard/Views/ContentView.swift || echo "No ContentView debug logs found"
    
    echo "🎯 Checking AppFeature.swift for debug logs..."
    grep -n "print.*AppFeature" iOS-App/AgentDashboard/AgentDashboard/TCA/AppFeature.swift || echo "No AppFeature debug logs found"
    
    echo "✅ Debug logging verification complete"
```