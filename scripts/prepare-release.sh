#!/usr/bin/env bash
# เตรียม Release แบบ Draft บน GitHub พร้อมแนบ ISO ทุกสถาปัตยกรรม
# แล้วไปกด "Publish release" เองบนหน้าเว็บ GitHub เมื่อพร้อม
#
#   ./scripts/prepare-release.sh "สรุปสิ่งที่เปลี่ยนในเวอร์ชันนี้"
set -euo pipefail
cd "$(dirname "$0")/.."
source config/aprilos.conf
TAG="v${OS_VERSION}"
NOTES_EXTRA="${1:-}"

command -v gh >/dev/null || { echo "ต้องติดตั้ง GitHub CLI (gh)"; exit 1; }
shopt -s nullglob
ISOS=(out/${OS_NAME}-${OS_VERSION}-*.iso)
[ ${#ISOS[@]} -gt 0 ] || { echo "ไม่พบ ISO ของเวอร์ชัน ${OS_VERSION} ใน out/ — รัน ./build.sh ก่อน"; exit 1; }
for f in "${ISOS[@]}"; do
    [ "$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")" -lt 2147483648 ] || { echo "$f ใหญ่เกิน 2 GB (ขีดจำกัดของ GitHub)"; exit 1; }
done
(cd out && shasum -a 256 $(basename -a "${ISOS[@]}") > ISO-SHA256SUMS)

if gh release view "$TAG" --repo "$GITHUB_REPO" >/dev/null 2>&1; then
    echo "มี release $TAG อยู่แล้ว → อัปโหลด ISO ทับของเดิม"
    gh release upload "$TAG" "${ISOS[@]}" out/ISO-SHA256SUMS --repo "$GITHUB_REPO" --clobber
else
    notes=$(cat <<NOTES
## ${OS_NAME} ${OS_VERSION} "${OS_CODENAME}"

${NOTES_EXTRA}

### ดาวน์โหลด

| ไฟล์ | ใช้กับ |
|---|---|
| \`${OS_NAME}-${OS_VERSION}-amd64.iso\` | PC และโน้ตบุ๊กทั่วไป (Intel / AMD, x86_64) และ Mac Intel |
| \`${OS_NAME}-${OS_VERSION}-arm64.iso\` | เครื่อง ARM64 ที่มี UEFI และ VM บน Mac Apple Silicon (UTM, Parallels, VMware Fusion) |

ตรวจความถูกต้องของไฟล์ด้วย \`ISO-SHA256SUMS\`

เครื่องที่ติดตั้ง AprilOS ไว้แล้วจะได้รับอัปเดตนี้อัตโนมัติผ่าน \`aprilos-update\`
NOTES
)
    gh release create "$TAG" --repo "$GITHUB_REPO" --draft --target main \
        --title "${OS_NAME} ${OS_VERSION}" --notes "$notes" \
        "${ISOS[@]}" out/ISO-SHA256SUMS
fi
echo "Draft พร้อมแล้ว: https://github.com/${GITHUB_REPO}/releases"
echo "ตรวจดูแล้วกด 'Publish release' เมื่อพร้อม"
