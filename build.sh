#!/bin/bash

set -Eeuo pipefail
trap 'echo "❌ ERROR: Command \"$BASH_COMMAND\" failed at line $LINENO." >&2' ERR

KERN_DIR="kern"
TODAY=$(date +%Y/%m/%d)

normalize_file() {
    f="$1"
    last_byte=$(tail -c1 "$f" 2>/dev/null | od -An -t u1 | tr -d ' ')
    if [ "$last_byte" = "10" ]; then
        truncate -s -1 "$f"
    fi
}

for kern_file in "$KERN_DIR"/*; do
    if [ -f "$kern_file" ]; then
        echo "Processing $kern_file..."

        tmp_file=$(mktemp)
        barnum "$kern_file" \
            | sed '/^\*I"/d;/^\*I'\''/d' \
            > "$tmp_file"
        normalize_file "$tmp_file"

        if ! cmp -s "$tmp_file" "$kern_file"; then
            echo "Changes detected, updating $kern_file..."
            mv "$tmp_file" "$kern_file"
            tmp_file2=$(mktemp)
            sed "s|^!!!EEV:.*|!!!EEV: $TODAY|" "$kern_file" > "$tmp_file2"
            mv "$tmp_file2" "$kern_file"
        else
            echo "No changes in $kern_file, skipping update."
            rm "$tmp_file"
        fi

        normalize_file "$kern_file"
    fi
done

echo "Done!"