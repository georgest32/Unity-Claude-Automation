#!/usr/bin/env python3
import json, os, sys, subprocess

if len(sys.argv) < 2:
    print("Usage: python3 extract_build_errors.py <xcresult_path>")
    sys.exit(0)

xcresult_path = sys.argv[1]

if not os.path.exists(xcresult_path):
    print("No result bundle found at:", xcresult_path)
    sys.exit(0)

try:
    # Extract JSON from xcresult bundle
    result = subprocess.run(
        ["xcrun", "xcresulttool", "get", "object", "--legacy", "--path", xcresult_path, "--format", "json"],
        capture_output=True, text=True, check=True
    )
    data = json.loads(result.stdout)
except Exception as e:
    print(f"Failed to extract xcresult data: {e}")
    sys.exit(0)

errors = []
def walk(x):
    if isinstance(x, dict):
        if x.get('issueType') == 'error':
            m = x.get('message', {}).get('text', '')
            loc = x.get('documentLocationInCreatingWorkspace', {})
            errors.append((m, loc.get('url',''), loc.get('line')))
        for v in x.values(): 
            walk(v)
    elif isinstance(x, list):
        for v in x: 
            walk(v)

walk(data)

if not errors:
    print("No error issues found in xcresult.")
    sys.exit(0)

print("=== Swift Compiler Errors ===")
for i, (msg, url, line) in enumerate(errors, 1):
    print(f"\n[{i}] ✖︎ {msg}")
    if url: 
        print(f"    file: {url}")
    if line: 
        print(f"    line: {line}")