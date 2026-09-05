#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  GITHUB_TOKEN=... ./scripts/upload-release-assets.sh --tag v1.0.0 [options] [files...]

Options:
  --tag TAG       GitHub Release tag to upload to (required)
  --repo OWNER/REPO
                  Override the repository detected from git remote
  --create        Create the Release when it does not exist
  -h, --help      Show this help

Examples:
  GITHUB_TOKEN=ghp_... ./scripts/upload-release-assets.sh --tag v1.0.0 --create
  GITHUB_TOKEN=ghp_... ./scripts/upload-release-assets.sh --tag v1.0.0 dist/*.dmg dist/*.exe
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Error: required command not found: %s\n' "$1" >&2
        exit 1
    }
}

TAG=''
REPO=''
CREATE_RELEASE=false
ASSETS=()

while (($# > 0)); do
    case "$1" in
        --tag)
            (($# >= 2)) || { printf 'Error: --tag requires a value\n' >&2; exit 1; }
            TAG="$2"
            shift 2
            ;;
        --repo)
            (($# >= 2)) || { printf 'Error: --repo requires a value\n' >&2; exit 1; }
            REPO="$2"
            shift 2
            ;;
        --create)
            CREATE_RELEASE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            ASSETS+=("$@")
            break
            ;;
        -* )
            printf 'Error: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
        *)
            ASSETS+=("$1")
            shift
            ;;
    esac
done

[[ -n "$TAG" ]] || { printf 'Error: --tag is required\n' >&2; usage >&2; exit 1; }
[[ -n "${GITHUB_TOKEN:-}" ]] || {
    printf 'Error: set GITHUB_TOKEN to a GitHub token with repository contents write access\n' >&2
    exit 1
}

require_command curl
require_command git
require_command python3

if [[ -z "$REPO" ]]; then
    remote_url="$(git config --get remote.origin.url || true)"
    REPO="$(python3 - "$remote_url" <<'PY'
import re
import sys

remote = sys.argv[1]
match = re.search(r'github\.com[:/]([^/]+/[^/]+?)(?:\.git)?$', remote)
if not match:
    raise SystemExit('Error: unable to detect OWNER/REPO from origin; use --repo')
print(match.group(1))
PY
)"
fi

if ((${#ASSETS[@]} == 0)); then
    shopt -s nullglob
    ASSETS=(dist/*)
    shopt -u nullglob
fi

if ((${#ASSETS[@]} == 0)); then
    printf 'Error: no assets found\n' >&2
    exit 1
fi

for asset in "${ASSETS[@]}"; do
    [[ -f "$asset" ]] || { printf 'Error: asset does not exist: %s\n' "$asset" >&2; exit 1; }
done

API="https://api.github.com/repos/${REPO}"
AUTH_HEADER="Authorization: Bearer ${GITHUB_TOKEN}"
ACCEPT_HEADER='Accept: application/vnd.github+json'

response_dir="$(mktemp -d)"
release_json="$response_dir/release.json"
trap 'rm -rf "$response_dir"' EXIT

# Keep HTTP error bodies, including on older macOS curl versions that lack
# --fail-with-body. Transport failures must still stop the script.
request() {
    local output="$1" status curl_status=0
    shift
    status="$(curl -sS -o "$output" -w '%{http_code}' \
        -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "$@")" || curl_status=$?
    if ((curl_status != 0)) || [[ "$status" != 2?? ]]; then
        printf 'Error: request failed (HTTP %s, curl exit %s).\n' "$status" "$curl_status" >&2
        if [[ -s "$output" ]]; then
            cat "$output" >&2
            printf '\n' >&2
        fi
        if [[ "$status" == '403' ]]; then
            printf '%s\n' \
                'Check that GITHUB_TOKEN has access to this repository and Contents: Read and write permission.' \
                'Also check organization approval/SSO, rate limits, and any proxy rejection in the response above.' >&2
        fi
        return 1
    fi
}

release_status="$(curl -sS -o "$release_json" -w '%{http_code}' \
    -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" \
    "$API/releases/tags/$TAG")"

if [[ "$release_status" == '404' && "$CREATE_RELEASE" == true ]]; then
    printf 'Creating GitHub Release %s...\n' "$TAG"
    request "$release_json" \
        -H 'Content-Type: application/json' \
        -d "$(python3 - "$TAG" <<'PY'
import json
import sys
print(json.dumps({'tag_name': sys.argv[1], 'name': sys.argv[1]}))
PY
)" \
        "$API/releases"
elif [[ "$release_status" != '200' ]]; then
    printf 'Error: could not find Release %s in %s (HTTP %s).\n' "$TAG" "$REPO" "$release_status" >&2
    cat "$release_json" >&2
    printf '\n' >&2
    if [[ "$release_status" == '404' ]]; then
        printf 'Check repository/token access; use --create if the Release does not exist.\n' >&2
    fi
    exit 1
fi

upload_url="$(python3 - "$release_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding='utf-8') as release_file:
    release = json.load(release_file)
print(release['upload_url'].split('{', 1)[0])
PY
)"

for asset in "${ASSETS[@]}"; do
    asset_name="$(basename "$asset")"
    encoded_name="$(python3 - "$asset_name" <<'PY'
import sys
from urllib.parse import quote

print(quote(sys.argv[1], safe=''))
PY
)"
    content_type="application/octet-stream"
    case "$asset_name" in
        *.dmg) content_type='application/x-apple-diskimage' ;;
        *.exe) content_type='application/vnd.microsoft.portable-executable' ;;
        *.zip) content_type='application/zip' ;;
    esac

    printf 'Uploading %s...\n' "$asset_name"
    request "$response_dir/upload.json" \
        -H "Content-Type: $content_type" \
        --data-binary "@$asset" \
        "$upload_url?name=$encoded_name"
done

printf 'Uploaded %d asset(s) to https://github.com/%s/releases/tag/%s\n' "${#ASSETS[@]}" "$REPO" "$TAG"