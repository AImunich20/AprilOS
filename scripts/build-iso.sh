#!/usr/bin/env bash
# รันภายใน builder container เท่านั้น (เรียกผ่าน ./build.sh)
set -euo pipefail
source /work/config/aprilos.conf

WORK=/build            # docker volume (เร็วกว่าและไม่เพี้ยนเรื่อง permission เหมือนโฟลเดอร์ที่ mount จาก macOS)
CACHE=/cache           # docker volume เก็บแพ็กเกจที่ดาวน์โหลดแล้ว → build ครั้งถัดไปเร็วขึ้นมาก
CHROOT=$WORK/chroot
ISO=$WORK/iso
OUT=/work/out
ISO_NAME="${OS_NAME}-${OS_VERSION}-${ARCH}.iso"
SQUASH_COMP="${SQUASH_COMP:-zstd}"   # zstd = เร็ว, xz = ไฟล์เล็กกว่าแต่ช้ากว่ามาก

mount_chroot() {
    for d in dev dev/pts proc sys run; do mount --bind "/$d" "$CHROOT/$d"; done
    mkdir -p "$CACHE/apt" "$CHROOT/var/cache/apt/archives"
    mount --bind "$CACHE/apt" "$CHROOT/var/cache/apt/archives"
}
umount_chroot() {
    for d in var/cache/apt/archives run sys proc dev/pts dev; do umount -lf "$CHROOT/$d" 2>/dev/null || true; done
}
trap umount_chroot EXIT

umount_chroot; rm -rf "$WORK"/*; mkdir -p "$CHROOT" "$ISO/casper" "$ISO/boot/grub" "$OUT" "$CACHE/debootstrap"

echo "==> [1/5] debootstrap ${UBUNTU_CODENAME} (${ARCH})"
debootstrap --arch="$ARCH" --variant=minbase --cache-dir="$CACHE/debootstrap" \
    "$UBUNTU_CODENAME" "$CHROOT" "$UBUNTU_MIRROR"

echo "==> [2/5] ปรับแต่งระบบใน chroot"
mkdir -p "$CHROOT/tmp/aprilos"
cp /work/config/aprilos.conf /work/config/packages.list /work/scripts/customize-chroot.sh "$CHROOT/tmp/aprilos/"
cp -a /work/overlay "$CHROOT/tmp/aprilos/overlay"
mount_chroot
chroot "$CHROOT" /usr/bin/env ARCH="$ARCH" /bin/bash /tmp/aprilos/customize-chroot.sh
umount_chroot
rm -rf "$CHROOT/tmp/aprilos" "$CHROOT"/var/cache/apt/archives/*.deb

echo "==> [3/5] เตรียม kernel/initrd"
cp "$(ls -1 "$CHROOT"/boot/vmlinuz-* | sort -V | tail -1)" "$ISO/casper/vmlinuz"
cp "$(ls -1 "$CHROOT"/boot/initrd.img-* | sort -V | tail -1)" "$ISO/casper/initrd"

echo "==> [4/5] สร้าง filesystem.squashfs (${SQUASH_COMP}, $(nproc) cores)"
COMP_OPTS=(-comp "$SQUASH_COMP"); [ "$SQUASH_COMP" = zstd ] && COMP_OPTS+=(-Xcompression-level 15)
mksquashfs "$CHROOT" "$ISO/casper/filesystem.squashfs" "${COMP_OPTS[@]}" -noappend -processors "$(nproc)"
du -sx --block-size=1 "$CHROOT" | cut -f1 > "$ISO/casper/filesystem.size"
chroot "$CHROOT" dpkg-query -W --showformat='${Package} ${Version}\n' > "$ISO/casper/filesystem.manifest"
mkdir -p "$ISO/.disk"; echo "${OS_NAME} ${OS_VERSION} \"${OS_CODENAME}\" - ${ARCH}" > "$ISO/.disk/info"

cat > "$ISO/boot/grub/grub.cfg" <<GRUB
set timeout=5
set default=0
menuentry "Try or Install ${OS_NAME} ${OS_VERSION}" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}
menuentry "Try or Install ${OS_NAME} (safe graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset ---
    initrd /casper/initrd
}
GRUB

echo "==> [5/5] สร้าง ISO"
grub-mkrescue -o "$OUT/$ISO_NAME" "$ISO" -- -volid "${OS_NAME^^}"
echo "ISO: out/$ISO_NAME ($(du -h "$OUT/$ISO_NAME" | cut -f1))"
