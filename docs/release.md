# Release And Publishing Model

This document explains how the image is built and published.

## Registry

Published images go to:

- `ghcr.io/<owner>/<repository>`

The workflow uses `${{ github.repository }}` as the image name, so the repository path becomes the GHCR package path.

## Workflow Triggers

The publish workflow lives in `.github/workflows/build.yml` and runs on:

- pushes to `main`
- pushes to tags matching `v*`
- pull requests targeting `main`
- manual `workflow_dispatch`

## Build Behavior

The workflow:

- builds for `linux/amd64` and `linux/arm64`
- logs in to GHCR for non-PR events
- generates OCI metadata tags
- pushes images only for non-PR events
- uploads a Trivy SARIF report for published builds

## Tagging Model

The metadata action generates tags from the upstream `RESTICPROFILE_VERSION` pinned in `Dockerfile`:

- the exact upstream version, for example `0.32.0`
- the upstream major-minor line, for example `0.32`
- `latest` for the default branch
- `sha-<commit>` tags

This means:

- published version tags follow the bundled upstream `resticprofile` release number
- `main` pushes refresh the upstream-aligned version tags and `latest`
- pull requests build but do not publish

## Release Expectations

When cutting a release:

1. make sure the Dockerfile pins and documentation are current
2. merge or push the version bump that updates `RESTICPROFILE_VERSION`
3. verify the GHCR package and workflow results

## Supply Chain Notes

The Dockerfile downloads upstream release assets and verifies them against published checksums before they enter the runtime image.

If upstream packaging changes:

- update the download URLs
- update the checksum source paths
- revalidate both supported architectures

Do not weaken checksum validation to make upstream layout changes easier to accommodate.
