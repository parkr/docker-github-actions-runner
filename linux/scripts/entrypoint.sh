#!/bin/bash

set -o nounset

# [VERIFY]

if [[ -v REPO ]] && [[ -v ORG ]]; then
    echo "REPO and ORG are mutually exclusive, only set the one you need"
    exit 1
fi
if ! [[ -v REPO ]] && ! [[ -v ORG ]]; then
    echo "Either REPO or ORG have to be set"
    exit 1
fi
if ! [[ -v TOKEN ]]; then
    echo "The TOKEN variable cannot be empty"
fi

# [SETUP]

# start docker
echo "Starting docker..."
sudo service docker start > /dev/null
sleep 5
if [[ "$(service docker status)" == *"Docker is running"* ]]; then
    echo "Done!"
else
    echo "Docker didn't start, status is:"
    echo $(service docker status)
fi

# [START]

echo "Registering runner..."

cd /home/runner/actions-runner

if [[ -v REPO ]]; then
    REQ_TOKEN_URL=https://api.github.com/repos/${REPO}/actions/runners/registration-token
    CONFIG_URL=https://github.com/${REPO}
else
    REQ_TOKEN_URL=https://api.github.com/orgs/${ORG}/actions/runners/registration-token
    CONFIG_URL=https://github.com/${ORG}
fi

TOKEN_RESP_CODE=$(curl -X POST -w "%{http_code}" -o token_resp.txt -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github+json" "${REQ_TOKEN_URL}")

if [[ $(echo ${TOKEN_RESP_CODE} | cut -b 1) != 2 ]]; then
    echo "token acquisition failed with code ${TOKEN_RESP_CODE}:"
    cat token_resp.txt
    exit 1
fi

REG_TOKEN=$(cat token_resp.txt | jq .token --raw-output)
rm token_resp.txt

echo "Registering runner..."

./config.sh \
    --url "${CONFIG_URL}" \
    --token "${REG_TOKEN}" \
    --name "${RUNNER_NAME:-"runner-ubuntu"}-${HOSTNAME}" \
    --unattended \
    --labels "${EXTRA_LABELS:-}"

cleanup() {
    echo "Removing runner..."
    # token is only valid for 1h, so it needs to be re-queried
    # https://github.com/actions/runner/discussions/1799#discussioncomment-2747605
    REG_TOKEN=$(curl --fail-with-body -X POST -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github+json" "$REQ_TOKEN_URL" | jq .token --raw-output)
    ./config.sh remove --token "${REG_TOKEN}"
}

trap cleanup SIGINT SIGTERM

./run.sh --disableupdate & wait $!
