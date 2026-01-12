#!/usr/bin/env bash
set -euo pipefail

# Codex Code Review Helper Script
# Example script showing how to use codex CLI for code review

if ! command -v codex >/dev/null 2>&1; then
  echo "ERROR: codex CLI not found. Install codex first." >&2
  exit 1
fi

RULES_FILE="${1:-.claude/code-review/rules.md}"
FILE_TO_REVIEW="${2:-}"

if [[ -z "$FILE_TO_REVIEW" ]]; then
  echo "Usage: $0 [rules-file] <file-to-review>" >&2
  exit 1
fi

if [[ ! -f "$RULES_FILE" ]]; then
  echo "WARNING: Rules file not found: $RULES_FILE" >&2
  echo "Using default TypeScript pattern rules." >&2
  RULES="Default rules: fn(args, deps), Result types, validation boundary, type safety, domain naming"
else
  RULES=$(cat "$RULES_FILE")
fi

if [[ ! -f "$FILE_TO_REVIEW" ]]; then
  echo "ERROR: File not found: $FILE_TO_REVIEW" >&2
  exit 1
fi

FILE_CONTENT=$(cat "$FILE_TO_REVIEW")

# Construct prompt
PROMPT=$(cat <<EOF
You are a code reviewer enforcing TypeScript patterns.

RULES TO ENFORCE:
$RULES

FILE TO REVIEW:
$FILE_TO_REVIEW

$FILE_CONTENT

INSTRUCTIONS:
Review this file against the rules above. For each violation found, report:
1. Rule name
2. File:line reference
3. Specific issue
4. Concrete fix

If no violations, respond with "PASS: File meets all requirements."

Format violations as:
FAIL

Violations:
1. [RULE NAME] - file.ts:42
   Issue: <specific violation>
   Fix: <concrete action>
EOF
)

# Call codex
codex \
  --quiet \
  --no-color \
  --system "You are a code reviewer enforcing TypeScript patterns. Review files against the provided rules and report violations with file:line references." \
  --prompt "$PROMPT"
