# ubi10-core Constitution

> **Version:** 1.1.0
> **Ratified:** 2026-03-10
> **Amended:** 2026-10-02
> **Status:** Active
> **Inherits:** [crunchtools/constitution](https://github.com/crunchtools/constitution) v1.18.0
> **Profile:** Container Image

This file holds what is specific to ubi10-core. The fleet rules and the Container
Image profile (license, versioning, LABELs, the RHSM secret-mount pattern,
systemd conventions, registry, testing and quality gates) apply at the
inherited version and are checked against this repo's files by
`constitution.yml`. They are not restated here.

## Purpose

Tier 0 of the layered UBI 10 image tree: troubleshooting tools, cron, central
log forwarding and systemd hardening. Every systemd-based crunchtools image
builds on it, directly or through ubi10-httpd. Published as
`quay.io/crunchtools/ubi10-core`.

## Parent Image

`registry.access.redhat.com/ubi10/ubi-init:latest`, so services run under
systemd. Every package comes from the UBI repos; no RHSM registration.

## Packages and Services

- **Packages:** iputils, bind-utils, net-tools, less, cronie, procps-ng,
  diffutils, rsyslog.
- **Masked:** systemd-remount-fs, systemd-update-done, systemd-udev-trigger.
- **Enabled:** rsyslog, with a `Restart=on-failure` drop-in
  (`config/rsyslog-restart.conf`).

## Central Log Forwarding

`config/rsyslog-forward.conf` forwards the container's internal journal to the
central collector over TCP 514 at the podman bridge gateway, with a
disk-assisted queue (64 MB cap, saved on shutdown) so a collector restart
backs logs up instead of dropping them. It lives here so every image built on
this base gets constitution XIII forwarding without opting in.

## Smoke Test Coverage

`tests/smoke-test.sh` asserts systemd boots, the three services above are
masked, the tool binaries (ping, dig, netstat, less, crontab, ps, diff) are
present, the packages are installed, and the rsyslog forwarding config is in
place and parses.

## Downstream Images

Build dispatches `parent-image-updated` to ubi10-httpd, factory, postiz, rotv,
immich and acquacotta.

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-10 | Initial constitution, tier 0 of the layered image tree |
| 1.0.1 | 2026-09-25 | Gatehouse review, triage and pre-commit gates |
| 1.1.0 | 2026-10-02 | Manifest under constitution v1.18.0: profile restatement removed, image specifics kept |
