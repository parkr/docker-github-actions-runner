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

RUNNER_NAME=$RUNNER_NAME
REPO=$REPO
ACCESS_TOKEN=$TOKEN

USER=$(echo $REPO | cut -d '/' -f 1)
USER_TYPE=$(curl -X GET -H "Accept: application/vnd.github+json" https://api.github.com/users/${USER} | jq .type --raw-output)

if [[ $USER_TYPE == "User" ]]; then
    echo "Repository is owned by an user"
    REG_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${REPO}/actions/runners/registration-token | jq .token --raw-output)
else
    echo "Repository is owned by an organization"
    REG_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/orgs/${USER}/actions/runners/registration-token | jq .token --raw-output)
fi

echo "Registering runner..."
cd /home/runner/actions-runner
./config.sh \
    --url https://github.com/${REPO} \
    --token ${REG_TOKEN} \
    --name ${RUNNER_NAME} \
    --unattended \
    --labels "${EXTRA_LABELS:-}"

cleanup() {
    echo "Removing runner..."
    # token is only valid for 1h, so it needs to be re-queried
    # https://github.com/actions/runner/discussions/1799#discussioncomment-2747605
    if [[ $USER_TYPE == "User" ]]; then
        echo "Repository is owned by an user"
        REG_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${REPO}/actions/runners/registration-token | jq .token --raw-output)
    else
        echo "Repository is owned by an organization"
        REG_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/orgs/${USER}/actions/runners/registration-token | jq .token --raw-output)
    fi
    ./config.sh remove --token "${REG_TOKEN}"
}

trap cleanup SIGINT SIGTERM

./run.sh & wait $!
