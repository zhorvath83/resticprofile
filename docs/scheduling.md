# Scheduling Model

This repository exists primarily to support non-root scheduled execution of `resticprofile` inside a container with `supercronic`.

The upstream reference pattern is documented here:

- [User schedule in container :: resticprofile](https://creativeprojects.github.io/resticprofile/schedules/non-root-schedule-in-container/index.html)

## Intended Execution Pattern

The image itself keeps the normal `resticprofile` entrypoint. Scheduled execution is expected to override the entrypoint or command and run a shell similar to:

```sh
resticprofile schedule --all && supercronic /resticprofile/crontab
```

That flow does two things:

- generates the user-owned crontab file under `/resticprofile`
- starts `supercronic` as a non-root process using that generated schedule

## Required Runtime Inputs

For the scheduling flow to work reliably, provide:

- a writable `/resticprofile`
- a writable `/tmp`
- a readable `profiles.yaml` or equivalent config under `/resticprofile`
- any credentials, key files, repositories, or source mounts required by your backup profile

## Docker Example

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v "$(pwd)/profiles.yaml:/resticprofile/profiles.yaml:ro" \
  -v "$(pwd)/repository:/repository" \
  -v "$(pwd)/source:/source:ro" \
  -v "$(pwd)/state:/resticprofile:rw" \
  --entrypoint /bin/sh \
  ghcr.io/<owner>/resticprofile:latest \
  -c 'resticprofile schedule --all && supercronic /resticprofile/crontab'
```

## Configuration Notes

The upstream pattern expects the scheduler output to target `/resticprofile/crontab`, for example:

```yaml
global:
  scheduler: crontab:-:/resticprofile/crontab
```

For user-level cron generation in a container, the profile should use:

```yaml
backup:
  schedule-permission: user
```

## Kubernetes Notes

In Kubernetes, keep the same execution model:

- mount writable storage at `/resticprofile`
- mount writable temporary storage at `/tmp`
- run with `runAsNonRoot: true`
- enable `readOnlyRootFilesystem: true` when the surrounding mounts satisfy the write requirements

If you override the runtime UID or GID, make sure the mounted `/resticprofile` path still allows the generated crontab file to be created and read by `supercronic`.
