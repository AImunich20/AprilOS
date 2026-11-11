# Migration scripts

สคริปต์ที่รันครั้งเดียวตอนอัปเดต ตั้งชื่อตามเวอร์ชัน เช่น `0.2.sh`
`aprilos-update` จะรันทุกไฟล์ที่เวอร์ชัน > เวอร์ชันเดิมของเครื่อง และ ≤ เวอร์ชันใหม่ เรียงจากน้อยไปมาก (รันเป็น root)

ตัวอย่าง `0.2.sh`:

```bash
#!/usr/bin/env bash
set -e
# ย้ายไฟล์ตั้งค่าเก่า, เปิด service ใหม่ ฯลฯ
systemctl enable --now some-new.service
```
