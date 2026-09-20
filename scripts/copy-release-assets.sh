#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${1:-$PROJECT_DIR/../share-anything/electron/dist}"
DEST_DIR="$PROJECT_DIR/dist"

if [[ "${1:-}" == '--help' || "${1:-}" == '-h' ]]; then
    printf 'Usage: %s [source-directory]\nCopies .dmg and .exe files to the project dist directory, removing -X.Y.Z from filenames.\n' "$0"
    exit 0
fi

[[ $# -le 1 ]] || { printf 'Error: expected at most one source directory\n' >&2; exit 1; }
[[ -d "$SOURCE_DIR" ]] || { printf 'Error: source directory does not exist: %s\n' "$SOURCE_DIR" >&2; exit 1; }

shopt -s nullglob
sources=()
names=()
for source in "$SOURCE_DIR"/*.dmg "$SOURCE_DIR"/*.exe; do
    [[ -f "$source" ]] || continue
    name="${source##*/}"
    name="$(printf '%s\n' "$name" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+([-\.])/\1/')"
    # Refuse ambiguous input when multiple versions map to the same name.
    for existing in "${names[@]:-}"; do
        [[ "$existing" != "$name" ]] || { printf 'Error: multiple source files map to %s\n' "$name" >&2; exit 1; }
    done
    sources+=("$source")
    names+=("$name")
done

[[ ${#sources[@]} -gt 0 ]] || { printf 'Error: no .dmg or .exe files found in %s\n' "$SOURCE_DIR" >&2; exit 1; }

mkdir -p "$DEST_DIR"
for index in "${!sources[@]}"; do
    cp "${sources[$index]}" "$DEST_DIR/${names[$index]}"
    printf 'Copied: %s -> %s\n' "${sources[$index]}" "$DEST_DIR/${names[$index]}"
done

printf 'Copied %d file(s).\n' "${#sources[@]}"
