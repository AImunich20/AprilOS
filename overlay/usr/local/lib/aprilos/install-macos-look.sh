#!/usr/bin/env bash
# ติดตั้งหน้าตาแบบ macOS ให้ AprilOS (รันเป็น root)
# ใช้ทั้งตอน build (customize-chroot.sh) และตอนอัปเดต (updates/migrations)
#
# ธีมทั้งหมดเป็นโอเพนซอร์สของโปรเจกต์ WhiteSur (https://github.com/vinceliuice)
#   - WhiteSur-gtk-theme  : GTK2/3/4 + กรอบหน้าต่าง xfwm4 + ธีม Dock ของ Plank  (MIT)
#   - WhiteSur-icon-theme : ไอคอน                                              (GPL-3.0)
#   - WhiteSur-cursors    : เคอร์เซอร์                                          (GPL-3.0)
# ล็อกเวอร์ชันและตรวจ sha256 ทุกไฟล์ เพื่อให้ build ซ้ำได้ผลเหมือนเดิม
set -euo pipefail

GTK_VER=2026-09-10
ICON_VER=2026-09-10
CURSOR_REV=e190baf618ed95ee217d2fd45589bd309b37672b

GTK_URL="https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/${GTK_VER}.tar.gz"
GTK_SHA=65516c8f45da45c602471e31b4de0b6e9aed6eb3fc3820df16161d077245a1a2
ICON_URL="https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/tags/${ICON_VER}.tar.gz"
ICON_SHA=406c9cd59705583f1754b0eaca96cc48bafda042b88ef143f16d8ae1820ecd95
CURSOR_URL="https://github.com/vinceliuice/WhiteSur-cursors/archive/${CURSOR_REV}.tar.gz"
CURSOR_SHA=35c817c2c26bc4d2c06801cfe6c924a068ad771d3846c5203b04d1c893dd5664

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fetch() {  # url sha256 ชื่อไฟล์
    curl -fsSL --retry 5 --retry-delay 5 -o "$TMP/$3" "$1"
    echo "$2  $TMP/$3" | sha256sum -c --quiet -
    tar -xzf "$TMP/$3" -C "$TMP"
}
fetch "$GTK_URL"    "$GTK_SHA"    gtk.tar.gz
fetch "$ICON_URL"   "$ICON_SHA"   icon.tar.gz
fetch "$CURSOR_URL" "$CURSOR_SHA" cursor.tar.gz

# ---- ธีม GTK + xfwm4 (Light = เดสก์ท็อป, Dark = หน้าล็อกอิน) ----
for v in Light Dark; do
    rm -rf "/usr/share/themes/WhiteSur-$v"
    tar -xJf "$TMP/WhiteSur-gtk-theme-${GTK_VER}/release/WhiteSur-$v.tar.xz" -C /usr/share/themes
    # ธีม Dock ของ Plank มากับธีม GTK
    mkdir -p "/usr/share/plank/themes/WhiteSur-$v"
    cp "/usr/share/themes/WhiteSur-$v/plank/dock.theme" "/usr/share/plank/themes/WhiteSur-$v/"
done

# ---- ไอคอน (WhiteSur, WhiteSur-light, WhiteSur-dark) ----
bash "$TMP/WhiteSur-icon-theme-${ICON_VER}/install.sh" -d /usr/share/icons >/dev/null

# ---- เคอร์เซอร์ ----
rm -rf /usr/share/icons/WhiteSur-cursors
cp -a "$TMP/WhiteSur-cursors-${CURSOR_REV}/dist" /usr/share/icons/WhiteSur-cursors
printf '[Icon Theme]\nInherits=WhiteSur-cursors\n' > /usr/share/icons/WhiteSur-cursors/cursor.theme
update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme \
    /usr/share/icons/WhiteSur-cursors/cursor.theme 90 >/dev/null
update-alternatives --set x-cursor-theme /usr/share/icons/WhiteSur-cursors/cursor.theme >/dev/null

for d in /usr/share/icons/WhiteSur /usr/share/icons/WhiteSur-light /usr/share/icons/WhiteSur-dark /usr/share/icons/hicolor; do
    gtk-update-icon-cache -qf "$d" 2>/dev/null || true
done

# ---- ค่าเริ่มต้นของ Dock (Plank) และ ibus ใน dconf/gsettings ----
dconf update 2>/dev/null || true
glib-compile-schemas /usr/share/glib-2.0/schemas
echo "ติดตั้งหน้าตาแบบ macOS (WhiteSur) เรียบร้อย"
