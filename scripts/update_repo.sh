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

    control="$(
        ar -p "$deb" "$member" |
        tar -xOf - ./control 2>/dev/null ||
        ar -p "$deb" "$member" |
        tar -xOf - control
    )"

    printf '%s\n' "$control" |
        awk '
            !/^Filename:/ &&
            !/^Size:/ &&
            !/^MD5sum:/ &&
            !/^SHA1:/ &&
            !/^SHA256:/
        ' >> Packages

    filename="debs/$(basename "$deb")"
    size="$(stat -f '%z' "$deb")"
    md5sum="$(md5 -q "$deb")"
    sha1="$(shasum -a 1 "$deb" | awk '{print $1}')"
    sha256="$(shasum -a 256 "$deb" | awk '{print $1}')"

    printf 'Filename: %s\n' "$filename" >> Packages
    printf 'Size: %s\n' "$size" >> Packages
    printf 'MD5sum: %s\n' "$md5sum" >> Packages
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
