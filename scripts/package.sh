#!/bin/sh
# Builds acal for Apple silicon and Intel, signs it ad hoc, and packs it for a GitHub release.
# The result is in dist/: acal-<version>-macos-universal.tar.gz and its .sha256 file.
set -eu
cd "$(dirname "$0")/.."

swift build -c release --arch arm64 --arch x86_64
bin=.build/apple/Products/Release/acal
codesign --force --sign - "$bin"

version="$("$bin" --version)"
name="acal-$version-macos-universal"
rm -rf "dist/$name" "dist/$name.tar.gz" "dist/$name.tar.gz.sha256"
mkdir -p "dist/$name"
cp "$bin" LICENSE "dist/$name/"
# Fixed owner and no macOS metadata, so the archive does not carry the packer's user name.
tar --uid 0 --gid 0 --uname root --gname wheel --no-mac-metadata -C dist -czf "dist/$name.tar.gz" "$name"
(cd dist && shasum -a 256 "$name.tar.gz" > "$name.tar.gz.sha256")

echo "Packed dist/$name.tar.gz"
lipo -archs "$bin"
