#!/usr/bin/env sh
# install.sh — install the /create-mvp Claude Code command (single command, with resume mode).
# POSIX sh. Works on Linux, macOS, WSL, and Git Bash (Windows).

set -eu

# Resolve script directory (portable)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

# Defaults
TARGET="user"
FORCE=0
DEST_OVERRIDE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Installs the /create-mvp Claude Code command. The command body is built by
concatenating partials in $SCRIPT_DIR/src/ in numeric order.

Options:
  --user          Install to \$HOME/.claude/commands/   (default)
  --project       Install to ./.claude/commands/ in the current directory
  --dest PATH     Install to a custom directory
  --force         Overwrite existing files without prompting; remove deprecated resume-mvp.md
  -h, --help      Show this help

Examples:
  sh install.sh
  sh install.sh --project
  sh install.sh --dest /opt/shared/.claude/commands --force

Plans + registry live under \${CREATE_MVP_HOME} if set, otherwise under
\${XDG_DATA_HOME:-\$HOME/.local/share}/create-mvp/ — regardless of where the
command file is installed. On macOS this resolves to \$HOME/.local/share/create-mvp/.
EOF
}

# Parse args
while [ $# -gt 0 ]; do
    case "$1" in
        --user)     TARGET="user" ;;
        --project)  TARGET="project" ;;
        --dest)
            shift
            if [ $# -eq 0 ]; then
                echo "Error: --dest requires a path" >&2
                exit 1
            fi
            DEST_OVERRIDE="$1"
            TARGET="custom"
            ;;
        --force)    FORCE=1 ;;
        -h|--help)  usage; exit 0 ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

# Determine commands destination
case "$TARGET" in
    user)
        BASE="${HOME:-${USERPROFILE:-}}"
        if [ -z "$BASE" ]; then
            echo "Error: neither \$HOME nor \$USERPROFILE is set" >&2
            exit 1
        fi
        DEST="$BASE/.claude/commands"
        ;;
    project)
        DEST="./.claude/commands"
        ;;
    custom)
        DEST="$DEST_OVERRIDE"
        ;;
esac

# Meta destination — vendor-neutral path.
# Priority: CREATE_MVP_HOME > $XDG_DATA_HOME/create-mvp > $HOME/.local/share/create-mvp
META_BASE="${HOME:-${USERPROFILE:-}}"
if [ -z "$META_BASE" ]; then
    echo "Error: neither \$HOME nor \$USERPROFILE is set (needed to resolve plans dir)" >&2
    exit 1
fi
if [ -n "${CREATE_MVP_HOME:-}" ]; then
    META_DIR="$CREATE_MVP_HOME"
else
    XDG_DATA_HOME_RESOLVED="${XDG_DATA_HOME:-$META_BASE/.local/share}"
    META_DIR="$XDG_DATA_HOME_RESOLVED/create-mvp"
fi

# One-time migration from the legacy ~/.claude/meta/create-mvp location.
LEGACY_META_DIR="$META_BASE/.claude/meta/create-mvp"
if [ -d "$LEGACY_META_DIR" ] && [ ! -d "$META_DIR" ]; then
    echo "  [migrate] copying plans + registry from $LEGACY_META_DIR to $META_DIR"
    mkdir -p "$(dirname "$META_DIR")"
    if cp -R "$LEGACY_META_DIR" "$META_DIR" 2>/dev/null; then
        echo "  [migrate] done — legacy dir kept at $LEGACY_META_DIR (delete manually when ready)"
    else
        echo "  [migrate] WARNING: copy failed; falling back to fresh bootstrap" >&2
    fi
fi

# Sanity: src/ exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: source directory not found: $SRC_DIR" >&2
    echo "Expected partials in $SRC_DIR/*.md" >&2
    exit 1
fi

