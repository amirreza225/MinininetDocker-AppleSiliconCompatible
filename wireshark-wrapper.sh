#!/bin/bash

REAL_WIRESHARK=/usr/bin/wireshark

if [[ -z "$DISPLAY" || ! -x "$REAL_WIRESHARK" ]]; then
    echo "No GUI available; running tshark fallback in headless mode." >&2
    exec /usr/bin/tshark "$@"
fi

host="${DISPLAY%%:*}"
screen="${DISPLAY##*:}"

if [[ -z "$host" || "$host" == "unix" ]]; then
    # Unix socket — connect directly
    exec env QT_XCB_GL_INTEGRATION=none LIBGL_ALWAYS_INDIRECT=1 "$REAL_WIRESHARK" "$@"
fi

# TCP display (e.g. host.docker.internal:0).
# Mininet host network namespaces have no route to the host directly,
# so tunnel X11 via the root namespace the same way Mininet's makeTerm does.
port=$((6000 + ${screen%%.*}))
SOCAT_PID=""

if ! ss -tlnp 2>/dev/null | grep -q ":${port}[[:space:]]"; then
    escaped="TCP\\:${host}\\:${port}"
    # Bind to 127.0.0.1 so the relay is not exposed beyond the local machine.
    socat "TCP-LISTEN:${port},bind=127.0.0.1,fork,reuseaddr" \
          "EXEC:'mnexec -a 1 socat STDIO ${escaped}'" &
    SOCAT_PID=$!
    sleep 0.3
fi

LOCAL_DISPLAY="localhost:${screen}"

# Forward the Xauthority cookie to the localhost display so MIT-MAGIC-COOKIE
# auth works when ~/.Xauthority has an entry for the original TCP host.
if command -v xauth >/dev/null 2>&1; then
    cookie=$(xauth list "$DISPLAY" 2>/dev/null | awk '{print $3}' | head -1)
    if [[ -n "$cookie" ]]; then
        xauth add "$LOCAL_DISPLAY" MIT-MAGIC-COOKIE-1 "$cookie" 2>/dev/null || true
    fi
fi

env DISPLAY="$LOCAL_DISPLAY" \
    QT_XCB_GL_INTEGRATION=none \
    LIBGL_ALWAYS_INDIRECT=1 \
    "$REAL_WIRESHARK" "$@"
EXIT_CODE=$?

[[ -n "$SOCAT_PID" ]] && kill "$SOCAT_PID" 2>/dev/null || true
exit "$EXIT_CODE"
