import json, sys, os, subprocess

if len(sys.argv) < 2:
    print("Usage: python3 xcresult_errors.py <path-to-xcresult>")
    sys.exit(1)

path = sys.argv[1]
if not os.path.exists(path):
    print(f"No result bundle found at {path}")
    sys.exit(0)

try:
    p = subprocess.run(
        ["xcrun", "xcresulttool", "get", "object", "--legacy", "--path", path, "--format", "json"],
        check=True, capture_output=True, text=True
    )
    data = json.loads(p.stdout)
except Exception as e:
    print(f"xcresulttool failed: {e}")
    sys.exit(0)

files = {}
def walk(x):
    if isinstance(x, dict):
        if x.get('issueType') == 'error':
            m = x.get('message', {}).get('text', '(no message)')
            loc = x.get('documentLocationInCreatingWorkspace', {})
            url = loc.get('url') or ""
            line = loc.get('line')
            files.setdefault(url, []).append((line, m))
        for v in x.values():
            walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)

walk(data)

if not files:
    print("No compiler errors found in xcresult.")
    sys.exit(0)

print("\n=== Compiler errors by file ===")
for url, errs in files.items():
    print(f"\nFILE: {url or '(unknown)'}")
    for ln, msg in sorted(errs, key=lambda t: (t[0] or 0, t[1])):
        where = f"line {ln}" if ln else "line ?"
        print(f"  • {where}: {msg}")