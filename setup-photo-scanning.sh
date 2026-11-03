#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
FILE="MyApp/Secrets.plist"
echo "TrainFUEL photo analysis setup"
echo "Paste your OpenRouter API key (the input is hidden)."
read -r -s -p "OpenRouter API key: " OPENROUTER_KEY
printf '\n'
if [[ "$OPENROUTER_KEY" != sk-or-* ]]; then
  echo "This doesn't look like an OpenRouter key. No file created."
  exit 1
fi
printf '%s' "$OPENROUTER_KEY" | /usr/bin/python3 -c '
import sys, plistlib
from pathlib import Path
key=sys.stdin.read()
path=Path("MyApp/Secrets.plist")
path.write_bytes(plistlib.dumps({"OpenRouterAPIKey":key}))
'
unset OPENROUTER_KEY
chmod 600 "$FILE"
echo "Saved locally at $FILE."
echo "This file is excluded from Git by .gitignore."
echo "Reopen Xcode and build the app. Do not share the key."
