#!/bin/sh
# Mobile Blueprint installer.
#
# Installs a spec-driven AI coding workflow into an existing mobile app.
# Requires only sh, plus tar and curl when fetching a remote bundle.
# Deliberately not Node-dependent: most Flutter, iOS, and Android projects
# have no Node toolchain and should not need one to get a workflow.
#
#   curl -fsSL https://mobile-blueprint.dev/install.sh | sh
#   ./install.sh --stack flutter --adapter claude
#   ./install.sh --from ./mobile --dry-run
#
set -eu

VERSION="0.1.0"
BASE_URL="${BLUEPRINT_BASE_URL:-https://mobile-blueprint.dev/releases}"

STACK=""
ADAPTERS=""
SOURCE=""
TARGET="$PWD"
DRY_RUN=0
FORCE=0
ASSUME_YES=0
TMPDIR_CREATED=""

# ----------------------------------------------------------------- output ----

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_BOLD=$(printf '\033[1m'); C_DIM=$(printf '\033[2m')
  C_RED=$(printf '\033[31m'); C_GREEN=$(printf '\033[32m')
  C_YELLOW=$(printf '\033[33m'); C_OFF=$(printf '\033[0m')
else
  C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_OFF=''
fi

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_OFF" "$*" >&2; }
die()  { printf '%serror%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }
ok()   { printf '%s+%s %s\n' "$C_GREEN" "$C_OFF" "$*"; }

cleanup() {
  [ -n "$TMPDIR_CREATED" ] && rm -rf "$TMPDIR_CREATED"
  return 0
}
trap cleanup EXIT INT TERM

usage() {
  cat <<'USAGE'
Mobile Blueprint installer

USAGE
  install.sh [options]

OPTIONS
  --stack <name>      flutter | ios | android | react-native
                      Detected from project files when omitted.
  --adapter <list>    Comma separated: claude, codex, copilot, opencode.
                      Detected from existing files, else prompted.
  --from <dir>        Install from a local bundle instead of downloading.
  --target <dir>      Project to install into. Defaults to the current dir.
  --dry-run           Print the plan and change nothing.
  --force             Overwrite existing Blueprint files without asking.
  --yes               Accept detected values without prompting.
  --version           Print the installer version.
  --help              Print this help.

EXAMPLES
  curl -fsSL https://mobile-blueprint.dev/install.sh | sh
  ./install.sh --stack flutter --adapter claude,codex
  ./install.sh --from ./mobile --dry-run
USAGE
}

# ------------------------------------------------------------------- args ----

while [ $# -gt 0 ]; do
  case "$1" in
    --stack)     STACK="${2:-}"; shift 2 ;;
    --stack=*)   STACK="${1#*=}"; shift ;;
    --adapter)   ADAPTERS="${2:-}"; shift 2 ;;
    --adapter=*) ADAPTERS="${1#*=}"; shift ;;
    --from)      SOURCE="${2:-}"; shift 2 ;;
    --from=*)    SOURCE="${1#*=}"; shift ;;
    --target)    TARGET="${2:-}"; shift 2 ;;
    --target=*)  TARGET="${1#*=}"; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --force)     FORCE=1; shift ;;
    --yes|-y)    ASSUME_YES=1; shift ;;
    --version)   say "$VERSION"; exit 0 ;;
    --help|-h)   usage; exit 0 ;;
    *)           die "unknown option: $1 (try --help)" ;;
  esac
done

[ -d "$TARGET" ] || die "target directory does not exist: $TARGET"
TARGET=$(cd "$TARGET" && pwd)

# --------------------------------------------------------------- detection ---

# A glob that matches nothing is passed through literally, and that literal
# never exists on disk. Testing the first argument is therefore the portable way
# to ask whether a pattern matched. `ls pattern1 pattern2` cannot be used: it
# exits non-zero when any one pattern misses, even if another matched.
glob_matches() {
  [ -e "$1" ]
}

