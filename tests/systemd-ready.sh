#!/bin/bash
# Ready once systemd has finished booting: running, or degraded (a unit the
# smoke tests then judge). Anything else, still starting, so not yet.
state=$(systemctl is-system-running 2>/dev/null || true)
case "$state" in running|degraded) exit 0 ;; *) exit 1 ;; esac
