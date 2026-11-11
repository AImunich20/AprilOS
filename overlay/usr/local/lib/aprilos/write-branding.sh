#!/usr/bin/env bash
# เขียนไฟล์ที่ระบุตัวตนของระบบเป็น AprilOS จากไฟล์ config
# ใช้ทั้งตอน build (customize-chroot.sh) และตอนอัปเดต (aprilos-update)
# usage: write-branding.sh /path/to/aprilos.conf
set -euo pipefail
source "$1"

# divert ครั้งเดียว เพื่อไม่ให้ base-files ของ Ubuntu เขียนทับตอน apt upgrade
for f in /usr/lib/os-release /etc/lsb-release; do
    dpkg-divert --list "$f" | grep -q . || dpkg-divert --local --rename --add "$f"
done

cat > /usr/lib/os-release <<OSR
PRETTY_NAME="${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
NAME="${OS_NAME}"
VERSION_ID="${OS_VERSION}"
VERSION="${OS_VERSION} (${OS_CODENAME})"
VERSION_CODENAME=${OS_CODENAME}
ID=${OS_ID}
ID_LIKE="ubuntu debian"
UBUNTU_CODENAME=${UBUNTU_CODENAME}
HOME_URL="https://github.com/${GITHUB_REPO}"
BUG_REPORT_URL="https://github.com/${GITHUB_REPO}/issues"
OSR
ln -sf ../usr/lib/os-release /etc/os-release

cat > /etc/lsb-release <<LSB
DISTRIB_ID=${OS_NAME}
DISTRIB_RELEASE=${OS_VERSION}
DISTRIB_CODENAME=${OS_CODENAME}
DISTRIB_DESCRIPTION="${OS_NAME} ${OS_VERSION}"
LSB

mkdir -p /etc/aprilos
echo "$OS_VERSION" > /etc/aprilos/version
# เก็บค่าตั้งของ updater ไว้ แต่ไม่ทับค่าที่ผู้ใช้แก้เอง (AUTO_APPLY ฯลฯ)
if [ ! -f /etc/aprilos/update.conf ]; then
    cat > /etc/aprilos/update.conf <<UPD
# แหล่งอัปเดตของ AprilOS (GitHub owner/repo)
GITHUB_REPO="${GITHUB_REPO}"
# yes = ติดตั้งอัปเดตอัตโนมัติเมื่อ timer ตรวจเจอ, no = แจ้งเตือนอย่างเดียว
AUTO_APPLY="no"
# yes = รวม prerelease ด้วย (ช่องทาง beta)
INCLUDE_PRERELEASE="no"
UPD
else
    sed -i "s|^GITHUB_REPO=.*|GITHUB_REPO=\"${GITHUB_REPO}\"|" /etc/aprilos/update.conf
fi
