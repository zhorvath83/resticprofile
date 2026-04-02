# Runtime Contract

This document defines the runtime expectations of the published `resticprofile` image.

## Goals

The image is built to support:

- non-root execution by default
- read-only root filesystem deployments
- explicit writable mounts
- predictable behavior across Docker and Kubernetes
- non-root scheduled execution with `resticprofile schedule` and `supercronic`

## Default Runtime Settings

- User: `65532:65532`
- Working directory: `/resticprofile`
- Entrypoint: `resticprofile`
- Default command: `--help`

These defaults may be overridden by the runtime platform. In Kubernetes, for example, `securityContext.runAsUser` can replace the image user.

## Filesystem Expectations

The image assumes the following writable locations exist at runtime:

- `/resticprofile`
- `/tmp`

Everything else should be treated as read-only.

The image does not declare Docker `VOLUME`s. Runtime mounts stay explicit so orchestrators and users keep control over persistence and permissions.

## Environment

The image sets the following runtime environment variables:

- `HOME=/resticprofile`
- `TMPDIR=/tmp`
- `TZ=Etc/UTC`
- `XDG_CACHE_HOME=/tmp/.cache`
- `XDG_CONFIG_HOME=/resticprofile/.config`
- `XDG_DATA_HOME=/resticprofile/.local/share`

These values are chosen so cache, config, and application state remain compatible with a read-only root filesystem.

## Bundled Binaries

The image contains:

- `resticprofile`
- `restic`
- `rclone`
- `supercronic`

Supporting packages are installed for certificate handling, SSH-based backends, timezone data, and log rotation.

The detailed scheduling model is documented in [docs/scheduling.md](/Users/zhorvath83/Projects/personal/resticprofile/docs/scheduling.md).

## Docker Example

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v "$(pwd)/data:/resticprofile:rw" \
  ghcr.io/<owner>/resticprofile:latest version
```

## Kubernetes Example

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: resticprofile
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: resticprofile
              image: ghcr.io/<owner>/resticprofile:latest
              args: ["run-schedule", "daily"]
              securityContext:
                runAsNonRoot: true
                readOnlyRootFilesystem: true
              volumeMounts:
                - name: data
                  mountPath: /resticprofile
                - name: tmp
                  mountPath: /tmp
          volumes:
            - name: data
              persistentVolumeClaim:
                claimName: resticprofile
            - name: tmp
              emptyDir: {}
```

If you set `runAsUser`, `runAsGroup`, or `fsGroup`, verify that the mounted storage remains writable for the effective identity.

## Operational Notes

- Keep configuration, generated schedules, and runtime state under `/resticprofile`.
- Use `/tmp` for transient files only.
- Do not rely on writes anywhere under `/usr`, `/etc`, or `/var` unless the image contract changes intentionally.
