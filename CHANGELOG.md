# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Removed
- `factory` from the `parent-image-updated` dispatch list: factory.crunchtools.com
  is decommissioned.

### Changed
- Gatehouse triage now receives `review_result`, so a PR whose review job died before posting is held instead of passing.
- Constitution is now a v1.18.0 manifest: fleet and profile rules apply by
  reference, and only this repo's specifics are kept.
- Constitution validation is pinned via `constitution.yml`.
- Dependabot auto-merges GitHub Actions minor and patch updates.
- The container release runs constitution v1.51.0's `container-release.yml`
  (was v1.46.0) and grants it `issues: write`, so a failed scheduled rebuild
  opens an issue instead of only warning. A `v*` promote now also refuses an
  image whose `version` label names a different release of this repo.

## [1.0.0] - 2026-09-20

First tagged release. This image has been running in production since before
it had version control; this release marks the current state as the baseline
going forward.
