#!/bin/bash
set -e

if [[ -n "$DISPLAY" && -x /usr/bin/wireshark ]]; then
    exec /usr/bin/wireshark "$@"
fi

echo "No DISPLAY detected; running tshark fallback in headless mode." >&2
exec /usr/bin/tshark "$@"
