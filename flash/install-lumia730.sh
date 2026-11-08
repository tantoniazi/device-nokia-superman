#!/usr/bin/env bash
# =====================================================================
# Meridian OS — Orquestrador de instalação (HOST Linux) — Lumia 730 (superman)
# SDD: meridian-os/SDD-MERIDIAN-MOBILE.md §14 · plano: docs/lumia730-build1.md
#
# REGRA INVIOLÁVEL (AGENTS.md do projeto): NENHUM write no eMMC antes de
# backup completo VALIDADO (Gates 1–2). Nenhuma operação destrutiva sem
# aprovação humana POR ESCRITO (--confirm-escrito).
#
# Uso (estágios, na ordem — cada um gera evidência):
#   ./install-lumia730.sh preflight        # deps, EDL 05c6:9008, arquivos, mtools
#   ./install-lumia730.sh backup           # dump completo + SHA-256      [Gate 1]
#   ./install-lumia730.sh backup-verify    # valida dump (sha256)          [Gate 2]
#   ./install-lumia730.sh unlock-check     # guia WPInternals (Windows, manual — ÚNICO passo não-Linux)
#   ./install-lumia730.sh efiesp-stage     # BootShim/lk2nd/kernel+DTB → EFIESP (mtools, sem root)
#   ./install-lumia730.sh write-efiesp     # grava EFIESP modificado [requer backup ok]
#   ./install-lumia730.sh write-rootfs     # rootfs → partição Data   [requer backup ok]
#   ./install-lumia730.sh boot-fastboot    # TESTE de boot via lk2nd (fastboot boot — NÃO grava nada)
#   ./install-lumia730.sh flash-fastboot   # flashes persistentes via fastboot do lk2nd (Linux)
#   ./install-lumia730.sh status           # estado (sem writes)
#
# ROTAS DE ESCRITA (pós-unlock, tudo no Linux):
#   PRINCIPAL: fastboot do lk2nd (fastboot boot/flash) — aparelho no boot menu do EFIESP
#   (A) edl + firehose msm8226 — NÃO vem no FFU; obtenha à parte (export EDL_FIREHOSE=...)
#   (B) WPInternals (Windows) — só para o UNLOCK inicial; resto fica no Linux.
# Na dúvida: pare e releia docs/lumia730-build1.md §E1–E7.
# =====================================================================
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
STATE="$DIR/.state"
BACKUP_DIR="$DIR/backup"
FFU_DIR="${FFU_DIR:-$DIR/../../Nokia_Lumia_730_Dual_SIM_RM-1040/ffu-out}"
EDL_FIREHOSE="${EDL_FIREHOSE:-}"   # export EDL_FIREHOSE=/caminho/prog_emmc_firehose_8x26.mbn
USBID="05c6:9008"

mkdir -p "$BACKUP_DIR"
touch "$STATE"

say()  { printf '\e[1;36m[meridian]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[aviso]\e[0m %s\n' "$*"; }
die()  { printf '\e[1;31m[ERRO]\e[0m %s\n' "$*" >&2; exit 1; }

have()      { command -v "$1" >/dev/null 2>&1; }
backup_ok() { grep -q '^backup-verified=yes' "$STATE"; }

edl_ready() {
  have edl || return 1
  lsusb 2>/dev/null | grep -qi "$USBID" || return 1
  [ -n "$EDL_FIREHOSE" ] && [ -f "$EDL_FIREHOSE" ] || return 1
  return 0
}

require_backup_gate() {
  backup_ok || die "Gate 1–2 não cumprido: rode 'backup' + 'backup-verify' ANTES de qualquer write."
  [ "${1:-}" = "--confirm-escrito" ] || die "Operação destrutiva: adicione --confirm-escrito (aprovação humana por escrito)."
}

cmd_status() {
  say "estado: $(cat "$STATE" | tr '\n' ' ')"
  if edl_ready; then say "rota A (edl+firehose): PRONTA (aparelho em EDL, programmer: $EDL_FIREHOSE)"
  else warn "rota A indisponível (edl/aparelho/firehose) — unlock e flash de boot: WPInternals (Windows)"; fi
  ls "$BACKUP_DIR" 2>/dev/null | tail -3 || true
}

