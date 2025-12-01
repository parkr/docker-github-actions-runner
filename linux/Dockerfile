FROM ubuntu:22.04

ARG RUNNER_VERSION="2.329.0" \
  CONTAINERD_VERSION="1.7.27" \
  DOCKER_VERSION="28.5.1" \
  BUILDX_VERSION="0.29.1" \
  COMPOSE_VERSION="2.40.2" \
  ARCH="" \
  INSTRUCTION_SET=""

ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
  && apt-get install -y curl jq sudo \
  && useradd -m runner \
  && usermod -aG sudo runner \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && mkdir /opt/hostedtoolcache \
  && chmod 777 /opt/hostedtoolcache

# install github actions runner
RUN mkdir -p /home/runner/actions-runner \
  && export DERIVED_INSTRUCTION_SET="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/x64/)" \
  && export INSTRUCTION_SET="${INSTRUCTION_SET:-$DERIVED_INSTRUCTION_SET}" \
  && curl -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${INSTRUCTION_SET}-${RUNNER_VERSION}.tar.gz -o /home/runner/actions-runner/actions.tar.gz \
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
  dnsutils

# install gh cli
RUN curl -L -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest \
  | jq -r '.tag_name' \
  | sed 's/^v//g' \
  > /tmp/ghcli_vers.txt \
  && export DERIVED_ARCH="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)" \
  && export ARCH="${ARCH:-$DERIVED_ARCH}" \
  && curl -L -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest \
  | jq ".assets[] | select(.name == \"gh_$(cat /tmp/ghcli_vers.txt)_linux_${ARCH}.deb\")" \
  | jq -r '.browser_download_url' \
  | curl -L $(cat -) -o /tmp/ghcli.deb \
  && rm /tmp/ghcli_vers.txt \
  && apt-get install -y /tmp/ghcli.deb \
  && rm /tmp/ghcli.deb

# install docker
RUN mkdir -p /home/runner/tmp \
  && cd /home/runner/tmp \
  && export DERIVED_ARCH="$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)" \
  && export ARCH="${ARCH:-$DERIVED_ARCH}" \
  && BASE_URL="https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/${ARCH}" \
  && curl -L ${BASE_URL}/containerd.io_${CONTAINERD_VERSION}-1_${ARCH}.deb -o ./containerd.io.deb \
  && curl -L ${BASE_URL}/docker-ce_${DOCKER_VERSION}-1~ubuntu.22.04~jammy_${ARCH}.deb -o ./docker-ce.deb \
  && curl -L ${BASE_URL}/docker-ce-cli_${DOCKER_VERSION}-1~ubuntu.22.04~jammy_${ARCH}.deb -o ./docker-ce-cli.deb \
  && curl -L ${BASE_URL}/docker-buildx-plugin_${BUILDX_VERSION}-1~ubuntu.22.04~jammy_${ARCH}.deb -o ./docker-buildx-plugin.deb \
  && curl -L ${BASE_URL}/docker-compose-plugin_${COMPOSE_VERSION}-1~ubuntu.22.04~jammy_${ARCH}.deb -o ./docker-compose-plugin.deb \
  && apt-get install -y $(ls *.deb | sed -e "s/^/.\//") \
  && rm $(ls *.deb) \
  && sed -i 's/ulimit -Hn/# ulimit -Hn/g' /etc/init.d/docker \
  && getent group docker || groupadd docker > /dev/null \
  && usermod -aG docker runner

COPY --chmod=755 etc/init.d/docker /etc/init.d/docker

COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

# switch to the runner user
USER runner

ENTRYPOINT ["/entrypoint.sh"]
