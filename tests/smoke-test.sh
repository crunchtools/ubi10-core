#!/bin/bash
# smoke-test.sh — smoke tests for ubi10-core container image
# Run inside a running container started with --systemd=always
# Exit 0 = all pass, Exit 1 = one or more failures

set -uo pipefail

FAILURES=0
TESTS=0

pass() {
    TESTS=$((TESTS + 1))
    echo "  PASS: $1"
}

fail() {
    TESTS=$((TESTS + 1))
    FAILURES=$((FAILURES + 1))
    echo "  FAIL: $1"
}

# ---------- systemd Boot ----------
echo "=== systemd Boot ==="

if systemctl is-system-running --wait >/dev/null 2>&1 || systemctl is-system-running >/dev/null 2>&1; then
    pass "systemd booted successfully"
else
    STATE=$(systemctl is-system-running 2>/dev/null || true)
    if [ "$STATE" = "running" ] || [ "$STATE" = "degraded" ]; then
        pass "systemd booted (state: $STATE)"
    else
        fail "systemd did not boot (state: $STATE)"
    fi
fi

# ---------- Masked Services ----------
echo "=== Masked Services ==="

for svc in systemd-remount-fs systemd-update-done systemd-udev-trigger; do
    ENABLED_STATE=$(systemctl is-enabled "${svc}.service" 2>/dev/null || true)
    UNIT_FILE=$(systemctl show -p FragmentPath "${svc}.service" 2>/dev/null | cut -d= -f2 || true)
    if [ "$ENABLED_STATE" = "masked" ] || [ "$UNIT_FILE" = "/dev/null" ] || \
       readlink -f "/etc/systemd/system/${svc}.service" 2>/dev/null | grep -q "/dev/null"; then
        pass "service masked: $svc"
    else
        fail "service not masked: $svc (is-enabled=$ENABLED_STATE, unit=$UNIT_FILE)"
    fi
done

# ---------- Tool Binaries ----------
echo "=== Tool Binaries ==="

for bin in ping dig netstat less crontab ps diff rsyslogd; do
    if command -v "$bin" >/dev/null 2>&1; then
        pass "binary exists: $bin"
    else
        fail "binary missing: $bin"
    fi
done

# ---------- Package Integrity ----------
echo "=== Package Integrity ==="

PACKAGES=(
    iputils
    bind-utils
    net-tools
    less
    cronie
    procps-ng
    diffutils
    rsyslog
)

for pkg in "${PACKAGES[@]}"; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        pass "package: $pkg"
    else
        fail "package missing: $pkg"
    fi
done

# ---------- Central Log Forwarding (constitution XIII) ----------
echo "=== Central Log Forwarding ==="

# The forwarding config is the whole point of shipping rsyslog here. Without it
# a systemd container's internal journal never reaches the collector, and the
# loss is silent — the container looks healthy the entire time.
if [ -f /etc/rsyslog.d/00-crunchtools-forward.conf ]; then
    pass "forwarding config present"
else
    fail "forwarding config missing: /etc/rsyslog.d/00-crunchtools-forward.conf"
fi

if grep -q 'omfwd' /etc/rsyslog.d/00-crunchtools-forward.conf 2>/dev/null; then
    pass "forwarding config declares omfwd action"
else
    fail "forwarding config does not forward anywhere"
fi

# The drop-in must NOT re-declare imjournal or workDirectory: the stock
# /etc/rsyslog.conf already sets both, and rsyslog rejects the entire
# configuration on a duplicate, which would leave the container with no
# logging at all.
if grep -vE '^[[:space:]]*#' /etc/rsyslog.d/00-crunchtools-forward.conf 2>/dev/null \
     | grep -qE 'module\(load="imjournal|workDirectory'; then
    fail "forwarding config re-declares imjournal/workDirectory (duplicate breaks all logging)"
else
    pass "forwarding config does not duplicate stock module/global declarations"
fi

# A config that rsyslog cannot parse would leave the service dead on arrival.
# Capture the output rather than discarding it: a bare pass/fail here tells you
# nothing when this trips only on a different runtime (rootless CI vs rootful
# host), and that is precisely when you need the message.
RSYSLOG_VALIDATION=$(rsyslogd -N1 2>&1)
RSYSLOG_RC=$?
if [ "$RSYSLOG_RC" -eq 0 ]; then
    pass "rsyslog config validates"
else
    fail "rsyslog config failed validation (rsyslogd -N1, rc=$RSYSLOG_RC)"
    echo "$RSYSLOG_VALIDATION" | sed 's/^/        /'
fi

ENABLED=$(systemctl is-enabled rsyslog.service 2>/dev/null || true)
if [ "$ENABLED" = "enabled" ]; then
    pass "rsyslog enabled at boot"
else
    fail "rsyslog not enabled at boot (is-enabled=$ENABLED)"
fi

# Host-level Restart=always only restarts the container; a service that dies
# inside a still-running container needs its own drop-in (container-image
# profile III.5).
if [ -f /etc/systemd/system/rsyslog.service.d/restart.conf ]; then
    pass "rsyslog self-heal drop-in present"
else
    fail "rsyslog self-heal drop-in missing"
fi

# ---------- Summary ----------
echo ""
echo "=== Results: $((TESTS - FAILURES))/$TESTS passed ==="

if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES test(s) failed"
    exit 1
fi

echo "All tests passed"
exit 0
