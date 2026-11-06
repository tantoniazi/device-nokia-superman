#!/bin/sh
# hwinit — bring-up de hardware do Lumia 730 (superman) [padrão phase1/<device>/hwinit.sh do monorepo]
# Plano: os/docs/lumia730-build1.md · TODOs conforme subsistemas sobem (E3→E5)
set -eu

DEVICE=superman
echo "[hwinit:$DEVICE] start"

# 1) zram — 1 GB de RAM é apertado p/ shell QML (SDD §14.4)
# TODO(E5): swapon /dev/zram0 com algoritmo zstd + cgroups do shell

# 2) USB gadget CDC/ECM — rede de desenvolvimento (SSH) sem Wi-Fi
# TODO(E5): configfs dwc3 → gadget ECM + systemd-networkd

# 3) Reguladores PM8226 mínimos (display/touch)
# TODO(E4): garantir ldo/smps necessários ao painel e ao controlador de touch

# 4) Áudio (PipeWire +SimpleCard WCD) — TODO(B1.5)
# 5) Modem (QRTR + NON-HLOS via firmware_class) — TODO(B1.5)
# 6) Wi-Fi wcn36xx + BT uart — TODO(B1.5)

echo "[hwinit:$DEVICE] done (skeleton — nada crítico ainda)"
