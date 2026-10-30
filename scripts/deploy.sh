#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="$1"      # for example: staging
HOST_PORT="$2"     # for example: 8081
IMAGE="$3"         # for example: localhost:5001/shopease-api:1.0.7
NAME="shopease-${ENV_NAME}"

echo "Pulling ${IMAGE}"
docker pull "${IMAGE}"

if docker inspect "${NAME}" >/dev/null 2>&1; then
  echo "Removing old container ${NAME}"
  docker rm -f "${NAME}"
fi

echo "Starting ${NAME} on port ${HOST_PORT}"
docker run -d --name "${NAME}" --network cicd-net -p "${HOST_PORT}:5000" \
  --restart unless-stopped --label "shopease.env=${ENV_NAME}" \
  -e APP_ENV="${ENV_NAME}" "${IMAGE}"
