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

Plans + registry always live under \$HOME/.claude/meta/create-mvp/, regardless
of where the command file is installed.
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

# Meta destination is always user-level
META_BASE="${HOME:-${USERPROFILE:-}}"
if [ -z "$META_BASE" ]; then
    echo "Error: neither \$HOME nor \$USERPROFILE is set (needed for ~/.claude/meta/create-mvp)" >&2
    exit 1
fi
META_DIR="$META_BASE/.claude/meta/create-mvp"

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

if [ -f "$out" ] && [ "$FORCE" -eq 0 ]; then
    printf "  [exists]  create-mvp.md — overwrite? [y/N] "
    reply=""
    read -r reply || reply=""
    case "$reply" in
        y|Y|yes|YES) ;;
        *)
            echo "  [skip]    create-mvp.md"
            echo ""
            echo "Done."
            exit 0
            ;;
    esac
fi

# Concatenate partials (lexical order from glob)
: > "$out"
for f in "$SRC_DIR"/*.md; do
    [ -f "$f" ] || continue
    cat "$f" >> "$out"
    # Ensure newline between partials
    printf '\n' >> "$out"
done

if [ -f "$out" ]; then
    bytes=$(wc -c < "$out" | tr -d ' ')
    echo "  [ok]      create-mvp.md ($bytes bytes from $partial_count partials)"
else
    echo "  [fail]    create-mvp.md" >&2
    exit 1
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
