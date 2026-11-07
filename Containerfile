FROM debian:13-slim
ARG TARGETARCH
# One workerd release per year, all with arm64 and x64 Linux binaries.
ARG VERSIONS="v1.20230115.0 v1.20231030.0 v1.20241106.0 v1.20251101.0 v1.20261107.1"

# libc++1: early-2023 workerd links libc++ dynamically; later builds are static.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl libc++1 \
 && rm -rf /var/lib/apt/lists/*

# Releases from early 2023 ship the binary uncompressed; later ones gzip it.
RUN case "$TARGETARCH" in arm64) a=arm64 ;; *) a=64 ;; esac \
 && for v in $VERSIONS; do \
      mkdir -p /opt/workerd/$v; \
      base="https://github.com/cloudflare/workerd/releases/download/$v/workerd-linux-$a"; \
      if curl -fsSL -o /tmp/w.gz "$base.gz"; then gunzip -c /tmp/w.gz > /opt/workerd/$v/workerd; \
      else curl -fsSL -o /opt/workerd/$v/workerd "$base"; fi; \
      chmod +x /opt/workerd/$v/workerd; \
    done; rm -f /tmp/w.gz

WORKDIR /lab
CMD ["/lab/run.sh"]
