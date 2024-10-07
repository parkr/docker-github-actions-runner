#!/bin/bash

RUNNER_NAME=$RUNNER_NAME
REPO=$REPO
ACCESS_TOKEN=$TOKEN

cd /home/docker/actions-runner

REG_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${REPO}/actions/runners/registration-token | jq .token --raw-output)
./config.sh --url https://github.com/${REPO} --token ${REG_TOKEN} --name ${RUNNER_NAME}

cleanup() {
    echo "Removing runner..."
    # token is only valid for 1h, so it needs to be re-queried
    # https://github.com/actions/runner/discussions/1799#discussioncomment-2747605
    REG_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${REPO}/actions/runners/registration-token | jq .token --raw-output)
    ./config.sh remove --token ${REG_TOKEN}
}

trap cleanup SIGINT SIGTERM

./run.sh & wait $!
