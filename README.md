# docker github actions runner

## Overview

This repository contains docker images for self-hosting a github actions runner as a docker container.

## Installation

```bash
$ git clone <this repo>
$ cd docker-github-actions-runner
$ cp env.example .env
$ chmod 600 .env
$ touch tunnel.env
```

## Configuration

```
$ vim tunnel.env # set these too
$ vim .env # set these variables
```

The `.env` variables are:

1. `REPO` - this is `username/your-repo-name`
2. `TOKEN` - this is a github access token with enough permissions to
   register new runners
3. `EXTRA_LABELS` - optional, but it's useful to add extra labels.

The token I have used successfully was setup this way:

1. https://github.com/settings/personal-access-tokens/new
2. Fill out a descriptive `Token name` and add a description.
3. Set `Expiration` to your desired expiration. I used 90 days.
4. Since user runners are specific to a single repository, I chose `Only
   select repositories` and selected the repository I wanted the runners to
   bind to.
5. For `Permissions`, you need `Administration` for `Repositories` which
   allows for runner registration. Set to `Read and write`.
6. Click `Generate token` and guard this token dearly.

The `tunnel.env` variables are defined by the `gluetun` docker image.

If you'd like to remove the VPN tunnel, you certainly can. I wanted to
isolate the runners from my local network at home, so I used a VPN to do
so. To remove the tunnel:

1. Remove the `tunnel:` configuration entirely from `docker-compose.yaml`
2. Remove the `depends_on:` configuration from `runner:`
3. Remove the `network_mode:` configuration from `runner:` and replace it
   with `networks: [runner_net]`.

## Usage

```bash
$ podman compose up -d
```

To debug:

```bash
$ podman compose logs -f
```

Logs should show why something is broken.

To confirm it's working, go to
`github.com/<owner>/<repo>/settings/actions/runners` and you should see
your 2 new runners. If you need more runners, modify the
docker-compose.yaml file.

To turn down, podman likes it when you remove containers:

```bash
$ podman compose down -v
```
