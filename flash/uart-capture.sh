#!/usr/bin/env bash
# Captura do console serial (UART) do Lumia 730 — 115200 8N1, 1.8 V (LEVEL SHIFTER OBRIGATÓRIO)
# Pads: a documentar com fotos em docs/lumia730-uart.md (perto do conector da bateria/SIM)
set -euo pipefail
DEV="${1:-/dev/ttyUSB0}"
OUT="$(dirname "$0")/uart-$(date +%Y%m%d-%H%M%S).log"
echo "[uart] capturando $DEV → $OUT (Ctrl-C para parar)"
command -v picocom >/dev/null && exec picocom -b 115200 "$DEV" | tee "$OUT"
command -v minicom  >/dev/null && exec minicom -D "$DEV" -b 115200 -C "$OUT"
echo "instale picocom ou minicom" >&2; exit 1
