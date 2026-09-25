FROM ubuntu:24.04

ARG RUNNER_VERSION="2.337.0" \
  CONTAINERD_VERSION="2.2.5" \
  DOCKER_VERSION="29.6.1" \
  BUILDX_VERSION="0.35.0" \
  COMPOSE_VERSION="5.2.0" \
  RV_VERSION="0.6.0" \
  UV_VERSION="0.11.25" \
  COSIGN_VERSION="3.1.3" \
  GO_VERSION="1.27.1" \
  RUSTUP_INIT_VERSION="1.28.2" \
  RUST_TOOLCHAIN_VERSION="1.78.0" \
  ARCH="" \
  INSTRUCTION_SET=""

ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
  && apt-get install -y curl gosu jq sudo \
  && useradd -m runner \
  && usermod -aG sudo runner \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && mkdir /opt/hostedtoolcache \
  && chmod 777 /opt/hostedtoolcache

# AGENT_TOOLSDIRECTORY tells the runner binary where its tool cache lives; it in turn
# exports RUNNER_TOOL_CACHE (read by actions/setup-go, actions/setup-node, etc.) into
# every job, so tools pre-installed below are picked up instead of re-downloaded.
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache \
  RUNNER_TOOL_CACHE=/opt/hostedtoolcache \
  CARGO_HOME=/usr/local/cargo \
  RUSTUP_HOME=/usr/local/rustup \
  PATH=/usr/local/cargo/bin:${PATH}

# install github actions runner
RUN mkdir -p /home/runner/actions-runner \
  && export DERIVED_INSTRUCTION_SET="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/x64/)" \
  && export INSTRUCTION_SET="${INSTRUCTION_SET:-$DERIVED_INSTRUCTION_SET}" \
  && curl -fsSL --connect-timeout 30 --retry 3 https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${INSTRUCTION_SET}-${RUNNER_VERSION}.tar.gz -o /home/runner/actions-runner/actions.tar.gz \
  && cd /home/runner/actions-runner \
  && tar -xzf actions.tar.gz \
  && rm actions.tar.gz \
  && chown -R runner /home/runner/actions-runner \
  && ./bin/installdependencies.sh

# install simple apt packages
RUN apt-get update \
  && apt-get install -y \
  git \
  sshpass \
  lsb-release \
  build-essential \
  jq \
  zip \
  unzip \
  libyaml-dev \
  libgmp-dev \
  dnsutils \
  python3 \
  ca-certificates

# install rust toolchain (cargo >= 1.78)
RUN export RUSTUP_TARGET="$(arch | sed s/aarch64/aarch64-unknown-linux-gnu/ | sed s/x86_64/x86_64-unknown-linux-gnu/)" \
  && export RUSTUP_BASE_URL="https://static.rust-lang.org/rustup/archive/${RUSTUP_INIT_VERSION}/${RUSTUP_TARGET}" \
  && curl -fsSL --connect-timeout 30 --retry 3 "${RUSTUP_BASE_URL}/rustup-init" -o /tmp/rustup-init \
  && curl -fsSL --connect-timeout 30 --retry 3 "${RUSTUP_BASE_URL}/rustup-init.sha256" -o /tmp/rustup-init.sha256 \
  && (cd /tmp && sha256sum -c rustup-init.sha256) \
  && chmod +x /tmp/rustup-init \
  && /tmp/rustup-init -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN_VERSION}" \
  && rm -f /tmp/rustup-init /tmp/rustup-init.sha256 \
  && export CARGO_VERSION="$(cargo --version | awk '{print $2}')" \
  && dpkg --compare-versions "${CARGO_VERSION}" ge "1.78.0" \
  && cargo --version \
  && rustc --version

# install node 24
RUN curl -fsSL --connect-timeout 30 --retry 3 https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y nodejs

# install go, pre-seeded into the hosted tool cache so actions/setup-go finds it there
# instead of downloading it (cache layout: $RUNNER_TOOL_CACHE/go/<version>/<arch>[.complete])
RUN export DERIVED_ARCH="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)" \
  && export ARCH="${ARCH:-$DERIVED_ARCH}" \
  && export DERIVED_INSTRUCTION_SET="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/x64/)" \
  && export INSTRUCTION_SET="${INSTRUCTION_SET:-$DERIVED_INSTRUCTION_SET}" \
  && GO_CACHE_DIR="/opt/hostedtoolcache/go/${GO_VERSION}/${INSTRUCTION_SET}" \
  && mkdir -p "${GO_CACHE_DIR}" \
  && curl -fsSL --connect-timeout 30 --retry 3 https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz -o /tmp/go.tar.gz \
  && tar -xzf /tmp/go.tar.gz -C "${GO_CACHE_DIR}" --strip-components=1 \
  && rm /tmp/go.tar.gz \
  && touch "${GO_CACHE_DIR}.complete" \
  && chmod -R 777 /opt/hostedtoolcache/go \
  && "${GO_CACHE_DIR}/bin/go" version

