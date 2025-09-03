#!/bin/bash
# Extract detailed Swift diagnostics from xcresult bundle
# Usage: ./extract_diagnostics.sh [path/to/build.xcresult]

set -euo pipefail

BUNDLE="${1:-$CM_BUILD_DIR/build.xcresult}"

if [[ ! -d "$BUNDLE" ]]; then
    echo "No xcresult bundle found at: $BUNDLE"
    exit 0
fi

echo "=== Extracting Swift Diagnostics from $BUNDLE ==="
echo

# Extract all errors and warnings with file locations
xcrun xcresulttool get --format json --path "$BUNDLE" | python3 - <<'PY'
import json
import sys

data = json.load(sys.stdin)

def walk(obj, results):
    if isinstance(obj, dict):
        if obj.get('issueType') in ('error', 'warning'):
            msg = obj.get('message', {}).get('text', '')
            loc = obj.get('documentLocationInCreatingWorkspace', {}) or {}
            url = loc.get('url', '')
            line = loc.get('line')
            
            icon = '✖' if obj.get('issueType') == 'error' else '⚠'
            results.append({
                'type': obj.get('issueType'),
                'message': msg,
                'file': url,
                'line': line,
                'icon': icon
            })
        
        for value in obj.values():
            walk(value, results)
    elif isinstance(obj, list):
        for item in obj:
            walk(item, results)

results = []
walk(data, results)

if not results:
    print("No errors or warnings found in build result")
else:
    # Group by error vs warning
    errors = [r for r in results if r['type'] == 'error']
    warnings = [r for r in results if r['type'] == 'warning']
    
    if errors:
        print(f"=== ERRORS ({len(errors)}) ===")
        for r in errors:
            print(f"\n{r['icon']} {r['message']}")
            if r['file']:
                print(f"   File: {r['file']}")
            if r['line']:
                print(f"   Line: {r['line']}")
    
    if warnings:
        print(f"\n=== WARNINGS ({len(warnings)}) ===")
        for r in warnings[:10]:  # Limit to first 10 warnings
            print(f"\n{r['icon']} {r['message']}")
            if r['file']:
                print(f"   File: {r['file']}")
            if r['line']:
                print(f"   Line: {r['line']}")
        
        if len(warnings) > 10:
            print(f"\n... and {len(warnings) - 10} more warnings")
PY

echo
echo "=== Checking for serialized diagnostics ==="

# Look for serialized diagnostic files
swiftdiags=$(find "$BUNDLE" -type f \( -name "*.dia" -o -name "*.diagnostics" \) 2>/dev/null || true)

if [[ -z "$swiftdiags" ]]; then
    echo "No serialized Swift diagnostics found"
else
    echo "Found serialized diagnostic files:"
    while IFS= read -r diag; do
        echo "  - $diag"
        if command -v swift-diagnostics &> /dev/null; then
            echo "    Parsing with swift-diagnostics:"
            xcrun swift-diagnostics tool parse "$diag" 2>/dev/null || echo "    (could not parse)"
        fi
    done <<< "$swiftdiags"
fi