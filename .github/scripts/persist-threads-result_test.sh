#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_bin="$test_root/bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${FAKE_GIT_MODE:-}" == "add-failure" && "$*" == *" add -- "* ]]; then
  exit 1
fi
case "$*" in
  *" diff --cached --quiet"*) exit 1 ;;
  *" push origin "*) exit 1 ;;
  *" fetch origin "*) exit 1 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$fake_bin/git"

run_failure_case() {
  local mode="$1"
  local case_root="$test_root/$mode"
  local submodule="$case_root/th"
  local output_file="$case_root/github-output"
  local runner_temp="$case_root/runner-temp"
  mkdir -p "$submodule/posts" "$runner_temp"
  : > "$output_file"
  printf '%s\n' '{"root":{"publication":{"status":"unknown"}}}' > "$submodule/posts/001.json"

  if PATH="$fake_bin:$PATH" \
    FAKE_GIT_MODE="$mode" \
    SUBMODULE_PATH="$submodule" \
    SUBMODULE_BRANCH="main" \
    POST_FILE="posts/001.json" \
    COMMIT_MESSAGE="test: persist result" \
    RECOVERY_PREFIX="test-result" \
    GITHUB_OUTPUT="$output_file" \
    GITHUB_RUN_ID="123" \
    GITHUB_RUN_ATTEMPT="1" \
    bash "$script_dir/persist-threads-result.sh"; then
    echo "$mode unexpectedly succeeded"
    exit 1
  fi

  if grep -q '^artifact_' "$output_file"; then
    echo "$mode unexpectedly emitted artifact outputs"
    exit 1
  fi
  if [[ -n "$(find "$runner_temp" -mindepth 1 -print -quit)" ]]; then
    echo "$mode unexpectedly copied internal data"
    exit 1
  fi
}

run_failure_case add-failure
run_failure_case push-failure

echo "persist-threads-result fail-closed tests passed"