# Flutter and React Native projects contain ios/ and android/ subdirectories,
# so they must be matched before the native stacks or every cross-platform
# project would be misread as native Android.
detect_stack() {
  if [ -f "$TARGET/pubspec.yaml" ] && grep -q '^ *flutter *:' "$TARGET/pubspec.yaml" 2>/dev/null; then
    echo flutter; return
  fi
  if [ -f "$TARGET/package.json" ] &&
     grep -Eq '"(react-native|expo)"' "$TARGET/package.json" 2>/dev/null; then
    echo react-native; return
  fi
  if glob_matches "$TARGET"/*.xcodeproj || glob_matches "$TARGET"/*.xcworkspace ||
     [ -f "$TARGET/Package.swift" ]; then
    echo ios; return
  fi
  if [ -f "$TARGET/settings.gradle" ] || [ -f "$TARGET/settings.gradle.kts" ] ||
     [ -f "$TARGET/build.gradle" ] || [ -f "$TARGET/build.gradle.kts" ]; then
    echo android; return
  fi
  echo ""
}

describe_stack() {
  case "$1" in
    flutter)      echo "Flutter (pubspec.yaml)" ;;
    react-native) echo "React Native or Expo (package.json)" ;;
    ios)          echo "native iOS (Xcode project or Package.swift)" ;;
    android)      echo "native Android (Gradle)" ;;
    *)            echo "$1" ;;
  esac
}

valid_stack() {
  case "$1" in
    flutter|ios|android|react-native) return 0 ;;
    *) return 1 ;;
  esac
}

detect_adapters() {
  found=""
  [ -d "$TARGET/.claude" ] && found="claude"
  if [ -d "$TARGET/.agents" ]; then
    [ -n "$found" ] && found="$found,codex" || found="codex"
  fi
  echo "$found"
}

valid_adapter() {
  case "$1" in
    claude|codex|copilot|opencode) return 0 ;;
    *) return 1 ;;
  esac
}

# Prompts read from /dev/tty so they still work under `curl | sh`, where
# stdin is the script itself rather than the terminal.
ask() {
  prompt="$1"; default="$2"; reply=""
  if [ "$ASSUME_YES" -eq 1 ] || [ ! -r /dev/tty ]; then
    echo "$default"; return
  fi
  printf '%s [%s]: ' "$prompt" "$default" > /dev/tty
  read -r reply < /dev/tty || reply=""
  [ -z "$reply" ] && reply="$default"
  echo "$reply"
}

# ---------------------------------------------------------------- preflight --

say ""
say "${C_BOLD}Mobile Blueprint${C_OFF} ${C_DIM}v$VERSION${C_OFF}"
say ""

if [ ! -d "$TARGET/.git" ] && ! (cd "$TARGET" && git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
  warn "$TARGET is not a Git repository."
  warn "The workflow relies on branches and commits. Run 'git init' first."
  [ "$ASSUME_YES" -eq 1 ] || {
    answer=$(ask "Continue anyway? (y/N)" "N")
    case "$answer" in y|Y|yes|Yes) ;; *) die "stopped. Initialize Git, then rerun." ;; esac
  }
fi

if [ -z "$STACK" ]; then
  STACK=$(detect_stack)
  if [ -n "$STACK" ]; then
    ok "Detected stack: $(describe_stack "$STACK")"
  else
    warn "Could not detect a mobile stack in $TARGET"
    STACK=$(ask "Stack (flutter/ios/android/react-native)" "flutter")
  fi
else
  info "Stack: $(describe_stack "$STACK") (specified)"
fi

valid_stack "$STACK" || die "unsupported stack: $STACK (expected flutter, ios, android, or react-native)"

if [ -z "$ADAPTERS" ]; then
  ADAPTERS=$(detect_adapters)
  if [ -n "$ADAPTERS" ]; then
    ok "Detected AI tools: $ADAPTERS"
  else
    ADAPTERS=$(ask "AI tool adapters (claude,codex,copilot,opencode)" "claude")
  fi
else
  info "Adapters: $ADAPTERS (specified)"
fi

# Validate every requested adapter before touching the filesystem.
OLD_IFS="$IFS"; IFS=','
for a in $ADAPTERS; do
  valid_adapter "$a" || { IFS="$OLD_IFS"; die "unknown adapter: $a"; }
done
IFS="$OLD_IFS"

# ------------------------------------------------------------------ source ---

resolve_source() {
  if [ -n "$SOURCE" ]; then
    [ -d "$SOURCE" ] || die "--from directory not found: $SOURCE"
    SOURCE=$(cd "$SOURCE" && pwd)
    return
  fi

  # Running from a checkout: the packs sit next to this script.
  script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || echo "")
  if [ -n "$script_dir" ] && [ -d "$script_dir/stacks" ]; then
    SOURCE="$script_dir"
    return
  fi

  # Piped from curl: download the released bundle.
  command -v curl >/dev/null 2>&1 || die "curl is required to download the bundle"
  command -v tar  >/dev/null 2>&1 || die "tar is required to unpack the bundle"

  TMPDIR_CREATED=$(mktemp -d 2>/dev/null || mktemp -d -t blueprint)
  url="$BASE_URL/mobile-blueprint-$VERSION.tar.gz"
  info "Downloading $url"
  curl -fsSL "$url" -o "$TMPDIR_CREATED/bundle.tar.gz" ||
    die "download failed. Check the URL or use --from with a local checkout."
  tar -xzf "$TMPDIR_CREATED/bundle.tar.gz" -C "$TMPDIR_CREATED" ||
    die "could not unpack the bundle"
  SOURCE="$TMPDIR_CREATED/mobile"
  [ -d "$SOURCE/stacks" ] || die "unexpected bundle layout under $SOURCE"
}

resolve_source
PACK="$SOURCE/stacks/$STACK"
[ -d "$PACK" ] || die "no stack pack for '$STACK' at $PACK"

# ------------------------------------------------------------------- plan ----

say ""
say "${C_BOLD}Plan${C_OFF}"
info "project   $TARGET"
info "stack     $STACK"
info "adapters  $ADAPTERS"
info "source    $SOURCE"
say ""

# Files the install writes, so conflicts can be reported before any change.
planned_paths() {
  echo "AGENTS.md"
  echo "blueprint/"
  OLD_IFS="$IFS"; IFS=','
  for a in $ADAPTERS; do
    case "$a" in
      claude)            echo "CLAUDE.md"; echo ".claude/skills/" ;;
      codex|copilot)     echo ".agents/skills/" ;;
      opencode)          echo ".agents/skills/" ;;
    esac
  done
  IFS="$OLD_IFS"
}

CONFLICTS=""
for p in $(planned_paths | sort -u); do
  if [ -e "$TARGET/$p" ]; then
    CONFLICTS="$CONFLICTS $p"
  fi
done

if [ -n "$CONFLICTS" ] && [ "$FORCE" -eq 0 ]; then
  warn "These paths already exist and would be overwritten:"
  for c in $CONFLICTS; do info "$c"; done
  if [ "$DRY_RUN" -eq 0 ]; then
    answer=$(ask "Overwrite? (y/N)" "N")
    case "$answer" in y|Y|yes|Yes) ;; *) die "stopped. Nothing was changed." ;; esac
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  say "${C_BOLD}Would write${C_OFF}"
  for p in $(planned_paths | sort -u); do info "$p"; done
  say ""
  say "${C_DIM}Dry run: nothing was changed.${C_OFF}"
  exit 0
fi

# ---------------------------------------------------------------- install ----

# The neutral workflow base lives in one of two places. A released bundle ships
# a self-contained `base/`. A source checkout has no such copy, so the base is
# the repository root one level up, and the checkout stays the single source of
# truth instead of carrying a duplicate that would drift.
resolve_base() {
  if [ -d "$SOURCE/base" ]; then
    BASE="$SOURCE/base"
    BASE_LAYOUT="bundle"
    return
  fi

  repo_root=$(cd "$SOURCE/.." 2>/dev/null && pwd || echo "")
  if [ -n "$repo_root" ] && [ -f "$repo_root/AGENTS.md" ] && [ -d "$repo_root/blueprint" ]; then
    BASE="$repo_root"
    BASE_LAYOUT="checkout"
    return
  fi

  die "missing workflow base. Expected $SOURCE/base, or a checkout with AGENTS.md one level up."
}

resolve_base

# Skill trees live at a different path in each layout.
if [ "$BASE_LAYOUT" = "checkout" ]; then
  BASE_SKILLS="$BASE/.claude/skills"
  [ -d "$BASE_SKILLS" ] || BASE_SKILLS="$BASE/.agents/skills"
else
  BASE_SKILLS="$BASE/skills"
fi
[ -d "$BASE_SKILLS" ] || die "missing skills tree at $BASE_SKILLS"

copy_tree() { # src dst
  mkdir -p "$2"
  (cd "$1" && tar cf - .) | (cd "$2" && tar xf -)
}

say "${C_BOLD}Installing${C_OFF}"

# 1. Neutral workflow base.
copy_tree "$BASE/blueprint" "$TARGET/blueprint"
cp "$BASE/AGENTS.md" "$TARGET/AGENTS.md"
info "blueprint/ and AGENTS.md"

# 2. Adapter skill trees.
WROTE_AGENTS=0
OLD_IFS="$IFS"; IFS=','
for a in $ADAPTERS; do
  case "$a" in
    claude)
      copy_tree "$BASE_SKILLS" "$TARGET/.claude/skills"
      cp "$BASE/CLAUDE.md" "$TARGET/CLAUDE.md"
      info ".claude/skills/ and CLAUDE.md"
      ;;
    codex|copilot|opencode)
      if [ "$WROTE_AGENTS" -eq 0 ]; then
        copy_tree "$BASE_SKILLS" "$TARGET/.agents/skills"
        info ".agents/skills/"
        WROTE_AGENTS=1
      fi
      ;;
  esac
done
IFS="$OLD_IFS"

# 3. Stack pack overlay. These files replace their neutral counterparts, which
#    is why the pack is applied after the base rather than merged into it.
cp "$PACK/coding-standards.md" "$TARGET/blueprint/context/coding-standards.md"
cp "$PACK/platform.md"         "$TARGET/blueprint/context/platform.md"
info "blueprint/context/ stack pack ($STACK)"

# The Commands block is the one place AGENTS.md names real tooling, so the
# pack substitutes it rather than leaving a Next.js example behind.
if [ -f "$PACK/commands.md" ]; then
  awk -v cmdfile="$PACK/commands.md" '
    /^## Commands$/ { print; print ""; while ((getline line < cmdfile) > 0) print line; skip=1; next }
    skip && /^## / { skip=0 }
    !skip { print }
  ' "$TARGET/AGENTS.md" > "$TARGET/AGENTS.md.tmp" && mv "$TARGET/AGENTS.md.tmp" "$TARGET/AGENTS.md"
  info "AGENTS.md Commands block"
fi

# Mobile skill overrides. Each directory is replaced wholesale rather than
# merged: the web skills ship reference files (browser test setup, dev-server
# verification, CSS theme variables) that are actively wrong for a mobile
# project, and a merge would leave them in place for an agent to read.
OVERRIDDEN=""
for skill in "$SOURCE"/skills/*/; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  for root in "$TARGET/.claude/skills" "$TARGET/.agents/skills"; do
    [ -d "$root" ] || continue
    rm -rf "$root/$name"
    copy_tree "$skill" "$root/$name"
  done
  OVERRIDDEN="$OVERRIDDEN $name"
done
info "mobile skill overrides:$OVERRIDDEN"

# 4. Retarget the handful of one-line web references left in otherwise neutral
#    base files. These are prose mentions, not logic, but leaving them costs
#    real accuracy: an autopilot run told to "prefer Playwright" will go looking
#    for a browser in a Flutter project.
#
#    Prose patches drift when upstream rewords a line, so this step verifies
#    itself afterward and warns rather than failing silently.
retarget_file() { # file, then pairs of pattern/replacement
  f="$1"; shift
  [ -f "$f" ] || return 0
  while [ $# -ge 2 ]; do
    sed "s|$1|$2|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    shift 2
  done
}

retarget_file "$TARGET/AGENTS.md" \
  'optional Render or Vercel deployment readiness, local config, env review, and smoke-test planning' \
  'optional App Store, Google Play, and internal distribution readiness, signing and versioning review, and store requirement checks' \
  'prepare local Render or Vercel config' \
  'prepare local store and signing config' \
  'optional, pre-build static mockups to lock the look' \
  'optional, pre-build throwaway native screens to lock the look'

retarget_file "$TARGET/blueprint/context/ai-interaction.md" \
  '`/release render` or `/release vercel`' \
  '`/release ios` or `/release android`'

retarget_file "$TARGET/blueprint/project-plan.md" \
  'Target host if known, such as Render or Vercel.' \
  'Target distribution if known, such as the App Store, Google Play, or an internal track.'

retarget_file "$TARGET/blueprint/context/coding-standards.md" \
  'Browser Verification' 'Device Verification'

for root in "$TARGET/.claude/skills" "$TARGET/.agents/skills"; do
  [ -d "$root" ] || continue
  retarget_file "$root/overview/SKILL.md" \
    'If the plan names Render, Vercel,' \
    'If the plan names the App Store, Google Play,'
  retarget_file "$root/autopilot/SKILL.md" \
    '   - browser, CLI, API, or app-level evidence for behavioral done-whens' \
    '   - device evidence for behavioral done-whens, at the tier the claim needs'

  if [ -f "$root/autopilot/SKILL.md" ]; then
    awk '
      /^3\. If UI is involved, inspect the running app when possible\./ {
        print "3. If UI is involved, run it on a real target with `/device`. Pick the"
        print "   cheapest tier in `blueprint/context/platform.md` that proves the claim,"
        print "   and name that tier. Capture a screenshot per platform the project ships,"
        print "   and read the device log: an exception, overflow, skipped frames, or a"
        print "   red box means not a pass even when the screen looks right."
        print "   With `verification.uiEvidence: \"required\"`, direct device evidence is"
        print "   mandatory and unavailable evidence is a hard stop."
        skip = 1
        next
      }
      skip && /^4\. / { skip = 0 }
      !skip { print }
    ' "$root/autopilot/SKILL.md" > "$root/autopilot/SKILL.md.tmp" &&
      mv "$root/autopilot/SKILL.md.tmp" "$root/autopilot/SKILL.md"
  fi
done

# Verify the retarget actually landed. A miss means upstream reworded a line,
# which is worth saying out loud rather than shipping a mobile install that
# still points at a browser.
LEFTOVER=$(grep -rl -iE 'playwright|vercel|render\.com|localhost:3000|globals\.css' \
  "$TARGET/AGENTS.md" "$TARGET/blueprint" \
  "$TARGET/.claude/skills" "$TARGET/.agents/skills" 2>/dev/null || true)
if [ -n "$LEFTOVER" ]; then
  warn "Some web-specific references could not be retargeted:"
  for f in $LEFTOVER; do info "${f#$TARGET/}"; done
  warn "The base workflow may have been reworded upstream. Review these by hand."
else
  info "retargeted web references to mobile"
fi

# 5. Generated state is local only and must never enter a feature commit.
mkdir -p "$TARGET/blueprint/.state"
if [ -f "$TARGET/.gitignore" ]; then
  grep -q '^blueprint/\.state/' "$TARGET/.gitignore" 2>/dev/null ||
    printf '\n# Blueprint generated state\nblueprint/.state/\n' >> "$TARGET/.gitignore"
else
  printf '# Blueprint generated state\nblueprint/.state/\n' > "$TARGET/.gitignore"
fi

cat > "$TARGET/blueprint/.state/manifest.json" <<MANIFEST
{
  "schemaVersion": 1,
  "version": "$VERSION",
  "stack": "$STACK",
  "adapters": [$(echo "$ADAPTERS" | sed 's/[^,]*/"&"/g')],
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
MANIFEST

say ""
ok "Installed Mobile Blueprint for $(describe_stack "$STACK")"
say ""
say "${C_BOLD}Next${C_OFF}"
info "1. Run /onboard in your AI tool so it learns your real commands and devices."
info "2. Write blueprint/project-plan.md and blueprint/build-plan.md."
info "3. Run /overview, then /feature for the first item."
say ""
say "${C_DIM}Stack pack: blueprint/context/platform.md defines what counts as proof.${C_OFF}"
say ""
