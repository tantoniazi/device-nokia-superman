#!/usr/bin/env bash
# BACKUP COMPLETO DO eMMC — OBRIGATÓRIO antes de QUALQUER escrita (Gates 1–2)
# SDD §14 / build1 §E1 · Nenhum passo depois deste roda sem este backup validado.
# ⚠ CORREÇÃO 2026-11-06: o FFU oficial NÃO contém firehose/programmer.
#   ROTA PRIMÁRIA: WPInternals (Windows) → dump completo do eMMC (protocolo
#   FlashApp do UEFI do aparelho). Este script é a rota ALTERNATIVA, só usável
#   se um programmer msm8226 for obtido separadamente.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
FIREHOSE="${1:-}"
if [ -z "$FIREHOSE" ] || [ ! -f "$FIREHOSE" ]; then
  cat <<'AVISO'
ERRO: sem firehose/programmer.
  → Use a rota primária: WPInternals (Windows) → backup completo do eMMC.
  → Ou obtenha um programmer msm8226 (pesquisa pendente) e rode:
      ./backup.sh /caminho/prog_emmc_firehose_8x26.mbn
AVISO
  exit 1
fi
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
