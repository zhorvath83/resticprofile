# syntax=docker/dockerfile:1.7

FROM alpine:3.22 AS downloader

ARG TARGETARCH

# renovate: datasource=github-releases depName=creativeprojects/resticprofile
ARG RESTICPROFILE_VERSION=0.32.0
# renovate: datasource=github-releases depName=restic/restic
ARG RESTIC_VERSION=0.18.1
# renovate: datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION=1.73.3

RUN apk add --no-cache bzip2 ca-certificates curl unzip

RUN case "${TARGETARCH}" in \
      amd64) export ARCH=amd64 ;; \
      arm64) export ARCH=arm64 ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    export RESTICPROFILE_TARBALL="resticprofile_${RESTICPROFILE_VERSION}_linux_${ARCH}.tar.gz" && \
    export RESTIC_BUNDLE="restic_${RESTIC_VERSION}_linux_${ARCH}.bz2" && \
    export RCLONE_BUNDLE="rclone-v${RCLONE_VERSION}-linux-${ARCH}.zip" && \
    curl --fail --silent --show-error --location \
      --output /tmp/resticprofile.checksums.txt \
      "https://github.com/creativeprojects/resticprofile/releases/download/v${RESTICPROFILE_VERSION}/checksums.txt" && \
    curl --fail --silent --show-error --location \
      --output "/tmp/${RESTICPROFILE_TARBALL}" \
      "https://github.com/creativeprojects/resticprofile/releases/download/v${RESTICPROFILE_VERSION}/${RESTICPROFILE_TARBALL}" && \
    cd /tmp && \
    grep " ${RESTICPROFILE_TARBALL}\$" resticprofile.checksums.txt | sha256sum -c - && \
    tar -xzf "${RESTICPROFILE_TARBALL}" && \
    mkdir -p /out && \
    install -m 0755 "$(find /tmp -maxdepth 2 -type f -name resticprofile -print -quit)" /out/resticprofile && \
    curl --fail --silent --show-error --location \
      --output /tmp/restic.SHA256SUMS \
      "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/SHA256SUMS" && \
    curl --fail --silent --show-error --location \
      --output "/tmp/${RESTIC_BUNDLE}" \
      "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/${RESTIC_BUNDLE}" && \
    grep " ${RESTIC_BUNDLE}\$" /tmp/restic.SHA256SUMS | (cd /tmp && sha256sum -c -) && \
    bzip2 -dc "/tmp/${RESTIC_BUNDLE}" > /out/restic && \
    chmod 0755 /out/restic && \
    curl --fail --silent --show-error --location \
      --output /tmp/rclone.SHA256SUMS \
      "https://downloads.rclone.org/v${RCLONE_VERSION}/SHA256SUMS" && \
    curl --fail --silent --show-error --location \
      --output "/tmp/${RCLONE_BUNDLE}" \
      "https://downloads.rclone.org/v${RCLONE_VERSION}/${RCLONE_BUNDLE}" && \
    grep " ${RCLONE_BUNDLE}\$" /tmp/rclone.SHA256SUMS | (cd /tmp && sha256sum -c -) && \
    unzip -p "/tmp/${RCLONE_BUNDLE}" "rclone-v${RCLONE_VERSION}-linux-${ARCH}/rclone" > /out/rclone && \
    chmod 0755 /out/rclone

FROM alpine:3.22

LABEL org.opencontainers.image.description="Non-root resticprofile container with restic and rclone bundled"
LABEL org.opencontainers.image.documentation="https://creativeprojects.github.io/resticprofile/"

ENV HOME=/resticprofile \
    PATH=/usr/bin:/usr/sbin:/bin:/sbin \
    SHELL=/bin/sh \
    TMPDIR=/tmp \
    TZ=Etc/UTC \
    XDG_CACHE_HOME=/tmp/.cache \
    XDG_CONFIG_HOME=/resticprofile/.config \
    XDG_DATA_HOME=/resticprofile/.local/share

COPY --from=downloader /out/restic /usr/bin/restic
COPY --from=downloader /out/rclone /usr/bin/rclone
COPY --from=downloader /out/resticprofile /usr/bin/resticprofile

RUN apk add --no-cache ca-certificates curl logrotate openssh-client-default supercronic tzdata && \
    addgroup -S -g 65532 restic && \
    adduser -S -D -H -h /resticprofile -s /sbin/nologin -G restic -u 65532 restic && \
    mkdir -p /resticprofile /tmp && \
    touch /resticprofile/crontab && \
    chmod 1777 /tmp && \
    chown -R restic:restic /resticprofile /tmp

WORKDIR /resticprofile
USER 65532:65532

ENTRYPOINT ["resticprofile"]
CMD ["--help"]