cmd_preflight() {
  say "pré-requisitos:"
  for t in sha256sum cpio gzip; do have "$t" || die "falta $t"; done
  have mcopy && say "mtools OK (edição de EFIESP sem root)" || warn "mtools ausente (mcopy/mdir) — necessário para efiesp-stage"
  have fastboot && say "fastboot OK (rota Linux pós-unlock, via lk2nd)" || warn "fastboot ausente (pacote android-tools) — rota pós-unlock"
  [ -r "$FFU_DIR/RM1040.img" ] && say "FFU extraído OK: $FFU_DIR/RM1040.img (restauração de emergência)" || warn "FFU não extraído em $FFU_DIR — rode o parser (tools/ffu-extract-lumia.py) para ter restore"
  [ -n "$EDL_FIREHOSE" ] && [ -f "$EDL_FIREHOSE" ] && say "firehose OK: $EDL_FIREHOSE" || warn "sem firehose (export EDL_FIREHOSE=...): writes via edl ficam bloqueados; use WPInternals"
  lsusb 2>/dev/null | grep -qi "$USBID" && say "aparelho em EDL ($USBID)" || warn "aparelho NÃO está em EDL — WPInternals → Reset to EDL"
  say "próximo: backup (Gate 1) — NADA de write antes dele."
}

cmd_backup() {
  if edl_ready; then
    OUT="$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$OUT"
    say "dump completo via edl → $OUT"
    edl --loader="$EDL_FIREHOSE" printgpt | tee "$OUT/gpt.txt"
    edl --loader="$EDL_FIREHOSE" rl "$OUT"
    (cd "$OUT" && sha256sum * > SHA256SUMS) && echo "backup-verified=pending" >> "$STATE"
    say "Gate 1 OK → rode backup-verify"
  else
    cat <<'GUIA'
ROTA B — backup via WPInternals (Windows, manual):
  1. Instale WPInternals (github.com/ReneLergner/WPinternals) + Windows Device Recovery Tool
  2. Aparelho em modo flash (WPInternals detecta; EDL 9008 quando pedido)
  3. Faça o DUMP COMPLETO do eMMC (todas as partições) — arquivo único ou por partição
  4. Copie o dump para flash/backup/ e rode: ./install-lumia730.sh backup-verify <dump>
  Motivo: o FFU oficial NÃO contém firehose; WPInternals fala o FlashApp do próprio UEFI.
GUIA
    warn "backup-verify exigirá o dump em $BACKUP_DIR"
  fi
}

cmd_backup_verify() {
  D="${1:-$(ls -td "$BACKUP_DIR"/*/ 2>/dev/null | head -1)}"; [ -n "${D:-}" ] || die "nenhum backup encontrado"
  F="${1:-}"
  if [ -n "$F" ] && [ -f "$F" ]; then
    say "dump único: $F ($(du -h "$F" | cut -f1)) — valida magic GPT:"
    head -c 512 "$F" | grep -aq 'EFI PART' && echo "backup-verified=yes $(date +%s)" >> "$STATE" || die "dump sem assinatura GPT — não confia nele"
  else
    (cd "$D" && sha256sum -c SHA256SUMS --quiet) && echo "backup-verified=yes $(date +%s)" >> "$STATE" || die "sha256 divergiu — backup corrompido"
  fi
  say "Gate 2 OK — backup VALIDADO. Writes liberados COM --confirm-escrito."
}

cmd_unlock_check() {
  cat <<'GUIA'
Unlock — WPInternals (MANUAL, Windows; ferramenta fechada de terceiros):
  1. WPInternals → Emergency/Normal flash → Unlock Bootloader
  2. Se pedir 'Security enablement', siga o assistente
  3. Confirme: boot menu acessível no EFIESP (guias: wiki.postmarketos.org/wiki/Windows_Phone)
Evidência para o Gate do projeto: foto do menu + log do UART.
GUIA
  grep -q '^unlock-confirmed' "$STATE" || true
}

cmd_efiesp_stage() {
  have mcopy || die "mtools necessário (mcopy/mdir) — instala mtools (sem sudo não dá apt; peça ao dono ou use CI)"
  [ -r "$FFU_DIR/parts/EFIESP.img" ] || die "EFIESP de referência ausente — extraia do FFU (tools/ffu-extract-lumia.py)"
  WORK="$DIR/work"; mkdir -p "$WORK"
  cp "$FFU_DIR/parts/EFIESP.img" "$WORK/EFIESP-new.img"
  say "estageando payloads em $WORK (lidos de work/ ou flash/):"
  for f in boot-shim.efi lk2nd.img zImage superman.dtb initramfs.cpio.gz; do
    [ -f "$DIR/$f" ] || warn "faltando $f — obtenha (Mainline4Lumia/boot-shim; kernel do build Meridian)"
  done
  for f in boot-shim.efi lk2nd.img zImage superman.dtb initramfs.cpio.gz; do
    [ -f "$DIR/$f" ] && mcopy -n -i "$WORK/EFIESP-new.img" -s "$DIR/$f" ::/meridian/ || true
  done
  mdir -/ -i "$WORK/EFIESP-new.img" ::/meridian 2>/dev/null || true
  say "EFIESP-new.img pronto — revise com mdir. Write só via 'write-efiesp' (gate)."
}

