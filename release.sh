#!/usr/bin/env bash
# ปล่อยเวอร์ชันใหม่ของ AprilOS ขึ้น GitHub → เครื่องผู้ใช้จะอัปเดตตามอัตโนมัติ
# usage: ./release.sh 0.2 "สรุปสิ่งที่เปลี่ยน"   (เพิ่ม --beta เพื่อปล่อยเป็น prerelease)
set -euo pipefail
cd "$(dirname "$0")"
VER="${1:?ระบุเวอร์ชัน เช่น ./release.sh 0.2 \"notes\"}"
NOTES="${2:-AprilOS $VER}"
PRE=""; [ "${3:-}" = "--beta" ] && PRE="--prerelease"
source config/aprilos.conf

command -v gh >/dev/null || { echo "ต้องติดตั้ง GitHub CLI (gh) ก่อน"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "มีไฟล์ที่ยังไม่ commit — commit ก่อนแล้วค่อย release"; exit 1; }
git rev-parse "v$VER" >/dev/null 2>&1 && { echo "มีแท็ก v$VER อยู่แล้ว"; exit 1; }
if [ "$VER" != "$OS_VERSION" ] && [ "$(printf '%s\n' "$OS_VERSION" "$VER" | sort -V | tail -1)" != "$VER" ]; then
    echo "เวอร์ชันใหม่ ($VER) ต้องมากกว่าเวอร์ชันปัจจุบัน ($OS_VERSION)"; exit 1
fi

# 1) bump เวอร์ชันใน config แล้ว commit + tag
sed -i.bak "s/^OS_VERSION=.*/OS_VERSION=\"$VER\"/" config/aprilos.conf && rm config/aprilos.conf.bak
git add config/aprilos.conf
git diff --cached --quiet || git commit -m "Release AprilOS $VER"
git tag -a "v$VER" -m "AprilOS $VER"
git push origin HEAD "v$VER"

# 2) สร้าง release แล้วแนบ SHA256SUMS ของ source tarball (ให้เครื่องผู้ใช้ตรวจความถูกต้อง)
gh release create "v$VER" --repo "$GITHUB_REPO" --title "AprilOS $VER" --notes "$NOTES" $PRE
tmp=$(mktemp -d)
curl -fsSL "https://github.com/${GITHUB_REPO}/archive/refs/tags/v${VER}.tar.gz" -o "$tmp/src.tar.gz"
(cd "$tmp" && shasum -a 256 src.tar.gz > SHA256SUMS)
gh release upload "v$VER" "$tmp/SHA256SUMS" --repo "$GITHUB_REPO"

# 3) แนบ ISO ถ้ามี build ไว้แล้ว
ISO="out/AprilOS-${VER}-${ARCH}.iso"
[ -f "$ISO" ] && gh release upload "v$VER" "$ISO" --repo "$GITHUB_REPO"
rm -rf "$tmp"
echo "✅ ปล่อย AprilOS $VER แล้ว: https://github.com/${GITHUB_REPO}/releases/tag/v$VER"
