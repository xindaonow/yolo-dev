#!/usr/bin/env bash
# Build the yolo-dev image from .devcontainer/Dockerfile.
# Other projects reference it via "image": "yolo-dev:latest" in their devcontainer.json.

set -euo pipefail

cd "$(dirname "$0")"

IMAGE="${IMAGE:-yolo-dev:latest}"
PLATFORM="${PLATFORM:-}"   # e.g. PLATFORM=linux/amd64 to force x86 on Apple Silicon

ARGS=(build -t "$IMAGE")
[[ -n "$PLATFORM" ]] && ARGS+=(--platform "$PLATFORM")

# --latest: force-refresh Claude/Codex to the newest published versions by
# busting just the npm layer cache (apt/node/bun/uv stay cached).
if [[ "${1:-}" == "--latest" ]]; then
  ARGS+=(--build-arg "CLI_REBUILD=$(date +%s)")
  echo "==> --latest: forcing fresh Claude/Codex install"
fi

ARGS+=(.devcontainer)

echo "==> docker ${ARGS[*]}"
docker "${ARGS[@]}"

echo ""
echo "==> Built $IMAGE"
docker images "$IMAGE"
echo ""
echo "==> Use it in a new project: cp templates/devcontainer.json <project>/.devcontainer/"
