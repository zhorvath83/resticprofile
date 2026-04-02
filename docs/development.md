# Development Guide

This document describes the expected maintenance workflow for the repository.

## Repository Scope

The repository is intentionally small. It owns:

- the container image build in `Dockerfile`
- the GitHub Actions publishing flow in `.github/workflows/build.yml`
- the Renovate policy in `.github/renovate.json5`
- the project and runtime documentation

It does not build `resticprofile` from source. The image assembles upstream release artifacts.
Its primary runtime use case is non-root scheduled execution with `supercronic`.

## Local Build

Use Docker to validate image changes when the local daemon is available:

```bash
docker build -t resticprofile:test .
```

If you need a specific architecture locally:

```bash
docker build --platform linux/amd64 -t resticprofile:test .
```

## Local Smoke Tests

Basic command execution:

```bash
docker run --rm resticprofile:test version
```

Read-only filesystem smoke test:

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v "$(pwd)/data:/resticprofile:rw" \
  resticprofile:test version
```

Scheduling smoke test:

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v "$(pwd)/profiles.yaml:/resticprofile/profiles.yaml:ro" \
  -v "$(pwd)/data:/resticprofile:rw" \
  --entrypoint /bin/sh \
  resticprofile:test \
  -c 'resticprofile schedule --all && test -s /resticprofile/crontab'
```

## Dependency Updates

The Dockerfile pins release versions through `ARG` values with inline `# renovate:` annotations.

When changing versions manually:

- preserve the annotation directly above the pinned `ARG`
- keep checksum validation intact
- do not replace pinned versions with floating tags or untracked downloads

Renovate is expected to update:

- GitHub Actions references
- the Alpine base image through Dockerfile parsing
- release-backed version arguments matched by the custom regex manager

## Validation Expectations

After relevant changes:

- For documentation-only changes: review links and examples for consistency.
- For workflow changes: validate YAML syntax and inspect GitHub Actions expressions carefully.
- For Dockerfile changes: run a real `docker build` when possible.
- For release asset download changes: confirm that filenames and checksum sources still match upstream conventions.

## Change Discipline

- Keep the repository deterministic and minimal.
- Preserve the non-root and read-only filesystem design unless the task explicitly changes it.
- Prefer explicit documentation whenever a change alters runtime or release behavior.
