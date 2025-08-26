# docker github actions runner

## Overview

This repository contains docker images for self-hosting a github actions runner as a docker container.

## Installation

```bash
$ git clone <this repo>
$ cd docker-github-actions-runner
$ cp env.example .env
$ vim .env # set these variables
```

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
