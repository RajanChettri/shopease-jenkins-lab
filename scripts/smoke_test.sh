#!/usr/bin/env bash
set -euo pipefail

NAME="$1"          # for example: shopease-staging

echo "Waiting for ${NAME} to become healthy..."
STATUS="starting"
for i in $(seq 1 20); do
  STATUS=$(docker inspect --format '{{.State.Health.Status}}' "${NAME}")
  echo "  attempt ${i}: ${STATUS}"
  if [ "${STATUS}" = "healthy" ]; then break; fi
  sleep 3
done

if [ "${STATUS}" != "healthy" ]; then
  echo "NOT healthy. Last logs:"
  docker logs --tail 30 "${NAME}"
  exit 1
fi

curl --fail --silent "http://${NAME}:5000/health"; echo
curl --fail --silent "http://${NAME}:5000/price/laptop"; echo
echo "Smoke test passed for ${NAME}"
