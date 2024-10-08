FROM ubuntu:22.04

ARG RUNNER_VERSION="2.320.0"

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

# install docker
RUN mkdir -p /home/runner/tmp \
  && cd /home/runner/tmp \
  && BASE_URL="https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64" \
  && curl -L ${BASE_URL}/containerd.io_1.7.22-1_amd64.deb -o ./containerd.io.deb \
  && curl -L ${BASE_URL}/docker-ce_27.3.1-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-ce.deb \
  && curl -L ${BASE_URL}/docker-ce-cli_27.3.1-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-ce-cli.deb \
  && curl -L ${BASE_URL}/docker-buildx-plugin_0.17.1-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-buildx-plugin.deb \
  && curl -L ${BASE_URL}/docker-compose-plugin_2.29.7-1~ubuntu.22.04~jammy_amd64.deb -o ./docker-compose-plugin.deb \
  && apt-get install -y $(ls *.deb | sed -e "s/^/.\//") \
  && rm $(ls *.deb) \
  && sed -i 's/ulimit -Hn/# ulimit -Hn/g' /etc/init.d/docker \
  && getent group docker || groupadd docker > /dev/null \
  && usermod -aG docker runner

# install docker
#RUN mkdir -p /home/runner/tmp \
#  && cd /home/runner/tmp \
#  && curl -L https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz -o docker.tgz \
#  && tar xzvf docker.tgz -C /usr/local/bin/ \
#  && rm docker.tgz 

COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

# switch to the runner user
USER runner

ENTRYPOINT ["/entrypoint.sh"]
