<div align="center">

# 🌸 AprilOS

**ระบบปฏิบัติการที่เบา สวย และพูดภาษาไทยได้ตั้งแต่บูตแรก**

สร้างบนฐาน Ubuntu LTS · เดสก์ท็อป XFCE · อัปเดตตัวเองผ่าน GitHub

![Base](https://img.shields.io/badge/base-Ubuntu%2024.04%20LTS-E95420?logo=ubuntu&logoColor=white)
![Desktop](https://img.shields.io/badge/desktop-XFCE-2284F2?logo=xfce&logoColor=white)
![Arch](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-6f42c1)
![Boot](https://img.shields.io/badge/boot-BIOS%20%2B%20UEFI-success)
![Release](https://img.shields.io/github/v/release/AImunich20/AprilOS?include_prereleases&color=ff69b4&label=release)

[ดาวน์โหลด](https://github.com/AImunich20/AprilOS/releases/latest) · [Build เอง](#️-build-เอง) · [ระบบอัปเดต](#-อัปเดตตัวเองผ่าน-github) · [Roadmap](#️-roadmap)

</div>

---

## ✨ ทำไมต้อง AprilOS

| | |
|---|---|
| 🪶 **เบาและเร็ว** | ใช้ XFCE เปิดเครื่องไว ใช้ RAM น้อย รันได้ดีแม้บนเครื่องเก่า |
| 🇹🇭 **ภาษาไทยพร้อมใช้** | ฟอนต์ไทย, ระบบพิมพ์ไทย (ibus-libthai), เขตเวลา Asia/Bangkok ตั้งไว้ให้แล้ว |
| 🔄 **อัปเดตตัวเอง** | ปล่อย Release บน GitHub ครั้งเดียว ทุกเครื่องอัปเดตตาม พร้อมตรวจ checksum |
| 🧱 **ฐานแข็งแรง** | Ubuntu LTS + แพตช์ความปลอดภัยจาก Ubuntu โดยตรง ใช้แพ็กเกจจาก `apt` ได้ทั้งหมด |
| 💿 **Live ISO** | ลองใช้ได้ทันทีจาก USB โดยไม่ต้องติดตั้ง บูตได้ทั้ง BIOS และ UEFI |
| 🛠️ **ปรับแต่งง่าย** | แก้ไฟล์ข้อความไม่กี่ไฟล์ก็ได้ OS เวอร์ชันของคุณเอง |

## 🚀 เริ่มต้นใช้งาน

1. ดาวน์โหลดไฟล์ `.iso` จากหน้า [Releases](https://github.com/AImunich20/AprilOS/releases/latest)
2. เขียนลง USB ด้วย [balenaEtcher](https://etcher.balena.io/) หรือเปิดใน VM (UTM, VirtualBox, VMware)
3. บูตแล้วเลือก **Try AprilOS** ระบบจะล็อกอินให้อัตโนมัติเป็นผู้ใช้ `april`

> หน้าจอเพี้ยนหรือจอดำ? เลือก **Try AprilOS (safe graphics)** ที่เมนูบูต

## 🏗️ Build เอง

ต้องมีแค่ **Docker** (Docker Desktop, OrbStack หรือ colima) ใช้ได้ทั้ง macOS และ Linux

```bash
git clone https://github.com/AImunich20/AprilOS.git
cd AprilOS
./build.sh
```

ได้ไฟล์ `out/AprilOS-<เวอร์ชัน>-amd64.iso`

```
debootstrap  ──►  ติดตั้งแพ็กเกจ + branding  ──►  squashfs  ──►  ISO (BIOS + UEFI)
  (Ubuntu)           (chroot)                    (casper)       (grub-mkrescue)
```

> 🍎 **Apple Silicon:** การ build `amd64` ต้องจำลอง CPU จึงใช้เวลาราว 30–90 นาที
> ถ้าต้องการทดสอบใน UTM บน Mac ให้เร็วขึ้น ให้ตั้งใน `config/aprilos.conf` เป็น
> `ARCH="arm64"` และ `UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports"`

## 🎨 ปรับแต่งให้เป็นของคุณ

| อยากเปลี่ยน | แก้ที่ |
|---|---|
| ชื่อ, เวอร์ชัน, โค้ดเนม, เขตเวลา, ภาษา | `config/aprilos.conf` |
| เพิ่มโปรแกรม | `config/packages.list` |
| ลบโปรแกรมออกจากเครื่องผู้ใช้ตอนอัปเดต | `config/packages-remove.list` |
| Wallpaper, ธีม, ไฟล์ตั้งค่า | วางไว้ใน `overlay/` ตาม path จริง เช่น `overlay/usr/share/backgrounds/` |
| เปลี่ยนเป็น GNOME | แทนส่วน XFCE ใน `packages.list` ด้วย `ubuntu-desktop-minimal` |
| คำสั่งพิเศษตอน build | `scripts/customize-chroot.sh` |

## 🔄 อัปเดตตัวเองผ่าน GitHub

ทุกเครื่องที่ติดตั้ง AprilOS จะคอยดู **GitHub Releases** ของ repo นี้ เมื่อมีเวอร์ชันใหม่จะแจ้งเตือนหรือติดตั้งให้เอง

```
 ผู้พัฒนา                         GitHub                         เครื่องผู้ใช้
──────────                   ─────────────                  ─────────────────
./release.sh 0.2  ──push──►  Release v0.2      ◄──check──   systemd timer (วันละครั้ง)
                             + SHA256SUMS                   🔔 แจ้งเตือนบนเดสก์ท็อป
                                               ──download─► sudo aprilos-update
```

### ปล่อยเวอร์ชันใหม่

```bash
./release.sh 0.2 "เพิ่มธีมใหม่ + แก้บั๊ก"      # stable
./release.sh 0.3 "ทดลองฟีเจอร์ใหม่" --beta     # prerelease
```

### บนเครื่องผู้ใช้

| คำสั่ง | ทำอะไร |
|---|---|
| `aprilos-update status` | ดูเวอร์ชันปัจจุบันและแหล่งอัปเดต |
| `aprilos-update check` | ตรวจว่ามีเวอร์ชันใหม่ไหม |
| `sudo aprilos-update` | ตรวจและติดตั้งอัปเดต |

<details>
<summary><b>ขั้นตอนที่เกิดขึ้นตอนอัปเดต</b></summary>

1. ดาวน์โหลด source ของแท็กล่าสุด แล้วตรวจกับ `SHA256SUMS` ที่แนบใน Release
2. `apt full-upgrade` เพื่อรับแพตช์ความปลอดภัยของ Ubuntu
3. ติดตั้งแพ็กเกจที่เพิ่มใหม่ และลบแพ็กเกจตาม `packages-remove.list`
4. คัดลอกไฟล์ใน `overlay/` ลงระบบ (ตัว updater ก็อัปเดตตัวเองตรงนี้)
5. รันสคริปต์ใน `updates/migrations/<เวอร์ชัน>.sh` ที่ยังไม่เคยรัน
6. อัปเดตเลขเวอร์ชันใน `/etc/os-release`

log ทั้งหมดอยู่ที่ `/var/log/aprilos-update.log`

</details>

<details>
<summary><b>ตั้งค่า updater</b> (<code>/etc/aprilos/update.conf</code>)</summary>

| ค่า | ความหมาย |
|---|---|
| `AUTO_APPLY="yes"` | ติดตั้งอัปเดตอัตโนมัติ (ค่าเริ่มต้น `no` = แจ้งเตือนอย่างเดียว) |
| `INCLUDE_PRERELEASE="yes"` | รับเวอร์ชัน beta ด้วย |

</details>

> ⚠️ **ความปลอดภัย:** ใครที่สร้าง Release ใน repo นี้ได้ ก็สั่งรันโค้ดด้วยสิทธิ์ root บนเครื่องผู้ใช้ได้ ควรเปิด 2FA และจำกัดคนที่เข้าถึง repo

## 📁 โครงสร้างโปรเจกต์

```
AprilOS/
├── build.sh                 🏗️  build ISO ผ่าน Docker
├── release.sh               🚀  ปล่อยเวอร์ชันใหม่ขึ้น GitHub Releases
├── builder/Dockerfile       🐳  สภาพแวดล้อมสำหรับ build
├── config/                  ⚙️  ค่าตั้งและรายการแพ็กเกจ
├── scripts/                 📜  ขั้นตอน build (debootstrap → chroot → ISO)
├── overlay/                 🎨  ไฟล์ที่คัดลอกลงระบบ รวมถึงตัว updater
└── updates/migrations/      🔧  สคริปต์ที่รันครั้งเดียวตอนอัปเดตไปเวอร์ชันนั้น
```

## 🗺️ Roadmap

- [x] Live ISO บูตได้ทั้ง BIOS + UEFI
- [x] Branding AprilOS + ภาษาไทยพร้อมใช้
- [x] ระบบอัปเดตตัวเองผ่าน GitHub Releases
- [ ] Wallpaper, ธีม, ไอคอน และหน้าจอตอนบูต (Plymouth) ของ AprilOS
- [ ] ตัวติดตั้งลงฮาร์ดดิสก์ (Calamares)
- [ ] เว็บเบราว์เซอร์ติดตั้งมาให้
- [ ] build ISO อัตโนมัติด้วย GitHub Actions

## 🤝 ร่วมพัฒนา

ยินดีรับทุก Issue และ Pull Request ไม่ว่าจะเป็นรายงานบั๊ก ไอเดียฟีเจอร์ หรือธีมสวยๆ 🌸

<div align="center">

สร้างด้วย 💖 บนฐาน [Ubuntu](https://ubuntu.com)
AprilOS ไม่ได้เกี่ยวข้องหรือได้รับการรับรองจาก Canonical Ltd.

</div>
