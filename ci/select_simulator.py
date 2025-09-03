#!/usr/bin/env python3
import json, sys, subprocess

if len(sys.argv) < 3:
    print("Usage: python3 select_simulator.py <want_os> <want_name>")
    sys.exit(1)

want_os = sys.argv[1]      # e.g. "18.5"
want_name = sys.argv[2]    # e.g. "iPhone 16 Pro"

# Get simulator data
try:
    output = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"])
    data = json.loads(output)
except Exception as e:
    print(f"Failed to get simulator list: {e}", file=sys.stderr)
    sys.exit(1)

def udid_from(devs, name=None):
    if not devs: 
        return None
    if name:
        for d in devs:
            if d.get('isAvailable') and d.get('name') == name:
                return d['udid']
    # fallback: first available iPhone
    for d in devs:
        if d.get('isAvailable') and 'iPhone' in d.get('name', ''):
            return d['udid']
    # fallback: any available
    for d in devs:
        if d.get('isAvailable'):
            return d['udid']
    return None

devices = data.get('devices', {})
candidates = None
needle = want_os.replace('.', '-')  # 18.5 -> 18-5

# Find runtime with matching iOS version
for runtime, devs in devices.items():
    # runtime looks like: com.apple.CoreSimulator.SimRuntime.iOS-18-5
    if 'iOS' in runtime and needle in runtime:
        candidates = devs
        break

udid = udid_from(candidates, want_name)

# Final fallback: any iOS device any OS
if not udid:
    for runtime, devs in devices.items():
        if 'iOS' in runtime:
            udid = udid_from(devs)
            if udid: 
                break

if udid:
    print(udid)
else:
    print("", file=sys.stderr)
    sys.exit(1)