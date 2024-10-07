FROM ubuntu:22.04

ARG RUNNER_VERSION="2.319.1"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y curl jq git \
  && useradd -m docker \
  && mkdir -p /home/docker/actions-runner

RUN curl -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -o /home/docker/actions-runner/actions.tar.gz \
  && cd /home/docker/actions-runner \
  && tar -xzf actions.tar.gz \
  && rm actions.tar.gz \
  && chown -R docker /home/docker/actions-runner

RUN /home/docker/actions-runner/bin/installdependencies.sh

COPY --chmod=755 scripts/start.sh /start.sh

# switch to the docker user
USER docker

ENTRYPOINT ["/start.sh"]
