#!/bin/sh
# Assemble the release tarball that every front door installs.
#
# The bundle is the only artifact that matters. install.sh, a Homebrew formula,
# a pub package, and the npm wrapper all resolve to this same file, so there is
# one source of truth and one version number.
#
#   ./mobile/scripts/build-bundle.sh [output-dir]
#
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
MOBILE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$MOBILE_DIR/.." && pwd)
OUT_DIR="${1:-$REPO_ROOT/dist}"

VERSION=$(sed -n 's/^VERSION="\(.*\)"/\1/p' "$MOBILE_DIR/install.sh" | head -1)
[ -n "$VERSION" ] || { echo "could not read VERSION from install.sh" >&2; exit 1; }

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT INT TERM

BUNDLE="$STAGE/mobile"
mkdir -p "$BUNDLE/base"

# 1. The neutral workflow base, flattened so the installer needs no adapter
#    knowledge at unpack time.
cp "$REPO_ROOT/AGENTS.md" "$BUNDLE/base/AGENTS.md"
cp "$REPO_ROOT/CLAUDE.md" "$BUNDLE/base/CLAUDE.md"
cp -R "$REPO_ROOT/blueprint" "$BUNDLE/base/blueprint"

if [ -d "$REPO_ROOT/.claude/skills" ]; then
  cp -R "$REPO_ROOT/.claude/skills" "$BUNDLE/base/skills"
else
  cp -R "$REPO_ROOT/.agents/skills" "$BUNDLE/base/skills"
fi

# Generated local state never ships in a bundle.
rm -rf "$BUNDLE/base/blueprint/.state"

# 2. The mobile layer.
cp "$MOBILE_DIR/install.sh" "$BUNDLE/install.sh"
cp "$MOBILE_DIR/README.md"  "$BUNDLE/README.md"
cp "$MOBILE_DIR/DESIGN.md"  "$BUNDLE/DESIGN.md"
cp -R "$MOBILE_DIR/stacks"  "$BUNDLE/stacks"
cp -R "$MOBILE_DIR/skills"  "$BUNDLE/skills"
chmod +x "$BUNDLE/install.sh"

mkdir -p "$OUT_DIR"
TARBALL="$OUT_DIR/mobile-blueprint-$VERSION.tar.gz"
(cd "$STAGE" && tar -czf "$TARBALL" mobile)

# A checksum so the curl path can be verified by anyone who wants to.
if command -v shasum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && shasum -a 256 "mobile-blueprint-$VERSION.tar.gz" > "mobile-blueprint-$VERSION.tar.gz.sha256")
elif command -v sha256sum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && sha256sum "mobile-blueprint-$VERSION.tar.gz" > "mobile-blueprint-$VERSION.tar.gz.sha256")
fi

echo "built $TARBALL"
echo "size  $(du -h "$TARBALL" | cut -f1)"
