#!/bin/bash
set -e

if [[ -n "${DISPLAY:-}" ]]; then
    exec /usr/bin/wireshark "$@"
fi

echo "No DISPLAY detected; running tshark fallback in headless mode." >&2
exec /usr/bin/tshark "$@"
