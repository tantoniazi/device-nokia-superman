#!/usr/bin/env bash
# BACKUP COMPLETO DO eMMC — OBRIGATÓRIO antes de QUALQUER escrita (Gates 1–2)
# SDD §14 / build1 §E1 · Nenhum passo depois deste roda sem este backup validado.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
FIREHOSE="$DIR/prog_emmc_firehose_8x26.mbn"   # extraído do FFU — NUNCA commitado
[ -f "$FIREHOSE" ] || { echo "ERRO: copie o firehose do FFU para $FIREHOSE (ver ../firmware/firmware-manifest.yaml)"; exit 1; }
OUT="$DIR/../backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
# bkerler/edl (pip install edl) — conferir a sintaxe da versão instalada:
#   novo: edl --loader=LOADER.mbn rl <dir>   ·  legado: edl /l LOADER.mbn && edl rl <dir>
echo "== Backup completo do eMMC → $OUT"
edl --loader="$FIREHOSE" printgpt | tee "$OUT/gpt.txt"
edl --loader="$FIREHOSE" rl "$OUT"
(cd "$OUT" && sha256sum * > SHA256SUMS)
echo "== OK: backup em $OUT"
echo "PRÓXIMO PASSO OBRIGATÓRIO: validar restore de 1 partição de teste e confirmar"
echo "o boot do Windows Phone (E1) antes de qualquer flash (build1 §E1 / Gate 2)."
