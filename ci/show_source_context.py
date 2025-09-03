#!/usr/bin/env python3
import json, os, sys

if len(sys.argv) < 2:
    xcresult_json = os.path.join(os.environ.get('CM_BUILD_DIR', '.'), 'xcresult.json')
else:
    xcresult_json = sys.argv[1]

if not os.path.exists(xcresult_json):
    print("No xcresult.json to read")
    sys.exit(0)

try:
    with open(xcresult_json, 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"Failed to read xcresult JSON: {e}")
    sys.exit(0)

def show_context(path, line):
    if not (path and path.startswith('file://')):
        return
    
    # Remove file:// prefix
    path = path[7:]
    if not (os.path.exists(path) and isinstance(line, int)):
        return
    
    start = max(1, line - 15)
    end = line + 15
    print(f"\n--- {path}:{line} ---")
    
    try:
        with open(path, 'r') as f:
            for i, ln in enumerate(f, 1):
                if i < start:
                    continue
                if i > end:
                    break
                mark = ">>" if i == line else "  "
                print(f"{mark} {i:5d}: {ln.rstrip()}")
    except Exception as e:
        print(f"Could not read {path}: {e}")

def walk(x):
    if isinstance(x, dict):
        if x.get('issueType') == 'error':
            loc = x.get('documentLocationInCreatingWorkspace', {})
            show_context(loc.get('url'), loc.get('line'))
        for v in x.values():
            walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)

walk(data)