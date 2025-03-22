FROM ubuntu:22.04

ARG RUNNER_VERSION="2.322.0" \
  CONTAINERD_VERSION="1.7.25" \
  DOCKER_VERSION="28.0.1" \
  BUILDX_VERSION="0.21.1" \
  COMPOSE_VERSION="2.33.1"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y curl jq sudo \
  && useradd -m runner \
  && usermod -aG sudo runner \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# install github actions runner
RUN mkdir -p /home/runner/actions-runner \
  && curl -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -o /home/runner/actions-runner/actions.tar.gz \
  && cd /home/runner/actions-runner \
  && tar -xzf actions.tar.gz \
  && rm actions.tar.gz \
  && chown -R runner /home/runner/actions-runner \
  && ./bin/installdependencies.sh

# install git
RUN apt-get update \
  && apt-get install -y git

# install gh cli
RUN curl -sL -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest \
  | jq -r '.tag_name' \
  | sed 's/^v//g' \
  > /tmp/ghcli_vers.txt \
  && curl -sL -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest \
  | jq ".assets[] | select(.name == \"gh_$(cat /tmp/ghcli_vers.txt)_linux_amd64.deb\")" \
  | jq -r '.browser_download_url' \
  | curl -sSLo /tmp/ghcli.deb \
  && rm /tmp/ghcli_vers.txt \
  && apt-get install -y /tmp/ghcli.deb \
  && rm /tmp/ghcli.deb

# install docker
RUN mkdir -p /home/runner/tmp \
  && cd /home/runner/tmp \
  && BASE_URL="https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64" \
  && curl -L ${BASE_URL}/containerd.io_${CONTAINERD_VERSION}-1_amd64.deb -o ./containerd.io.deb \
  && curl -L ${BASE_URL}/docker-ce_${DOCKER_VERSION}-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-ce.deb \
  && curl -L ${BASE_URL}/docker-ce-cli_${DOCKER_VERSION}-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-ce-cli.deb \
  && curl -L ${BASE_URL}/docker-buildx-plugin_${BUILDX_VERSION}-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-buildx-plugin.deb \
  && curl -L ${BASE_URL}/docker-compose-plugin_${COMPOSE_VERSION}-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-compose-plugin.deb \
  && apt-get install -y $(ls *.deb | sed -e "s/^/.\//") \
  && rm $(ls *.deb) \
  && sed -i 's/ulimit -Hn/# ulimit -Hn/g' /etc/init.d/docker \
  && getent group docker || groupadd docker > /dev/null \
  && usermod -aG docker runner

COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

# switch to the runner user
USER runner

ENTRYPOINT ["/entrypoint.sh"]
