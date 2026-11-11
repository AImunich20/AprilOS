#!/usr/bin/env bash
# Build AprilOS ISO ผ่าน Docker (macOS / Linux)
#
#   ./build.sh                 build ทุกสถาปัตยกรรม (amd64 + arm64) พร้อมกัน
#   ./build.sh arm64           build เฉพาะ arm64 (ARM, Apple Silicon VM)
#   ./build.sh amd64           build เฉพาะ amd64 (PC ทั่วไป / x86)
#
# ตัวแปรเสริม: SQUASH_COMP=xz ./build.sh   (ไฟล์เล็กกว่า แต่ช้ากว่า)
set -euo pipefail
cd "$(dirname "$0")"
ARCHES=("${@:-amd64 arm64}"); ARCHES=(${ARCHES[@]})

build_one() {
    local arch=$1
    docker build -q --platform "linux/${arch}" -t "aprilos-builder:${arch}" builder/ >/dev/null
    docker run --rm --privileged --platform "linux/${arch}" \
        -e ARCH="$arch" -e SQUASH_COMP="${SQUASH_COMP:-zstd}" \
        -v "$PWD":/work \
        -v "aprilos-cache-${arch}":/cache \
        -v "aprilos-work-${arch}":/build \
        "aprilos-builder:${arch}" /work/scripts/build-iso.sh
}

mkdir -p out/logs
start=$(date +%s); pids=()
for a in "${ARCHES[@]}"; do
    echo "==> เริ่ม build ${a} (log: out/logs/build-${a}.log)"
    build_one "$a" > "out/logs/build-${a}.log" 2>&1 &
    pids+=("$!:$a")
done

fail=0
for p in "${pids[@]}"; do
    if wait "${p%%:*}"; then echo "✓ ${p#*:} สำเร็จ"; else echo "✗ ${p#*:} ล้มเหลว — ดู out/logs/build-${p#*:}.log"; fail=1; fi
done

# สร้าง checksum ของ ISO ทั้งหมด พร้อมแนบขึ้น Release
(cd out && ls *.iso >/dev/null 2>&1 && shasum -a 256 *.iso > ISO-SHA256SUMS) || true
echo "ใช้เวลา $(( ($(date +%s) - start) / 60 )) นาที"; ls -lh out/*.iso 2>/dev/null || true
exit $fail
