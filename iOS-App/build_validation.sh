#!/bin/bash
# iOS Build Validation Script
# Run this before committing to catch common build issues

set -euo pipefail

echo "=== iOS Build Validation ==="
echo

# Check 1: Ensure single @main App
echo "Checking for single @main App..."
if command -v rg &> /dev/null; then
    hits=$(rg -n --no-heading -g 'iOS-App/**/*.swift' '@main\s+struct\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s*App' | wc -l | tr -d ' ')
else
    hits=$(grep -r "@main.*struct.*App" iOS-App --include="*.swift" | wc -l | tr -d ' ')
fi

echo "@main App count: $hits"
if [ "$hits" -gt 1 ]; then
    echo "❌ Multiple @main apps detected:"
    if command -v rg &> /dev/null; then
        rg -n --no-heading -g 'iOS-App/**/*.swift' '@main\s+struct\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s*App'
    else
        grep -rn "@main.*struct.*App" iOS-App --include="*.swift"
    fi
    exit 1
fi
echo "✅ Single @main App found"
echo

# Check 2: Duplicate type names
echo "Checking for duplicate type names..."
python3 - <<'PY'
import os
import re
from collections import defaultdict

root = "iOS-App"
pattern = re.compile(r'^\s*(struct|class|enum)\s+([A-Za-z_][A-Za-z0-9_]*)\b')
names = defaultdict(list)

for dirpath, _, files in os.walk(root):
    for f in files:
        if not f.endswith(".swift"):
            continue
        filepath = os.path.join(dirpath, f)
        try:
            with open(filepath, encoding="utf-8", errors="ignore") as file:
                for i, line in enumerate(file, 1):
                    match = pattern.match(line)
                    if match:
                        type_name = match.group(2)
                        names[type_name].append(f"{filepath}:{i}")
        except:
            continue

dupes = {k: v for k, v in names.items() if len(v) > 1}
if dupes:
    print("❌ Duplicate type names found:")
    for name, locations in dupes.items():
        print(f"  {name}")
        for loc in locations:
            print(f"    - {loc}")
    raise SystemExit(1)
else:
    print("✅ No duplicate type names")
PY
echo

# Check 3: No "import Dependencies" statements
echo "Checking for 'import Dependencies' statements..."
if command -v rg &> /dev/null; then
    deps_count=$(rg "^import Dependencies$" iOS-App -g "*.swift" | wc -l | tr -d ' ')
else
    deps_count=$(grep -r "^import Dependencies$" iOS-App --include="*.swift" | wc -l | tr -d ' ')
fi

if [ "$deps_count" -gt 0 ]; then
    echo "❌ Found 'import Dependencies' statements:"
    if command -v rg &> /dev/null; then
        rg -n "^import Dependencies$" iOS-App -g "*.swift"
    else
        grep -rn "^import Dependencies$" iOS-App --include="*.swift"
    fi
    echo "Replace with: import ComposableArchitecture"
    exit 1
fi
echo "✅ No 'import Dependencies' statements"
echo

# Check 4: Verify wrapper views exist
echo "Checking for required view wrappers..."
required_views=("AgentsView" "TerminalView" "AnalyticsView" "SettingsView" "DashboardView")
missing_views=()

for view in "${required_views[@]}"; do
    if command -v rg &> /dev/null; then
        count=$(rg "struct $view\s*:" iOS-App -g "*.swift" | wc -l | tr -d ' ')
    else
        count=$(grep -r "struct $view\s*:" iOS-App --include="*.swift" | wc -l | tr -d ' ')
    fi
    
    if [ "$count" -eq 0 ]; then
        missing_views+=("$view")
    elif [ "$count" -gt 1 ]; then
        echo "⚠️  Warning: Multiple definitions of $view"
    fi
done

if [ ${#missing_views[@]} -gt 0 ]; then
    echo "❌ Missing views:"
    for view in "${missing_views[@]}"; do
        echo "  - $view"
    done
    exit 1
fi
echo "✅ All required views present"
echo

# Check 5: ContentView exists and is unique
echo "Checking ContentView..."
if command -v rg &> /dev/null; then
    content_count=$(rg "struct ContentView\s*:" iOS-App -g "*.swift" | wc -l | tr -d ' ')
else
    content_count=$(grep -r "struct ContentView\s*:" iOS-App --include="*.swift" | wc -l | tr -d ' ')
fi

if [ "$content_count" -eq 0 ]; then
    echo "❌ ContentView not found"
    exit 1
elif [ "$content_count" -gt 1 ]; then
    echo "❌ Multiple ContentView definitions found"
    exit 1
fi
echo "✅ ContentView is unique"
echo

echo "=== All validation checks passed ✅ ==="