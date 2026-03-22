#!/bin/bash
# Run a command with a timeout, capturing output to a log file.
# Usage: run-with-timeout.sh <timeout_seconds> <log_file> <command...>
#
# Exit codes:
#   0   — command succeeded
#   1   — command failed
#   124 — command timed out (killed)

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: $0 <timeout_seconds> <log_file> <command...>"
    exit 1
fi

TIMEOUT_SECS="$1"
LOG_FILE="$2"
shift 2

# Run command with timeout, redirect all output to log
if command -v gtimeout &>/dev/null; then
    # macOS with coreutils installed via brew
    gtimeout --signal=KILL "${TIMEOUT_SECS}s" "$@" > "$LOG_FILE" 2>&1
    EXIT_CODE=$?
elif command -v timeout &>/dev/null; then
    # Linux
    timeout --signal=KILL "${TIMEOUT_SECS}s" "$@" > "$LOG_FILE" 2>&1
    EXIT_CODE=$?
else
    # Fallback: use background process + sleep
    "$@" > "$LOG_FILE" 2>&1 &
    PID=$!
    (
        sleep "$TIMEOUT_SECS"
        kill -9 "$PID" 2>/dev/null
    ) &
    WATCHDOG=$!
    wait "$PID" 2>/dev/null
    EXIT_CODE=$?
    kill "$WATCHDOG" 2>/dev/null
    wait "$WATCHDOG" 2>/dev/null
fi

if [ $EXIT_CODE -eq 137 ] || [ $EXIT_CODE -eq 124 ]; then
    echo "TIMEOUT: command killed after ${TIMEOUT_SECS}s"
    exit 124
fi

exit $EXIT_CODE
