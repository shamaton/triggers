#!/usr/bin/env bash

set -euo pipefail

: "${SUBMODULE_PATH:?SUBMODULE_PATH is required}"
: "${SUBMODULE_BRANCH:?SUBMODULE_BRANCH is required}"
: "${POST_FILE:?POST_FILE is required}"
: "${COMMIT_MESSAGE:?COMMIT_MESSAGE is required}"
: "${RECOVERY_PREFIX:?RECOVERY_PREFIX is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"
: "${GITHUB_RUN_ATTEMPT:?GITHUB_RUN_ATTEMPT is required}"

git -C "$SUBMODULE_PATH" add -- "$POST_FILE"
if git -C "$SUBMODULE_PATH" diff --cached --quiet; then
  echo "No publication state changes to persist."
  echo "persisted=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

git -C "$SUBMODULE_PATH" commit -m "$COMMIT_MESSAGE"

for attempt in 1 2 3; do
  if git -C "$SUBMODULE_PATH" push origin "HEAD:$SUBMODULE_BRANCH"; then
    echo "persisted=true" >> "$GITHUB_OUTPUT"
    exit 0
  fi
  echo "Publication result push attempt ${attempt} failed. Refreshing the target branch."
  if ! git -C "$SUBMODULE_PATH" fetch origin "$SUBMODULE_BRANCH"; then
    continue
  fi
  if ! git -C "$SUBMODULE_PATH" rebase "origin/$SUBMODULE_BRANCH"; then
    git -C "$SUBMODULE_PATH" rebase --abort || true
    break
  fi
done

recovery_branch="automation/${RECOVERY_PREFIX}-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
for attempt in 1 2 3; do
  if git -C "$SUBMODULE_PATH" push origin "HEAD:refs/heads/$recovery_branch"; then
    echo "persisted=false" >> "$GITHUB_OUTPUT"
    echo "recovery_branch=$recovery_branch" >> "$GITHUB_OUTPUT"
    echo "Publication result was preserved on $recovery_branch."
    exit 1
  fi
  echo "Recovery branch push attempt ${attempt} failed."
done

echo "persisted=false" >> "$GITHUB_OUTPUT"
echo "Publication result could not be pushed. The remote in_flight state remains blocked; verify Threads and resolve it manually."
exit 1
