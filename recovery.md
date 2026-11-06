# Recovery — Lumia 730 (superman)

> Fonte da verdade: `os/docs/lumia730-build1.md` §E1/E7 e `os/docs/lumia730-research.md` §6.
> **Regra:** recovery testado (Gate 7) antes de distribuir qualquer imagem.

## 1. Pré-condição
- Backup completo do eMMC validado (`flash/backup.sh` → `backup/<timestamp>/` com `SHA256SUMS`).

## 2. Restaurar via edl (Linux)
```bash
edl --loader=flash/prog_emmc_firehose_8x26.mbn wl backup/<timestamp>/
```
Conferir sintaxe da versão do `edl` instalada; alternativa QFIL (Windows):
Load backup `rawprogram`+`patch` → Flash.

## 3. Restaurar via QFIL (Windows)
1. EDL 9008 (WPInternals → Reset to EDL; test points só como fallback).
2. QFIL → Load Programmer (`prog_emmc_firehose_8x26.mbn`) → Rawprogram do backup → Download.
3. Verificar boot no Windows Phone 8.1/10 — evidência em vídeo/foto (Gate 7).

## 4. Falhas conhecidas
- **Bootloop no Meridian** (soft brick): gravar o kernel antigo em `boot` via lk2nd/QFIL; OSTree faz rollback automático de deploy ruim (SDD §12).
- **Hard brick** (sbl1/tz/rpm corrompidos): EDL + restore do backup; sem JTAG no MSM8226 — por isso o backup é obrigatório.
- **UART**: 115200 8N1, 1.8 V **com level shifter** — pads a documentar em `docs/lumia730-uart.md` (fotos).
