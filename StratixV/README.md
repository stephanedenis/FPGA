# Storey Peak / Stratix V GS — Guide de démarrage zéro

## Carte identifiée

| Attribut | Valeur |
|----------|--------|
| Nom | Microsoft Storey Peak (Catapult v2) |
| FPGA | Intel Stratix V GS — **5SGSMD5K1F40** |
| JTAG ID | `0x029070DD` |
| Variante die | `5SGSMD5K2F40` (2e PCIe HIP caché, voir docs/) |
| Interface JTAG | FT232H embarqué sur USB (`0403:6014`) |
| Horloge embarquée | 125 MHz sur PIN_M23 |

---

## Prérequis logiciels

### Quartus (synthèse RTL)

Utiliser **Quartus Prime Standard 21.1.1** — seule version qui supporte Stratix V GS gratuitement.

```bash
# Depuis Quartus-21.1.1.850-linux-complete.tar
tar -xf Quartus-21.1.1.850-linux-complete.tar -C /tmp/q21 \
  components/QuartusSetup-21.1.1.850-linux.run \
  components/stratixv-21.1.1.850.qdz

chmod +x /tmp/q21/components/QuartusSetup-21.1.1.850-linux.run
/tmp/q21/components/QuartusSetup-21.1.1.850-linux.run \
  --mode unattended --accept_eula 1 --installdir ~/intelFPGA/21.1

# IMPORTANT : le device pack Stratix V est un ZIP
unzip -q /tmp/q21/components/stratixv-21.1.1.850.qdz -d ~/intelFPGA/21.1/
```

**Matrice de compatibilité :**

| Version | Edition | Stratix V GS |
|---------|---------|-------------|
| 17.0 – 21.1 | **Standard** | ✅ |
| 17.0 – 21.1 | Lite | ❌ |
| 22.x – 26.x | Pro | ❌ (`Family not supported`) |

Voir [docs/TOOLCHAIN_SETUP.md](docs/TOOLCHAIN_SETUP.md) pour les détails.

### Plugin JTAG FT232H

Source : [j-marjanovic/jtag-quartus-ft232h](https://github.com/j-marjanovic/jtag-quartus-ft232h)  
Bugs corrigés : voir [plugin/README.md](plugin/README.md)

```bash
git clone https://github.com/j-marjanovic/jtag-quartus-ft232h
cd jtag-quartus-ft232h
# Appliquer plugin/do_flush_patch.diff
mkdir build && cd build && cmake .. && make -j$(nproc)
cp build/libjtag_hw_otma.so ~/intelFPGA/21.1/quartus/linux64/
```

---

## Workflow de mise en service (ordre strict)

### 1. Vérifier l'USB
```bash
lsusb -d 0403:6014
# → Bus 002 Device 007: ID 0403:6014 Future Technology Devices...
```

### 2. Initialiser le FT232H via OpenOCD
```bash
openocd -f interface/ftdi/um232h.cfg \
  -c "adapter speed 1000; transport select jtag; \
      jtag newtap auto0 tap -irlen 10 -expected-id 0x029070dd; \
      init; exit;"
# → tap/device found: 0x029070dd
```

### 3. Scanner la chaîne JTAG
```bash
~/altera_pro/26.1/quartus/bin/jtagd --foreground --debug --port 1309 &
sleep 2
~/altera_pro/26.1/quartus/bin/jtagconfig
# → 1) OTMA FT232H [bus-instance]
#      029070DD   5SGSMD5H(1|2|3)/5SGSMD5K1/..
```

### 4. Compiler le circuit de vérification
```bash
cd trivial/
export LD_LIBRARY_PATH=$HOME/lib64_shim:/usr/lib64
export LM_LICENSE_FILE=~/intelFPGA/18.1/licenses/license.dat
~/intelFPGA/21.1/quartus/bin/quartus_sh --flow compile trivial
# → 0 errors — Elapsed: ~3 min — output_files/trivial.sof (24 MB)
```

### 5. Programmer et vérifier
```bash
~/altera_pro/26.1/quartus/bin/quartus_pgm \
  -c 1 -m JTAG -o 'p;trivial/output_files/trivial.sof'
# → Configuration succeeded -- 1 device(s) configured

~/altera_pro/26.1/quartus/bin/jtagconfig -d
# → + Node 00486E00  Source/Probe #0    ← ISSP actif !
# → + Design hash    080F144288D793FD861D
# Les 8 LEDs physiques clignotent (motif walking)
```

---

## Pinout validé (racerxdl/pcieledblink)

| Signal | Pin | Standard |
|--------|-----|----------|
| clkin 125 MHz | PIN_M23 | SSTL-135 |
| LED[7] | PIN_A8 | 2.5 V |
| LED[6] | PIN_B8 | 2.5 V |
| LED[5] | PIN_C8 | 2.5 V |
| LED[4] | PIN_C9 | 2.5 V |
| LED[3] | PIN_C10 | 2.5 V |
| LED[2] | PIN_B10 | 2.5 V |
| LED[1] | PIN_A10 | 2.5 V |
| LED[0] | PIN_A11 | 2.5 V |
| PCIe perst | PIN_AB28 | 2.5 V |

---

## Références communautaires

| Repo | Contenu |
|------|---------|
| [j-marjanovic/jtag-quartus-ft232h](https://github.com/j-marjanovic/jtag-quartus-ft232h) | Plugin FT232H pour Quartus jtagd |
| [racerxdl/pcieledblink](https://github.com/racerxdl/pcieledblink) | PCIe + LED blink — pinout validé HW |
| [thinkoco/microsoft_fpga](https://github.com/thinkoco/microsoft_fpga) | BSP OpenCL 18.1.2 — RISC-V E203 |
| [wirebond/sv_second_pcie_hip](https://gist.github.com/wirebond/9e75db58112bb49c6b2debad7dc13cb2) | 2e PCIe HIP caché (LD_PRELOAD trick) |
| [github.com/topics/storey-peak](https://github.com/topics/storey-peak) | Tous les repos taggés storey-peak |

## Dépannage

Voir [docs/JTAG_RECOVERY_RUNBOOK.md](docs/JTAG_RECOVERY_RUNBOOK.md) et `scripts/fpga_jtag_recover.sh`.

| Erreur | Solution |
|--------|----------|
| `LIBUSB_ERROR_BUSY` | `pkill -9 jtagd` puis `./scripts/fpga_jtag_recover.sh` |
| `Family Stratix V is not supported` | Utiliser Quartus Standard 21.1 (pas Pro) |
| `ddb_stratixv_hdr.ddb not installed` | `unzip stratixv-21.1.1.850.qdz -d ~/intelFPGA/21.1/` |
| `License file is not specified` | `export LM_LICENSE_FILE=...` |
| Hang sur `refresh_defined_devices` | Plugin non patché, voir `plugin/` |
