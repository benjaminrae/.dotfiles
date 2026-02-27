#!/bin/bash
COMMAND=$(cat | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

if echo "$COMMAND" | grep -qE '^git commit\b'; then
  if [ ! -f Makefile ]; then
    echo "Warning: No Makefile found. Add a 'pre-commit' target to run checks before commits." >&2
  elif ! make -n pre-commit >/dev/null 2>&1; then
    echo "Warning: No 'pre-commit' target in Makefile. Add one to run checks before commits." >&2
  else
    make pre-commit 2>&1 || exit 2
  fi
elif echo "$COMMAND" | grep -qE '^git push\b'; then
  if [ ! -f Makefile ]; then
    echo "Warning: No Makefile found. Add a 'pre-push' target to run checks before pushes." >&2
  elif ! make -n pre-push >/dev/null 2>&1; then
    echo "Warning: No 'pre-push' target in Makefile. Add one to run checks before pushes." >&2
  else
    make pre-push 2>&1 || exit 2
  fi
fi

exit 0