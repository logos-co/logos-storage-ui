#!/usr/bin/env bash
# Preview one QML screen with the system Qt runtime, without the backend.
# Usage: ./preview.sh [--no-watch] [File.qml]
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

watch=true
if [ "${1:-}" = "--no-watch" ]; then
    watch=false
    shift
fi
file=${1:-StorageView.qml}

if [ ! -f "$root/src/qml/$file" ]; then
    echo "No such QML file: src/qml/$file" >&2
    exit 1
fi

# The system Qt is used on purpose: it renders through the host GL drivers,
# which the Nix-built Qt cannot reach from a container.
if ! qml_bin=$(command -v qml); then
    echo "qml not found in PATH (Fedora: sudo dnf install qt6-qtdeclarative)." >&2
    exit 1
fi

ds=$(nix eval --raw "$root#designSystemQml")
args=(-I "$ds" -I "$root/preview" "$root/src/qml/$file")

if [ "$watch" = true ]; then
    exec qmlpreview "$qml_bin" "${args[@]}"
fi
exec "$qml_bin" "${args[@]}"
