#!/usr/bin/env bash
# Monta o .deb do device package (anatomia: SDD §6.1)
set -euo pipefail
cd "$(dirname "$0")"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
D="$STAGE/usr/share/meridian/devices/nokia-superman"
mkdir -p "$D/kernel" "$D/dts" "$D/firmware" "$D/flash"
cp device.yaml "$D/"
cp kernel/fragment.config "$D/kernel/"
cp kernel/patches/series "$D/kernel/"
cp dts/*.dts "$D/dts/"
cp firmware/firmware-manifest.yaml "$D/firmware/"
cp hwinit.sh "$D/"
cp flash/rawprogram.xml flash/patch.xml flash/backup.sh "$D/flash/" 2>/dev/null || true
cp recovery.md "$D/"
cp -r package/DEBIAN "$STAGE/"
chmod +x "$STAGE/DEBIAN/postinst" "$D/hwinit.sh" 2>/dev/null || true
mkdir -p output
dpkg-deb --build "$STAGE" "output/meridian-device-nokia-superman_0.1.0_armhf.deb"
ls -la output/
