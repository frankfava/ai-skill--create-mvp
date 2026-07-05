#!/usr/bin/env sh
# export-skill.sh — build a cloud Claude Skill bundle from src/*.md partials.
# Produces:
#   <out>/create-mvp/SKILL.md    (required by Anthropic's Skill format)
#   <out>/create-mvp.zip         (if `zip` is on PATH and --no-zip not set)
#
# POSIX sh. Works on Linux, macOS, WSL, and Git Bash (Windows).

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

SKILL_NAME="create-mvp"
SKILL_DESCRIPTION="Interactive MVP workflow — turns a vague idea into a checkpointed, parallel-executed MVP. Use when the user wants to scope, plan, or build an MVP, prototype, or new project from scratch."
MARKER="generated-by: ai-skill-create-mvp export-skill.sh"

OUT_DIR="$SCRIPT_DIR/dist"
NO_ZIP=0
FORCE=0
ARCHIVE_EXT="zip"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Builds a cloud Claude Skill bundle by concatenating $SCRIPT_DIR/src/*.md
in numeric order and swapping the Claude-Code frontmatter for cloud-skill YAML.

Options:
  --out PATH      Output root directory (default: $SCRIPT_DIR/dist)
  --skill         Name the archive $SKILL_NAME.skill instead of .zip
                  (same zip format; .skill is Anthropic's native extension)
  --no-zip        Skip producing the archive even if 'zip' is available
  --force         Overwrite existing SKILL.md without prompting
  -h, --help      Show this help

Outputs:
  <out>/$SKILL_NAME/SKILL.md
  <out>/$SKILL_NAME.zip    (when 'zip' is on PATH; .skill with --skill)
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --out)
            shift
            if [ $# -eq 0 ]; then
                echo "Error: --out requires a path" >&2
                exit 1
            fi
            OUT_DIR="$1"
            ;;
        --skill)  ARCHIVE_EXT="skill" ;;
        --no-zip) NO_ZIP=1 ;;
        --force)  FORCE=1 ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [ ! -d "$SRC_DIR" ]; then
    echo "Error: source directory not found: $SRC_DIR" >&2
    exit 1
fi

partial_count=0
for f in "$SRC_DIR"/*.md; do
    [ -f "$f" ] || continue
    partial_count=$((partial_count + 1))
done
if [ "$partial_count" -eq 0 ]; then
    echo "Error: no partials found in $SRC_DIR/*.md" >&2
    exit 1
fi

# Description sanity: cloud spec caps description at 200 chars.
desc_len=$(printf %s "$SKILL_DESCRIPTION" | wc -c | tr -d ' ')
if [ "$desc_len" -gt 200 ]; then
    echo "Error: SKILL_DESCRIPTION is $desc_len chars (max 200)" >&2
    exit 1
fi

SKILL_DIR="$OUT_DIR/$SKILL_NAME"
SKILL_FILE="$SKILL_DIR/SKILL.md"

mkdir -p "$SKILL_DIR"

tmp_concat="$SKILL_DIR/.concat.$$"
tmp_out="$SKILL_DIR/.SKILL.md.$$"
trap 'rm -f "$tmp_concat" "$tmp_out"' EXIT INT TERM

# Step 1: concatenate partials with thematic-break dividers (same as install.sh).
: > "$tmp_concat"
first=1
for f in "$SRC_DIR"/*.md; do
    [ -f "$f" ] || continue
    if [ "$first" -eq 1 ]; then
        first=0
    else
        printf '\n---\n\n' >> "$tmp_concat"
    fi
    cat "$f" >> "$tmp_concat"
    printf '\n' >> "$tmp_concat"
done

if [ ! -s "$tmp_concat" ]; then
    echo "Error: concatenation produced empty file" >&2
    exit 1
fi

# Step 2: build SKILL.md = cloud frontmatter + body-after-original-frontmatter.
{
    printf -- '---\n'
    printf 'name: %s\n' "$SKILL_NAME"
    printf 'description: %s\n' "$SKILL_DESCRIPTION"
    printf '%s\n' "$MARKER"
    printf -- '---\n'
    # Strip the first YAML frontmatter block from the concatenated body.
    # Reads lines: if the first non-empty line is '---', skip until the next '---'.
    awk '
        BEGIN { state = "pre" }
        state == "pre" {
            if ($0 ~ /^[[:space:]]*$/) { next }
            if ($0 == "---") { state = "in_fm"; next }
            state = "body"
            print
            next
        }
        state == "in_fm" {
            if ($0 == "---") { state = "body"; next }
            next
        }
        state == "body" { print }
    ' "$tmp_concat"
} > "$tmp_out"

if [ ! -s "$tmp_out" ]; then
    echo "Error: SKILL.md build produced empty file" >&2
    exit 1
fi

# Step 3: publish (idempotent, with overwrite handling).
publish() {
    mv "$tmp_out" "$SKILL_FILE"
    rm -f "$tmp_concat"
    bytes=$(wc -c < "$SKILL_FILE" | tr -d ' ')
    echo "  [$1]      $SKILL_FILE ($bytes bytes from $partial_count partials)"
}

if [ -f "$SKILL_FILE" ]; then
    if grep -q "^${MARKER}\$" "$SKILL_FILE" 2>/dev/null; then
        if cmp -s "$tmp_out" "$SKILL_FILE"; then
            echo "  [unchanged] $SKILL_FILE (matches existing build)"
            rm -f "$tmp_out" "$tmp_concat"
        else
            publish "updated"
        fi
    elif [ "$FORCE" -eq 1 ]; then
        echo "  [warn]    existing SKILL.md has no export marker; --force overwriting anyway"
        publish "forced"
    else
        printf "  [exists]  %s (no export marker — possibly hand-edited)\n            Overwrite? [y/N] " "$SKILL_FILE"
        reply=""
        read -r reply || reply=""
        case "$reply" in
            y|Y|yes|YES) publish "ok" ;;
            *)
                echo "  [skip]    $SKILL_FILE"
                rm -f "$tmp_out" "$tmp_concat"
                echo ""
                echo "Done."
                exit 0
                ;;
        esac
    fi
else
    publish "ok"
fi

# Step 4: zip the folder as root (cloud spec requires `create-mvp/SKILL.md` inside).
# .skill and .zip are the same zip format — only the extension differs.
ZIP_NAME="$SKILL_NAME.$ARCHIVE_EXT"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"
if [ "$NO_ZIP" -eq 1 ]; then
    echo "  [skip]    archive (--no-zip)"
elif command -v zip >/dev/null 2>&1; then
    rm -f "$ZIP_PATH"
    # cd into OUT_DIR so the folder name is the zip root, not the absolute path.
    ( cd "$OUT_DIR" && zip -rq "$ZIP_NAME" "$SKILL_NAME" )
    zip_bytes=$(wc -c < "$ZIP_PATH" | tr -d ' ')
    echo "  [$ARCHIVE_EXT]     $ZIP_PATH ($zip_bytes bytes)"
else
    echo "  [skip]    zip not found — install 'zip' or pass --no-zip to silence"
fi

echo ""
echo "Skill bundle: $SKILL_DIR"
if [ -f "$ZIP_PATH" ]; then
    echo "Archive:      $ZIP_PATH"
fi
echo ""
echo "Upload the .$ARCHIVE_EXT (or the SKILL.md alone) at claude.ai → Settings → Skills."
