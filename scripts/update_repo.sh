#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

: > Packages

found=0

for deb in debs/*.deb; do
    [ -f "$deb" ] || continue

    found=1

    member="$(ar -t "$deb" | tr -d '\r' | grep '^control\.tar' | head -n 1)"

    if [ -z "$member" ]; then
        echo "No control.tar found in: $deb"
        exit 1
    fi

    case "$member" in
        *.gz)  decomp="gzip -dc" ;;
        *.xz)  decomp="xz -dc" ;;
        *.lzma) decomp="xz --format=lzma -dc" ;;
        *.bz2) decomp="bzip2 -dc" ;;
        *.zst) decomp="zstd -dc" ;;
        *)     decomp="cat" ;;
    esac

    tmpdir="$(mktemp -d)"
    ar -p "$deb" "$member" | $decomp | tar -xf - -C "$tmpdir"
    control="$(cat "$tmpdir/control")"
    rm -rf "$tmpdir"

    printf '%s\n' "$control" |
        awk '
            !/^Filename:/ &&
            !/^Size:/ &&
            !/^MD5sum:/ &&
            !/^SHA1:/ &&
            !/^SHA256:/
        ' >> Packages

    filename="debs/$(basename "$deb")"
    size="$(wc -c < "$deb" | tr -d ' ')"
    if command -v md5sum >/dev/null 2>&1; then
        md5="$(md5sum "$deb" | awk '{print $1}')"
        sha1="$(sha1sum "$deb" | awk '{print $1}')"
        sha256="$(sha256sum "$deb" | awk '{print $1}')"
    else
        md5="$(md5 -q "$deb")"
        sha1="$(shasum -a 1 "$deb" | awk '{print $1}')"
        sha256="$(shasum -a 256 "$deb" | awk '{print $1}')"
    fi

    printf 'Filename: %s\n' "$filename" >> Packages
    printf 'Size: %s\n' "$size" >> Packages
    printf 'MD5sum: %s\n' "$md5" >> Packages
    printf 'SHA1: %s\n' "$sha1" >> Packages
    printf 'SHA256: %s\n\n' "$sha256" >> Packages
done

if [ "$found" -eq 0 ]; then
    echo "No .deb packages found in debs/"
    exit 1
fi

bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz

echo
echo "Repository updated:"
echo "  Packages"
echo "  Packages.bz2"
echo "  Packages.gz"
echo
grep '^Package:' Packages || true
