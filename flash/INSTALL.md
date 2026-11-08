# Install — Nokia Lumia 730 (superman) — Meridian OS

> **Regras invariáveis**: (1) NENHUM write no eMMC antes de backup completo validado (Gates 1–2);
> (2) nenhuma operação destrutiva sem aprovação humana por escrito; (3) nenhum blob de firmware
> commitado no repo (manifest only).

## Cadeia de scripts

| Script | Onde roda | Papel |
|---|---|---|
| `install-lumia730.sh` | host Linux | orquestrador: preflight → backup → verify → unlock → efiesp-stage → write-* |
| `uart-capture.sh` | host Linux | console serial 115200 8N1 (**1,8 V — level shifter obrigatório**) |
| `firstboot-installer.sh` | **no aparelho** (initramfs, pós-lk2nd) | sanity de HW, monta rootfs na partição Data, rede USB (ECM 10.15.0.1), handoff p/ shell |

## Fluxo (execute em ordem, cada estágio gera evidência)

```bash
./install-lumia730.sh preflight        # deps, EDL 05c6:9008, FFU extraído, firehose, mtools
./install-lumia730.sh backup           # dump completo — edl+firehose OU guia WPInternals
./install-lumia730.sh backup-verify    # valida SHA-256/GPT           [Gates 1–2]
./install-lumia730.sh unlock-check     # guia WPInternals (Windows, MANUAL)
./install-lumia730.sh efiesp-stage     # BootShim/lk2nd/zImage+DTB/initramfs → EFIESP via mtools (sem root)
./install-lumia730.sh write-efiesp --confirm-escrito   # [GATE] grava EFIESP
./install-lumia730.sh write-rootfs --confirm-escrito   # [GATE] rootfs → partição Data
./install-lumia730.sh boot-fastboot    # TESTE de boot via lk2nd (fastboot boot — não grava)
./install-lumia730.sh flash-fastboot efiesp --confirm-escrito   # flash EFIESP via fastboot (Linux)
./install-lumia730.sh flash-fastboot rootfs --confirm-escrito   # rootfs → Data via fastboot (Linux)
./install-lumia730.sh uart             # primeiro boot — capture o console
# no aparelho: /firstboot-installer.sh  (sanity Gate 4: fbdev/input; rede USB; handoff)
```

## O que é manual (honesto)

> **Divisão Linux/Windows**: preparação 100% Linux (FFU, EFIESP via mtools, kernel, rootfs,
> fastboot via lk2nd). **Único passo Windows: o UNLOCK no WPInternals** (fechado; sem
> implementação Linux do FlashApp — port futuro, ver BACKLOG). Depois do unlock, o lk2nd
> expõe fastboot e **todo o resto roda no Linux**.

| Etapa | Por quê |
|---|---|
| Unlock bootloader | **WPInternals** (Windows, GUI, fechado) — github.com/ReneLergner/WPinternals |
| Boot menu no EFIESP | guias postmarketOS wiki → Windows Phone (BCD/entradas de boot) |
| Firehose msm8226 | **não vem no FFU** — se obtido à parte, habilita a rota `edl` (export `EDL_FIREHOSE=...`) |
| UART pads | localizar + fotografar (`docs/lumia730-uart.md`), 1,8 V com level shifter |

## Payloads esperados em `flash/` (para o efiesp-stage)

`boot-shim.efi` (imbushuo/boot-shim @ elf-loader-pre3) · `lk2nd.img` (Mainline4Lumia) ·
`zImage` + `superman.dtb` (kernel 6.6.y + patches msm8226, build KAS) · `initramfs.cpio.gz`.

## Recovery

`recovery.md` — restore via WPInternals/QFIL a partir do backup validado. **Testar antes de
distribuir qualquer imagem** (Gate 7).
