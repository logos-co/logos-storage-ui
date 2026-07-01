#!/usr/bin/env bash
#
# Local preview of the storage-ui doc-test reports.
#
# The storage-ui doc-tests are internal (not published), so this only runs a spec
# and produces its standalone report — there is no docs site to serve.
#
#   ./docs/preview.sh --doctest-migration  # run the config-migration doc-test
#
set -euo pipefail
cd "$(dirname "$0")/.."

case "${1:-}" in
  --doctest-migration) SPEC=storage-ui-migration.test.yaml ;;
  *)
    echo "Usage: $0 --doctest-migration" >&2
    exit 2
    ;;
esac

OUTPUT_DIR="./doctests/preview-outputs"
REPORT_CACHE="${REPORT_CACHE:-$OUTPUT_DIR/report.html}"
COMMIT="$(git rev-parse HEAD)"

if [ -z "$(git branch -r --contains "$COMMIT" 2>/dev/null)" ]; then
  echo "ERROR: HEAD ($COMMIT) is not pushed to any remote branch." >&2
  echo "  Push your branch first (any branch, not just master), then re-run." >&2
  exit 1
fi

if [ -e "$OUTPUT_DIR" ]; then chmod -R u+w "$OUTPUT_DIR" 2>/dev/null || true; fi
rm -rf "$OUTPUT_DIR" && mkdir -p "$OUTPUT_DIR"

echo "==> Running $SPEC, keeping artefacts in $OUTPUT_DIR…"
nix run github:logos-co/logos-doctest -- run \
  "doctests/$SPEC" \
  --verbose --continue-on-fail --output-dir "$OUTPUT_DIR" \
  --release-for "logos-storage-ui=${COMMIT}" \
  --report "$REPORT_CACHE"

echo "==> Report:           $REPORT_CACHE"
echo "==> Logs & artefacts: $OUTPUT_DIR"
