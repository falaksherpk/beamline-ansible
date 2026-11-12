# CI image for beamline-ansible's lint jobs (handbook Ch40). The pattern of tango-devices'
# ci/Dockerfile (Part 4 Ch34): the base pinned by digest, one venv from a hash-locked lock,
# nothing resolved at build time. Build context: this ci/ directory of one commit; the image
# is tagged with that commit and named by tag and digest in .gitlab-ci.yml.
FROM docker.io/library/ubuntu:24.04@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55

ENV DEBIAN_FRONTEND=noninteractive
# python3.12 and shellcheck from Ubuntu 24.04, as on admin and beamlinehost (Ch40 R1; Ch39
# P0-R1: ShellCheck 0.9.0); git for ansible-lint and the file lists; curl for promtool.
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3.12 python3.12-venv shellcheck git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# promtool, for the alert rules' unit tests, at the version the prometheus role installs on
# obs. Keep both values in step with roles/prometheus/defaults/main.yml: the promtool job
# fails if the versions differ.
ARG PROMETHEUS_VERSION=3.13.4
ARG PROMETHEUS_SHA256=87f21a66f96c597a189cef8d640e8921b621fc17a9feff707c332c4f3b3ddd56
RUN curl -fsSL -o /tmp/prometheus.tar.gz \
      "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" \
 && echo "${PROMETHEUS_SHA256}  /tmp/prometheus.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/prometheus.tar.gz -C /usr/local/bin --strip-components=1 \
      "prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool" \
 && rm /tmp/prometheus.tar.gz

# Every wheel is checked against its hash, none is built from source, nothing is resolved:
# requirements.txt is the complete set (compiled from requirements.in), which pip check confirms.
COPY requirements.txt /tmp/requirements.txt
RUN python3.12 -m venv /opt/ci-venv \
 && /opt/ci-venv/bin/python -m pip --disable-pip-version-check --no-cache-dir install --quiet \
      --require-hashes --only-binary :all: --no-deps -r /tmp/requirements.txt \
 && /opt/ci-venv/bin/python -m pip --disable-pip-version-check check \
 && rm /tmp/requirements.txt
ENV PATH=/opt/ci-venv/bin:$PATH

WORKDIR /builds
