#!/bin/bash
# Runs the Obeya app's own tests (apps/obeya/test). Skips when node or npm is missing.
root="$(cd "$(dirname "$0")/../.." && pwd)"
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "SKIP: node or npm not installed"
  exit 0
fi
cd "$root/apps/obeya" || exit 1
npm ci --silent >/dev/null 2>&1 || { echo "FAIL: npm ci"; exit 1; }
npm run build --silent >/dev/null 2>&1 || { echo "FAIL: npm run build"; exit 1; }
npm test --silent
