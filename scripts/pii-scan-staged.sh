#!/usr/bin/env bash
set -euo pipefail

# Scans STAGED changes (git index) for common secret/PII patterns.
# Exits non-zero to block commits when matches are found.

cd "$(git rev-parse --show-toplevel)"

echo "PII/secrets scan (staged changes)…"

# Only scan text diffs of staged content.
DIFF="$(git diff --cached --unified=0 --no-color)"

# Patterns: adjust conservatively to avoid noise.
PATTERNS=(
  # Bearer tokens (long-ish)
  "Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._~-]{20,}"
  "Bearer[[:space:]]+[A-Za-z0-9._~-]{20,}"

  # OpenAI key shapes (common prefixes)
  "sk-[A-Za-z0-9]{20,}"
  "sk-proj-[A-Za-z0-9]{20,}"

  # Apple device UDID-ish strings often start with 00008…
  "00008[0-9A-Fa-f-]{6,}"

  # Emails
  "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
)

FOUND=0
for pat in "${PATTERNS[@]}"; do
  if printf "%s" "${DIFF}" | /usr/bin/grep -E -n "${pat}" >/dev/null 2>&1; then
    echo ""
    echo "Blocked commit: staged diff matched sensitive pattern:"
    echo "  ${pat}"
    echo ""
    echo "Matches:"
    printf "%s" "${DIFF}" | /usr/bin/grep -E -n "${pat}" | head -n 20
    FOUND=1
  fi
done

if [ "${FOUND}" -ne 0 ]; then
  echo ""
  echo "Fix: remove/redact secrets or move them to ignored config (e.g. Secrets.xcconfig, worker secrets)."
  echo "If this is a false positive, tighten the pattern list in scripts/pii-scan-staged.sh."
  exit 1
fi

echo "OK: no obvious PII/secrets found in staged changes."

