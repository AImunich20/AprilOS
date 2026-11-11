#!/usr/bin/env bash
# รันภายใน chroot ของ AprilOS
set -euo pipefail
source /tmp/aprilos/aprilos.conf
export DEBIAN_FRONTEND=noninteractive LC_ALL=C

if [ "$ARCH" = "amd64" ]; then M="$UBUNTU_MIRROR"; S="http://security.ubuntu.com/ubuntu"; else M="$UBUNTU_MIRROR"; S="$UBUNTU_MIRROR"; fi
cat > /etc/apt/sources.list <<SRC
deb $M $UBUNTU_CODENAME main restricted universe multiverse
deb $M $UBUNTU_CODENAME-updates main restricted universe multiverse
deb $S $UBUNTU_CODENAME-security main restricted universe multiverse
SRC

apt-get update
apt-get -y upgrade
grep -vE '^\s*(#|$)' /tmp/aprilos/packages.list | xargs apt-get install -y

# ภาษา / เวลา
locale-gen $LOCALE $EXTRA_LOCALES
update-locale LANG="$LOCALE"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime; echo "$TIMEZONE" > /etc/timezone

# ไฟล์ปรับแต่งเพิ่มเติม + ระบบอัปเดต (overlay/ จะถูกคัดลอกทับ / ทั้งหมด)
cp -a --no-preserve=ownership /tmp/aprilos/overlay/. /

# ---- Branding: ระบุตัวตนเป็น AprilOS + ตั้งค่า updater ----
bash /usr/local/lib/aprilos/write-branding.sh /tmp/aprilos/aprilos.conf
systemctl enable aprilos-update.timer
echo "$HOSTNAME" > /etc/hostname

# ตั้งชื่อผู้ใช้/โฮสต์ของ live session
cat > /etc/casper.conf <<CAS
export USERNAME="${LIVE_USER}"
export USERFULLNAME="${OS_NAME} Live User"
export HOST="${HOSTNAME}"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="${OS_NAME}"
CAS

update-initramfs -u -k all

# ล้างของที่ไม่ต้องใช้
apt-get -y autoremove --purge
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
