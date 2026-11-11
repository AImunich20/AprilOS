#!/usr/bin/env bash
# รันบน macOS/Linux ที่มี Docker: สร้าง builder image แล้ว build ISO ข้างใน container
set -euo pipefail
cd "$(dirname "$0")"
source config/aprilos.conf

docker build --platform "linux/${ARCH}" -t aprilos-builder builder/
docker run --rm --privileged --platform "linux/${ARCH}" \
    -v "$PWD":/work aprilos-builder /work/scripts/build-iso.sh

echo "✅ เสร็จแล้ว: $(ls out/*.iso)"
