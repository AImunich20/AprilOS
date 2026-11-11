#!/usr/bin/env bash
# ทดสอบ AprilOS ใน QEMU (macOS / Linux) — ต้องติดตั้ง qemu ก่อน (brew install qemu)
#
#   scripts/test-vm.sh live    [arch]   บูต Live ISO แล้วถ่ายภาพหน้าจอเดสก์ท็อป
#   scripts/test-vm.sh install [arch]   ติดตั้งลงดิสก์เสมือนแบบอัตโนมัติ (ทดสอบ aprilos-install)
#   scripts/test-vm.sh boot    [arch]   บูตจากดิสก์ที่ติดตั้งแล้ว ล็อกอิน แล้วถ่ายภาพหน้าจอ
#
# arch เริ่มต้น = สถาปัตยกรรมของเครื่องนี้ (Apple Silicon → arm64 เร็วที่สุดเพราะใช้ HVF)
# ภาพหน้าจอเก็บที่ out/vm/*.png
set -euo pipefail
cd "$(dirname "$0")/.."
source config/aprilos.conf
MODE=${1:-live}
HOST_ARCH=$(uname -m); [ "$HOST_ARCH" = x86_64 ] && HOST_ARCH=amd64; [ "$HOST_ARCH" = aarch64 ] && HOST_ARCH=arm64
A=${2:-$HOST_ARCH}
ISO="out/${OS_NAME}-${OS_VERSION}-${A}.iso"
VM=out/vm; mkdir -p "$VM"
DISK="$VM/disk-${A}.qcow2"
MON="$VM/mon-${A}.sock"
SHARE=$(dirname "$(dirname "$(command -v qemu-img)")")/share/qemu

[ -f "$ISO" ] || { echo "ไม่พบ $ISO"; exit 1; }

if [ "$A" = arm64 ]; then
    QEMU=qemu-system-aarch64
    ACCEL=tcg; CPU=max
    [ "$(uname -s)-$HOST_ARCH" = Darwin-arm64 ] && { ACCEL=hvf; CPU=host; }
    [ ! -f "$VM/vars-arm64.fd" ] && cp "$SHARE/edk2-arm-vars.fd" "$VM/vars-arm64.fd"
    BASE=(-machine virt -accel "$ACCEL" -cpu "$CPU"
          -drive "if=pflash,format=raw,readonly=on,file=$SHARE/edk2-aarch64-code.fd"
          -drive "if=pflash,format=raw,file=$VM/vars-arm64.fd"
          -device virtio-gpu-pci,xres=1600,yres=900)
    CONSOLE=ttyAMA0
else
    QEMU=qemu-system-x86_64
    ACCEL=tcg; [ "$(uname -s)-$HOST_ARCH" = Linux-amd64 ] && [ -w /dev/kvm ] && ACCEL=kvm
    [ ! -f "$VM/vars-amd64.fd" ] && cp "$SHARE/edk2-i386-vars.fd" "$VM/vars-amd64.fd"
    BASE=(-machine q35 -accel "$ACCEL" -cpu max
          -drive "if=pflash,format=raw,readonly=on,file=$SHARE/edk2-x86_64-code.fd"
          -drive "if=pflash,format=raw,file=$VM/vars-amd64.fd"
          -device virtio-vga,xres=1600,yres=900)
    CONSOLE=ttyS0
fi
BASE+=(-smp 4 -m 4096 -device qemu-xhci -device usb-kbd -device usb-tablet
       -nic user,model=virtio-net-pci -display none
       -monitor "unix:$MON,server,nowait" -serial "file:$VM/serial-${A}-${MODE}.log")
CDROM=(-device virtio-scsi-pci -drive "file=$ISO,media=cdrom,if=none,id=cd,readonly=on" -device scsi-cd,drive=cd)

mon()  { echo "$1" | nc -U "$MON" >/dev/null 2>&1 || true; }
shot() { mon "screendump $PWD/$VM/$1.png -f png"; sleep 2; echo "ภาพหน้าจอ: $VM/$1.png"; }
type_text() { local s=$1 c; for ((i=0; i<${#s}; i++)); do c=${s:i:1}; mon "sendkey $c"; sleep 0.15; done; }
stop() { mon quit; sleep 2; }

case "$MODE" in
live)
    rm -f "$MON"
    $QEMU "${BASE[@]}" "${CDROM[@]}" & pid=$!
    echo "บูต Live ISO ($A, accel=$ACCEL) ..."; sleep ${WAIT:-100}
    shot "live-${A}"; stop; wait $pid 2>/dev/null || true ;;
install)
    rm -f "$DISK" "$MON"; qemu-img create -q -f qcow2 "$DISK" 25G
    tmp=$(mktemp -d); bsdtar -xf "$ISO" -C "$tmp" casper/vmlinuz casper/initrd
    echo "ติดตั้งอัตโนมัติลงดิสก์เสมือน ($A) ... (ดู log: $VM/serial-${A}-install.log)"
    $QEMU "${BASE[@]}" "${CDROM[@]}" -drive "file=$DISK,if=virtio,format=qcow2" \
        -kernel "$tmp/casper/vmlinuz" -initrd "$tmp/casper/initrd" \
        -append "boot=casper aprilos.autoinstall=/dev/vda console=tty0 console=$CONSOLE ---" & pid=$!
    for _ in $(seq 1 ${INSTALL_TIMEOUT:-360}); do kill -0 $pid 2>/dev/null || break; sleep 5; done
    kill -0 $pid 2>/dev/null && { shot "install-timeout-${A}"; stop; }
    wait $pid 2>/dev/null || true
    rm -rf "$tmp"
    grep -q "ติดตั้ง AprilOS ลง" "$VM/serial-${A}-install.log" && echo "ติดตั้งสำเร็จ" || { echo "ติดตั้งไม่สำเร็จ"; exit 1; } ;;
boot)
    rm -f "$MON"
    $QEMU "${BASE[@]}" -drive "file=$DISK,if=virtio,format=qcow2" & pid=$!
    echo "บูตจากดิสก์ที่ติดตั้งแล้ว ($A) ..."; sleep ${WAIT:-60}
    shot "login-${A}"
    type_text april; mon "sendkey ret"; sleep 25
    shot "desktop-${A}"; stop; wait $pid 2>/dev/null || true ;;
*) sed -n '2,9p' "$0"; exit 2 ;;
esac
