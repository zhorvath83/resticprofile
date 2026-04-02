# resticprofile

This repository builds and publishes a hardened container image for `resticprofile` with bundled `restic` and `rclone`.

The primary goal is to provide a non-root image that works well with `resticprofile schedule` and `supercronic` inside a container.

The image is designed for schedulers and orchestration platforms that prefer:

- a non-root default user
- a read-only root filesystem
- explicit writable mounts instead of implicit image volumes
- multi-architecture publishing through GHCR
- container-native scheduled execution with `supercronic`

## What The Image Includes

- `resticprofile`
- `restic`
- `rclone`
- `supercronic`
- supporting packages needed for TLS, SSH, timezone data, and log rotation

All three backup-related binaries are downloaded from upstream releases during the build and verified with published checksums.
The runtime image keeps the executables under `/usr/bin` to stay aligned with the upstream non-root scheduling pattern.

## Runtime Contract

- Default user: `65532:65532`
- Working directory: `/resticprofile`
- Writable paths required at runtime:
  - `/resticprofile`
  - `/tmp`
- Read-only root filesystem: supported
- Implicit Docker `VOLUME`s: none

The full runtime contract is documented in [docs/runtime.md](/Users/zhorvath83/Projects/personal/resticprofile/docs/runtime.md).
The scheduling model is documented in [docs/scheduling.md](/Users/zhorvath83/Projects/personal/resticprofile/docs/scheduling.md).

## Quick Start

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v "$(pwd)/data:/resticprofile:rw" \
  ghcr.io/<owner>/resticprofile:latest version
```

For scheduled runs, keep the configuration, cache, and generated `crontab` file under `/resticprofile`.

## Scheduling Example

The intended container pattern is:

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v "$(pwd)/profiles.yaml:/resticprofile/profiles.yaml:ro" \
  -v "$(pwd)/data:/resticprofile:rw" \
  --entrypoint /bin/sh \
  ghcr.io/<owner>/resticprofile:latest \
  -c 'resticprofile schedule --all && supercronic /resticprofile/crontab'
```

This follows the upstream non-root container scheduling model based on `supercronic`.

## Kubernetes Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resticprofile
spec:
  containers:
    - name: resticprofile
      image: ghcr.io/<owner>/resticprofile:latest
      args: ["version"]
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

If your cluster overrides the image UID, make sure the mounted volumes remain writable for the effective runtime user or group.

## Development And Maintenance

- Runtime and filesystem expectations: [docs/runtime.md](/Users/zhorvath83/Projects/personal/resticprofile/docs/runtime.md)
- Non-root scheduling model: [docs/scheduling.md](/Users/zhorvath83/Projects/personal/resticprofile/docs/scheduling.md)
- Local development and validation flow: [docs/development.md](/Users/zhorvath83/Projects/personal/resticprofile/docs/development.md)
- Release and publishing model: [docs/release.md](/Users/zhorvath83/Projects/personal/resticprofile/docs/release.md)

## Repository Layout

- [Dockerfile](/Users/zhorvath83/Projects/personal/resticprofile/Dockerfile): multi-stage image build
- [README.md](/Users/zhorvath83/Projects/personal/resticprofile/README.md): project overview
- [.github/workflows/build.yml](/Users/zhorvath83/Projects/personal/resticprofile/.github/workflows/build.yml): multi-arch build, GHCR push, Trivy scan
- [.github/renovate.json5](/Users/zhorvath83/Projects/personal/resticprofile/.github/renovate.json5): dependency update policy
- [AGENTS.md](/Users/zhorvath83/Projects/personal/resticprofile/AGENTS.md): repository-specific assistant guidance
