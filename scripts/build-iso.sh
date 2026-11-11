#!/usr/bin/env bash
# รันภายใน builder container เท่านั้น
set -euo pipefail
source /work/config/aprilos.conf

WORK=/build            # ไม่ใช้โฟลเดอร์ที่ mount จาก macOS เพราะ device node/permission จะเพี้ยน
CHROOT=$WORK/chroot
ISO=$WORK/iso
OUT=/work/out
ISO_NAME="${OS_NAME}-${OS_VERSION}-${ARCH}.iso"

rm -rf "$WORK"; mkdir -p "$CHROOT" "$ISO/casper" "$ISO/boot/grub" "$OUT"

echo "==> [1/5] debootstrap ${UBUNTU_CODENAME} (${ARCH})"
debootstrap --arch="$ARCH" --variant=minbase "$UBUNTU_CODENAME" "$CHROOT" "$UBUNTU_MIRROR"

mount_chroot() {
    for d in dev dev/pts proc sys run; do mount --bind "/$d" "$CHROOT/$d"; done
}
umount_chroot() {
    for d in run sys proc dev/pts dev; do umount -lf "$CHROOT/$d" 2>/dev/null || true; done
}
trap umount_chroot EXIT

echo "==> [2/5] ปรับแต่งระบบใน chroot"
mkdir -p "$CHROOT/tmp/aprilos"
cp /work/config/aprilos.conf /work/config/packages.list /work/scripts/customize-chroot.sh "$CHROOT/tmp/aprilos/"
cp -a /work/overlay "$CHROOT/tmp/aprilos/overlay"
mount_chroot
chroot "$CHROOT" /bin/bash /tmp/aprilos/customize-chroot.sh
umount_chroot
rm -rf "$CHROOT/tmp/aprilos"

echo "==> [3/5] เตรียม kernel/initrd"
cp "$(ls -1 "$CHROOT"/boot/vmlinuz-* | sort -V | tail -1)" "$ISO/casper/vmlinuz"
cp "$(ls -1 "$CHROOT"/boot/initrd.img-* | sort -V | tail -1)" "$ISO/casper/initrd"

echo "==> [4/5] สร้าง filesystem.squashfs"
mksquashfs "$CHROOT" "$ISO/casper/filesystem.squashfs" -comp xz -noappend -e boot
du -sx --block-size=1 "$CHROOT" | cut -f1 > "$ISO/casper/filesystem.size"
chroot "$CHROOT" dpkg-query -W --showformat='${Package} ${Version}\n' > "$ISO/casper/filesystem.manifest"
mkdir -p "$ISO/.disk"; echo "${OS_NAME} ${OS_VERSION} \"${OS_CODENAME}\" - ${ARCH}" > "$ISO/.disk/info"

cat > "$ISO/boot/grub/grub.cfg" <<GRUB
set timeout=5
set default=0
menuentry "Try ${OS_NAME} ${OS_VERSION}" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}
menuentry "Try ${OS_NAME} (safe graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset ---
    initrd /casper/initrd
}
GRUB

echo "==> [5/5] สร้าง ISO (BIOS + UEFI)"
grub-mkrescue -o "$OUT/$ISO_NAME" "$ISO" -- -volid "${OS_NAME^^}"
echo "ISO: out/$ISO_NAME"
