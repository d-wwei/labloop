#!/bin/bash
# Extract a metric value from a log file using a grep/regex pattern.
# Usage: extract-metric.sh <log_file> <extract_command>
#
# The extract_command is evaluated as a shell command.
# It should output a single line containing the metric value.
#
# Exit codes:
#   0 — metric extracted successfully (value printed to stdout)
#   1 — metric not found (crash or extraction failure)

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <log_file> <extract_command>"
    exit 1
fi

LOG_FILE="$1"
shift
EXTRACT_CMD="$*"

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: log file not found: $LOG_FILE"
    exit 1
fi

# Run the extraction command, replacing {log} with the actual log path
CMD="${EXTRACT_CMD//\{log\}/$LOG_FILE}"
RESULT=$(eval "$CMD" 2>/dev/null || true)

if [ -z "$RESULT" ]; then
    echo "ERROR: metric extraction returned empty result"
    exit 1
fi

# Extract the numeric value (first number found in the result)
VALUE=$(echo "$RESULT" | grep -oE '[0-9]+\.?[0-9]*' | head -1)

if [ -z "$VALUE" ]; then
    echo "ERROR: no numeric value found in: $RESULT"
    exit 1
fi

echo "$VALUE"