# install uv
RUN curl -fsSL --connect-timeout 30 --retry 3 https://astral.sh/uv/install.sh | UV_VERSION=${UV_VERSION} UV_INSTALL_DIR=/usr/local/bin sh

# install gh cli
RUN curl -fsSL --connect-timeout 30 --retry 3 -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest \
  | jq -r '.tag_name' \
  | sed 's/^v//g' \
  > /tmp/ghcli_vers.txt \
  && export DERIVED_ARCH="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)" \
  && export ARCH="${ARCH:-$DERIVED_ARCH}" \
  && curl -fsSL --connect-timeout 30 --retry 3 -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest \
  | jq ".assets[] | select(.name == \"gh_$(cat /tmp/ghcli_vers.txt)_linux_${ARCH}.deb\")" \
  | jq -r '.browser_download_url' \
  | curl -fsSL --connect-timeout 30 --retry 3 $(cat -) -o /tmp/ghcli.deb \
  && rm /tmp/ghcli_vers.txt \
  && apt-get install -y /tmp/ghcli.deb \
  && rm /tmp/ghcli.deb

# install rv
RUN export DERIVED_ARCH="$(arch)" \
  && export ARCH="${ARCH:-$DERIVED_ARCH}" \
  && curl -fsSL --connect-timeout 30 --retry 3 -H "Accept: application/vnd.github+json" "https://api.github.com/repos/spinel-coop/rv/releases/tags/v${RV_VERSION}" \
  | jq ".assets[] | select(.name == \"rv-${ARCH}-unknown-linux-gnu.tar.xz\")" \
  | jq -r '.browser_download_url' \
  | curl -fsSL --connect-timeout 30 --retry 3 $(cat -) -o /tmp/rv.tar.xz \
  && tar -xvf /tmp/rv.tar.xz -C /tmp \
  && install -m 755 /tmp/rv-${ARCH}-unknown-linux-gnu/rv /usr/local/bin/rv \
  && ln -s /usr/local/bin/rv /usr/local/bin/rvx \
  && rm /tmp/rv.tar.xz \
  && which rv

# install docker
RUN mkdir -p /home/runner/tmp \
  && cd /home/runner/tmp \
  && export DERIVED_ARCH="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)" \
  && export ARCH="${ARCH:-$DERIVED_ARCH}" \
  && BASE_URL="https://download.docker.com/linux/ubuntu/dists/noble/pool/stable/${ARCH}" \
  && curl -fsSL --connect-timeout 30 --retry 3 ${BASE_URL}/containerd.io_${CONTAINERD_VERSION}-1~ubuntu.24.04~noble_${ARCH}.deb -o ./containerd.io.deb \
  && curl -fsSL --connect-timeout 30 --retry 3 ${BASE_URL}/docker-ce_${DOCKER_VERSION}-1~ubuntu.24.04~noble_${ARCH}.deb -o ./docker-ce.deb \
  && curl -fsSL --connect-timeout 30 --retry 3 ${BASE_URL}/docker-ce-cli_${DOCKER_VERSION}-1~ubuntu.24.04~noble_${ARCH}.deb -o ./docker-ce-cli.deb \
  && curl -fsSL --connect-timeout 30 --retry 3 ${BASE_URL}/docker-buildx-plugin_${BUILDX_VERSION}-1~ubuntu.24.04~noble_${ARCH}.deb -o ./docker-buildx-plugin.deb \
  && curl -fsSL --connect-timeout 30 --retry 3 ${BASE_URL}/docker-compose-plugin_${COMPOSE_VERSION}-1~ubuntu.24.04~noble_${ARCH}.deb -o ./docker-compose-plugin.deb \
  && apt-get install -y $(ls *.deb | sed -e "s/^/.\//") \
  && rm $(ls *.deb) \
  && sed -i 's/ulimit -Hn/# ulimit -Hn/g' /etc/init.d/docker \
  && (getent group docker || groupadd docker > /dev/null) \
  && usermod -aG docker runner

# install cosign, for signing/verifying docker image signatures
RUN export DERIVED_ARCH="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)" \
  && export ARCH="${ARCH:-$DERIVED_ARCH}" \
  && curl -fsSL --connect-timeout 30 --retry 3 https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${ARCH} -o /usr/local/bin/cosign \
  && chmod +x /usr/local/bin/cosign \
  && cosign version

COPY --chmod=755 etc/init.d/docker /etc/init.d/docker

COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
