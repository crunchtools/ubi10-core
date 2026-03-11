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
    if systemctl is-enabled "$svc" 2>/dev/null | grep -q "masked"; then
        pass "service masked: $svc"
    else
        fail "service not masked: $svc"
    fi
done

# ---------- Tool Binaries ----------
echo "=== Tool Binaries ==="

for bin in ping dig netstat less crontab ps diff; do
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
)

for pkg in "${PACKAGES[@]}"; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        pass "package: $pkg"
    else
        fail "package missing: $pkg"
    fi
done

# ---------- Summary ----------
echo ""
echo "=== Results: $((TESTS - FAILURES))/$TESTS passed ==="

if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES test(s) failed"
    exit 1
fi

echo "All tests passed"
exit 0
