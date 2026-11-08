#!/bin/sh
# =====================================================================
# Meridian OS — Instalador ON-DEVICE — Lumia 730 (superman)
# Roda NO APARELHO, a partir do initramfs Meridian (após lk2nd bootar o kernel).
# Papel (docs/lumia730-build1.md §E5–E6): sanity de HW, preparo do rootfs na
# partição Data, boot entry no EFIESP, rede USB p/ SSH, e handoff p/ shell.
# Idempotente: pode rodar quantas vezes precisar. Sem nada destrutivo: NÃO
# reformata partições aqui — o rootfs.ext4 vem pronto do build (host/KAS).
# =====================================================================
set -eu
MARKER=/tmp/meridian-firstboot

log() { echo "[firstboot] $*"; }
fail() { echo "[firstboot][ERRO] $*" >&2; exit 1; }

[ -e /dev/console ] || fail "sem console — rode pelo initramfs com console=ttyS0"

log "montando pseudo-fs"
mkdir -p /proc /sys /dev /run
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true

log "sanity de hardware (Gate 4 — evidência no UART)"
dmesg | grep -iE 'mdss|dsi|qcom' | head -5 || log "sem dmesg mdss (kernel antigo?)"
ls /dev/fb0 >/dev/null 2>&1 && log "fbdev OK: /dev/fb0" || log "fbdev AUSENTE (painel E4 pendente)"
ls /dev/input/event* >/dev/null 2>&1 && log "input OK: $(ls /dev/input/event* | tr '\n' ' ')" || log "touch AUSENTE (i2c1 — E4)"

log "localizando partições (GPT do Lumia: EFIESP, MainOS, Data)"
DATA=""
for CAND in /dev/mmcblk0p27 /dev/mmcblk0p26; do
  [ -b "$CAND" ] && DATA="$CAND" && break
done
[ -n "$DATA" ] || fail "partição Data não encontrada (mmcblk0p26/27) — verifique o GPT"
log "Data = $DATA"

log "montando rootfs (ext4 pronto do build) em /rootfs"
mkdir -p /rootfs
mount -t ext4 "$DATA" /rootfs 2>/dev/null || fail "Data não é ext4 montável — escreva o rootfs.img no host (write-rootfs)"

if [ -x /rootfs/usr/bin/systemctl ]; then
  log "rootfs Meridian presente — OSTree/OSTree deploy é papel do meridian-ota (ADR-012)"
  log "handoff: switch_root para /rootfs"
  mount --move /dev  /rootfs/dev 2>/dev/null || true
  mount --move /proc /rootfs/proc 2>/dev/null || true
  mount --move /sys  /rootfs/sys  2>/dev/null || true
  exec switch_root /rootfs /sbin/init
fi

log "rootfs vazio — modo manutenção: console + rede USB (ECM) para SSH do host"
# USB gadget CDC/ECM (dwc3 configfs) — rede de desenvolvimento
if [ -d /sys/class/udm ]; then :; fi
mkdir -p /sys/kernel/config/usb_gadget/g1 2>/dev/null || true
if [ -w /sys/kernel/config/usb_gadget/g1/idVendor ]; then
  echo 0x1d6b > /sys/kernel/config/usb_gadget/g1/idVendor
  echo 0x0104 > /sys/kernel/config/usb_gadget/g1/idProduct
  mkdir -p /sys/kernel/config/usb_gadget/g1/functions/ecm.usb0
  mkdir -p /sys/kernel/config/usb_gadget/g1/configs/c.1
  ln -sf /sys/kernel/config/usb_gadget/g1/functions/ecm.usb0 /sys/kernel/config/usb_gadget/g1/configs/c.1/ 2>/dev/null || true
  UDC=$(ls /sys/class/udc | head -1) && echo "$UDC" > /sys/kernel/config/usb_gadget/g1/UDC || true
  ifconfig usb0 10.15.0.1 netmask 255.255.255.0 up 2>/dev/null || true
  log "rede USB: 10.15.0.1 (host: 10.15.0.2) — ssh meridian@10.15.0.1 quando sshd existir"
fi
touch "$MARKER"
log "pronto — console interativo abaixo (Power: botão; recovery: docs/lumia730-build1.md §E7)"
exec setsid sh -c 'exec sh </dev/console >/dev/console 2>&1'
