#!/bin/bash
# The contract test for container-release.yml: boot $IMAGE (the gated digest)
# under systemd and run the smoke tests inside it.
set -euo pipefail
: "${IMAGE:?IMAGE is the digest under test}"
name="contract-$$"
podman run -d --name "$name" --systemd=always "$IMAGE" >/dev/null
trap 'podman rm -f "$name" >/dev/null' EXIT
for _ in $(seq 1 60); do
    state=$(podman exec "$name" systemctl is-system-running 2>/dev/null || true)
    case "$state" in running|degraded) break ;; esac
    sleep 1
done
podman cp tests/smoke-test.sh "$name:/tmp/smoke-test.sh"
podman exec "$name" bash /tmp/smoke-test.sh