# Collect partials in lexical (numeric-prefix) order
partial_count=0
for f in "$SRC_DIR"/*.md; do
    [ -f "$f" ] || continue
    partial_count=$((partial_count + 1))
done

if [ "$partial_count" -eq 0 ]; then
    echo "Error: no partials found in $SRC_DIR/*.md" >&2
    exit 1
fi

# Create commands destination
if ! mkdir -p "$DEST" 2>/dev/null; then
    echo "Error: failed to create $DEST" >&2
    exit 1
fi
DEST_ABS="$(cd "$DEST" && pwd)"

# Bootstrap meta dir + registry
mkdir -p "$META_DIR/plans"
if [ ! -f "$META_DIR/registry.json" ]; then
    printf '{\n  "version": 1,\n  "entries": {}\n}\n' > "$META_DIR/registry.json"
    echo "  [meta]    bootstrapped $META_DIR/registry.json"
else
    echo "  [meta]    using existing $META_DIR/registry.json"
fi

# Build the command file
out="$DEST_ABS/create-mvp.md"
marker='^generated-by: ai-skill-create-mvp install.sh$'

# Build to a temp file first so we can compare/cmp before publishing
tmp_out="$out.tmp.$$"
trap 'rm -f "$tmp_out"' EXIT INT TERM

: > "$tmp_out"
first=1
for f in "$SRC_DIR"/*.md; do
    [ -f "$f" ] || continue
    if [ "$first" -eq 1 ]; then
        first=0
    else
        # Insert thematic break between partials. Source files no longer carry
        # leading '---' (which broke IDE markdown rendering), so the installer
        # injects the divider here.
        printf '\n---\n\n' >> "$tmp_out"
    fi
    cat "$f" >> "$tmp_out"
    # Ensure newline at end of partial
    printf '\n' >> "$tmp_out"
done

if [ ! -s "$tmp_out" ]; then
    echo "  [fail]    create-mvp.md (concatenation produced empty file)" >&2
    exit 1
fi

publish() {
    mv "$tmp_out" "$out"
    bytes=$(wc -c < "$out" | tr -d ' ')
    echo "  [$1]      create-mvp.md ($bytes bytes from $partial_count partials)"
}

if [ -f "$out" ]; then
    if grep -q "$marker" "$out" 2>/dev/null; then
        # Existing file was previously installed by this script — safe to overwrite
        if cmp -s "$tmp_out" "$out"; then
            echo "  [unchanged] create-mvp.md (matches existing build)"
            rm -f "$tmp_out"
        else
            publish "updated"
        fi
    elif [ "$FORCE" -eq 1 ]; then
        echo "  [warn]    existing create-mvp.md has no install marker; --force overwriting anyway"
        publish "forced"
    else
        printf "  [exists]  create-mvp.md (no install marker — possibly hand-edited)\n            Overwrite? [y/N] "
        reply=""
        read -r reply || reply=""
        case "$reply" in
            y|Y|yes|YES) publish "ok" ;;
            *)
                echo "  [skip]    create-mvp.md"
                rm -f "$tmp_out"
                echo ""
                echo "Done."
                exit 0
                ;;
        esac
    fi
else
    publish "ok"
fi

# Deprecated resume-mvp.md cleanup
old_resume="$DEST_ABS/resume-mvp.md"
if [ -f "$old_resume" ]; then
    if [ "$FORCE" -eq 1 ]; then
        rm "$old_resume"
        echo "  [removed] resume-mvp.md (deprecated — use /create-mvp resume)"
    else
        printf "  [legacy]  resume-mvp.md found — remove? (deprecated, use /create-mvp resume) [y/N] "
        reply=""
        read -r reply || reply=""
        case "$reply" in
            y|Y|yes|YES)
                rm "$old_resume"
                echo "  [removed] resume-mvp.md"
                ;;
            *)
                echo "  [keep]    resume-mvp.md (will not be invoked anymore — safe to delete later)"
                ;;
        esac
    fi
fi

echo ""
echo "Commands: $DEST_ABS"
echo "Plans:    $META_DIR/plans"
echo "Registry: $META_DIR/registry.json"
echo ""
echo "Ready. In Claude Code:"
echo "  /create-mvp                      # start a new MVP"
echo "  /create-mvp resume               # resume an in-progress MVP"
echo "  /create-mvp resume status        # show status, don't execute"