cmd_write_efiesp() {
  require_backup_gate "${1:-}"
  [ -f "$DIR/work/EFIESP-new.img" ] || die "rode efiesp-stage antes"
  edl_ready || die "rota A (edl+firehose) indisponível — gravação manual via WPInternals 'Custom flash' (partição EFIESP, setores 184320..249855)"
  say "gravação EFIESP via edl — PARTIÇÃO EFIESP APENAS"
  edl --loader="$EDL_FIREHOSE" w EFIESP "$DIR/work/EFIESP-new.img"
  say "OK — boot pelo menu do EFIESP e capture o UART (./install-lumia730.sh uart)"
}

cmd_write_rootfs() {
  require_backup_gate "${1:-}"
  IMG="${2:-$DIR/work/rootfs.img}"; [ -f "$IMG" ] || die "rootfs.img ausente (build KAS: meridian-os build/meridian-superman.yml)"
  edl_ready || die "rota A indisponível — rootfs via WPInternals custom flash (partição Data)"
  say "gravação do rootfs → partição Data (apaga Data; backup é o Gate)"
  edl --loader="$EDL_FIREHOSE" w Data "$IMG"
  say "OK — primeiro boot: ./firstboot-installer.sh roda NO APARELHO (initramfs)"
}

cmd_uart() { exec "$DIR/uart-capture.sh"; }

# ---------- rota LINUX principal pós-unlock: fastboot do lk2nd ----------
fb_ready() { have fastboot && fastboot devices 2>/dev/null | grep -q .; }

cmd_boot_fastboot() {
  # boot de teste SEM gravar nada — lk2nd injeta o DTB do aparelho
  fb_ready || die "fastboot do lk2nd não detectado — aparelho no boot menu (EFIESP) → lk2nd + cabo USB; e 'fastboot devices'"
  for f in zImage initramfs.cpio.gz; do [ -f "$DIR/$f" ] || die "faltando $DIR/$f (build do kernel/meridian-superman)"; done
  say "boot de teste via lk2nd (não grava): zImage + initramfs — UART obrigatório"
  fastboot boot "$DIR/zImage" "$DIR/initramfs.cpio.gz"
  say "se o UART mostrar o init do firstboot-installer: Gate 3 ✅"
}

cmd_flash_fastboot() {
  require_backup_gate "${2:-}"
  WHAT="${1:-}"; shift 2 2>/dev/null || true
  fb_ready || die "fastboot do lk2nd não detectado"
  case "$WHAT" in
    efiesp)
      [ -f "$DIR/work/EFIESP-new.img" ] || die "rode efiesp-stage antes"
      say "flash EFIESP via fastboot (persistente)"
      fastboot flash EFIESP "$DIR/work/EFIESP-new.img" ;;
    rootfs)
      IMG="${1:-$DIR/work/rootfs.img}"; [ -f "$IMG" ] || die "rootfs.img ausente (KAS)"
      say "flash rootfs → partição Data via fastboot"
      fastboot flash Data "$IMG" ;;
    *) die "uso: flash-fastboot efiesp|rootfs --confirm-escrito" ;;
  esac
  say "OK — valide no UART (./install-lumia730.sh uart)"
}

case "${1:-status}" in
  preflight)      cmd_preflight ;;
  backup)         cmd_backup ;;
  backup-verify)  cmd_backup_verify "${2:-}" ;;
  unlock-check)   cmd_unlock_check ;;
  efiesp-stage)   cmd_efiesp_stage ;;
  write-efiesp)   cmd_write_efiesp "${2:-}" ;;
  write-rootfs)   cmd_write_rootfs "${1:-}" "${2:-}" ;;
  uart)           cmd_uart ;;
  boot-fastboot)  cmd_boot_fastboot ;;
  flash-fastboot) cmd_flash_fastboot "${2:-}" "${3:-}" "${4:-}" ;;
  status|*)       cmd_status ;;
esac
