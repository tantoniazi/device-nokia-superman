# device-nokia-superman — Meridian OS · Nokia Lumia 730

**Device package** do **Meridian Mobile OS** para o **Nokia Lumia 730** (RM-1017/1018, codename `superman`, Qualcomm MSM8226).

> ⚠️ **Status: EXPERIMENTAL** — Build 1 (Boot + Shell Alpha) em andamento.
> ⚠️ **Nenhum flash antes do backup completo do eMMC** (`flash/backup.sh`) — sem JTAG neste SoC.
> ⚠️ **Nenhum flash destrutivo sem aprovação humana por escrito** (regra do projeto).

---

## O que é

Um pacote por aparelho, como no Manjaro: instalar o Meridian num Lumia 730 é

```bash
apt-get install meridian-device-nokia-superman
```

O pacote traz: fragment de kernel + patches + DTS + manifest de firmware + `hwinit` + scripts de flash/recovery. **O core do OS é sempre o mesmo** — trocar de aparelho = trocar de pacote (SDD §6).

| Item | Valor |
|------|-------|
| SDD | `meridian-os/SDD-MERIDIAN-MOBILE.md` (§6 drivers, §14 Build 1) |
| Plano de build | `meridian-os/docs/lumia730-build1.md` (E0–E7) |
| Gates de pesquisa | `meridian-os/docs/lumia730-research.md` (Gates 1–8) |
| Série mainline MSM8x26 | [patchew — Initial support for MSM8x26 Lumias](https://patchew.org/linux/20230930221323.101289-1-rayyan@ansari.sh/) (aceita no 6.7) |
| Bootloader | [WPInternals](https://github.com/ReneLergner/WPinternals) → boot menu EFIESP ([pmOS wiki](https://wiki.postmarketos.org/wiki/Windows_Phone)) → [BootShim](https://github.com/imbushuo/boot-shim) → [lk2nd](https://github.com/msm8916-mainline/lk2nd) |
| Info de flash/port | XDA Forums (seção Lumia 730/735) + org [Mainline4Lumia](https://github.com/Mainline4Lumia) |

## Estrutura

```
device.yaml          metadados do aparelho (fonte da verdade)
kernel/              fragment.config + patches/series (quilt)
dts/                 qcom-msm8226-microsoft-superman.dts (novo — o 730 não está no mainline)
firmware/            manifest de blobs (download pelo usuário — NUNCA commitados)
hwinit.sh            bring-up de HW (padrão phase1/ do monorepo)
flash/               backup.sh (obrigatório) · INSTALL.md · rawprogram/patch
kas/                 build KAS do sistema para este aparelho
package/             anatomia do .deb (DEBIAN/control + postinst)
recovery.md          procedimento de restauração (Gate 7)
```

## Começar

1. Ler `flash/INSTALL.md` (unlock → boot menu → lk2nd → kernel).
2. **E1 primeiro**: `./flash/backup.sh` e validar o restore.
3. Build 1 sem modem/Wi-Fi/Android — escopo em `meridian-os/SDD-MERIDIAN-MOBILE.md` §14.

> ℹ️ Repos criado sob a conta pessoal (`tantoniazi`) — migrar para a org
> `meridian-systems` quando ela existir (o SDD §6.2 já define o layout da org).
