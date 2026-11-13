#!/usr/bin/env bash
# รันภายใน chroot ของ AprilOS
set -euo pipefail
source /tmp/aprilos/aprilos.conf
export DEBIAN_FRONTEND=noninteractive LC_ALL=C

if [ "$ARCH" = "amd64" ]; then S="http://security.ubuntu.com/ubuntu"; else S="$UBUNTU_MIRROR"; fi
cat > /etc/apt/sources.list <<SRC
deb $UBUNTU_MIRROR $UBUNTU_CODENAME main restricted universe multiverse
deb $UBUNTU_MIRROR $UBUNTU_CODENAME-updates main restricted universe multiverse
deb $S $UBUNTU_CODENAME-security main restricted universe multiverse
SRC

# ---- เร่งความเร็วการ build ----
# ไม่ fsync ทุกไฟล์ (eatmydata) และไม่สร้าง index ของ man page ระหว่างติดตั้ง
echo 'APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/99aprilos-build
echo "man-db man-db/auto-update boolean false" | debconf-set-selections
apt-get update
apt-get install -y eatmydata
APT="eatmydata apt-get -o Dpkg::Options::=--force-confnew"

$APT -y upgrade

# bootloader ของแต่ละสถาปัตยกรรม (ตัวติดตั้งใช้ติดตั้ง GRUB ลงดิสก์)
case "$ARCH" in
    amd64) BOOT_PKGS="grub-efi-amd64 grub-pc-bin efibootmgr" ;;
    arm64) BOOT_PKGS="grub-efi-arm64 efibootmgr" ;;
esac
grep -vE '^\s*(#|$)' /tmp/aprilos/packages.list | xargs $APT install -y $BOOT_PKGS

# ภาษา / เวลา
locale-gen $LOCALE $EXTRA_LOCALES
update-locale LANG="$LOCALE"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime; echo "$TIMEZONE" > /etc/timezone

# ไฟล์ปรับแต่งเพิ่มเติม + ระบบอัปเดต + ตัวติดตั้ง (overlay/ จะถูกคัดลอกทับ / ทั้งหมด)
cp -a --no-preserve=ownership /tmp/aprilos/overlay/. /

# ---- Branding: ระบุตัวตนเป็น AprilOS + ตั้งค่า updater ----
bash /usr/local/lib/aprilos/write-branding.sh /tmp/aprilos/aprilos.conf
systemctl enable aprilos-update.timer aprilos-autoinstall.service
chmod 755 /usr/local/sbin/* /usr/local/bin/* /usr/local/lib/aprilos/*.sh
# หน้าตาแบบ macOS: ธีม/ไอคอน/เคอร์เซอร์ WhiteSur + ค่าเริ่มต้นของ Dock (ค่า XFCE อยู่ใน overlay/etc/skel)
bash /usr/local/lib/aprilos/install-macos-look.sh
echo "$HOSTNAME" > /etc/hostname

# wallpaper: ชี้ภาพพื้นหลังเริ่มต้นของ XFCE มาที่ภาพของ AprilOS
WP=/usr/share/backgrounds/aprilos/aprilos-waves.svg
for f in $(ls /usr/share/backgrounds/xfce/*.{svg,png,jpg} 2>/dev/null); do
    case "$f" in *aprilos*) ;; *) dpkg-divert --local --rename --add "$f" >/dev/null; ln -sf "$WP" "$f" ;; esac
done

# ตั้งชื่อผู้ใช้/โฮสต์ของ live session
cat > /etc/casper.conf <<CAS
export USERNAME="${LIVE_USER}"
export USERFULLNAME="${OS_NAME} Live User"
export HOST="${HOSTNAME}"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="${OS_NAME}"
CAS

echo "man-db man-db/auto-update boolean true" | debconf-set-selections
update-initramfs -u -k all

# ล้างของที่ไม่ต้องใช้ (ไฟล์ .deb ถูกเก็บไว้ใน cache ของ build และลบออกจาก image ภายหลัง)
$APT -y autoremove --purge
apt-get -y purge eatmydata libeatmydata1 || true
rm -f /etc/apt/apt.conf.d/99aprilos-build
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
