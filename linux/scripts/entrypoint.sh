#!/bin/bash

set -o nounset

# [SETUP]

# start docker
echo "Starting docker..."
sudo service docker start > /dev/null
sleep 5
if [[ $(service docker status) == *"Docker is running"* ]]; then
    echo "Done!"
else
    echo "Docker didn't start, status is:"
    echo $(service docker status)
    exit 1
fi

# [START]

echo "Registering runner..."

cd /home/runner/actions-runner

REG_TOKEN=$(curl -X POST -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${REPO}/actions/runners/registration-token | jq .token --raw-output)

./config.sh \
    --url https://github.com/${REPO} \
    --token ${REG_TOKEN} \
    --name "${RUNNER_NAME:-"runner-ubuntu"}-$HOSTNAME" \
    --unattended \
    --labels "${EXTRA_LABELS:-}"

cleanup() {
    echo "Removing runner..."
    # token is only valid for 1h, so it needs to be re-queried
    # https://github.com/actions/runner/discussions/1799#discussioncomment-2747605
    REG_TOKEN=$(curl -X POST -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${REPO}/actions/runners/registration-token | jq .token --raw-output)
    ./config.sh remove --token "${REG_TOKEN}"
}

trap cleanup SIGINT SIGTERM

./run.sh & wait $!
