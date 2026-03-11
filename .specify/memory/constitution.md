# ubi10-core Constitution

> **Version:** 1.0.0
> **Ratified:** 2026-03-10
> **Status:** Active
> **Inherits:** [crunchtools/constitution](https://github.com/crunchtools/constitution) v1.0.0
> **Profile:** Container Image

UBI 10 core base image providing troubleshooting tools, cron, and systemd hardening. Foundation layer for all CrunchTools container images.

---

## License

AGPL-3.0-or-later

## Versioning

Follow Semantic Versioning 2.0.0. MAJOR/MINOR/PATCH.

## Base Image

`registry.access.redhat.com/ubi10/ubi-init:latest` — systemd-based for multi-service containers.

## Registry

Published to `quay.io/crunchtools/ubi10-core`.

## RHSM Registration

Not required. All packages are available in UBI repos.

## Containerfile Conventions

- Uses `Containerfile` (not Dockerfile)
- Required LABELs: `maintainer`, `description`
- `dnf install -y` followed by `dnf clean all`
- No RHSM registration needed
- systemd services masked: systemd-remount-fs, systemd-update-done, systemd-udev-trigger
- `STOPSIGNAL SIGRTMIN+3` for proper systemd shutdown
- `ENTRYPOINT ["/sbin/init"]`

## Packages Installed

iputils, bind-utils, net-tools, less, cronie, procps-ng, diffutils

## Testing

- **Build test**: CI builds the image on every push to main/master
- **Smoke tests**: systemd boot, masked services (3), tool binaries (ping, dig, netstat, less, crontab, ps, diff), package integrity (7 packages)
- **Security scan**: Recommended (not yet implemented)

## Quality Gates

1. Build — CI builds the Containerfile successfully
2. Test — smoke tests pass (systemd boots, services masked, tools present, packages verified)
3. Push — image published only after tests pass
4. Weekly rebuild — cron job picks up base image updates every Monday 4:00 AM UTC

## Downstream Images

ubi10-httpd (direct child). Changes to this image cascade to all CrunchTools container images via repository_dispatch.
