#!/usr/bin/env bash
# 0.2: หน้าตาแบบ macOS (ธีม WhiteSur, แถบเมนูด้านบน, Dock แบบ Plank)
# แพ็กเกจใหม่ (plank, fonts-inter ฯลฯ) และไฟล์ overlay ถูกติดตั้งก่อนขั้นนี้แล้ว
set -e
bash /usr/local/lib/aprilos/install-macos-look.sh
# เปลี่ยนภาพพื้นหลังเริ่มต้นของ XFCE (symlink ที่ divert ไว้ตอน build) ไปเป็นภาพใหม่
for f in /usr/share/backgrounds/xfce/*; do
    [ -L "$f" ] && [ "$(readlink "$f")" = /usr/share/backgrounds/aprilos/aprilos-default.svg ] \
        && ln -sf /usr/share/backgrounds/aprilos/aprilos-waves.svg "$f"
done
# ผู้ใช้เดิมยังใช้ค่าตั้งเดิมของตัวเอง — ใช้หน้าตาใหม่ได้ด้วย: aprilos-apply-macos-look
