# JTAG Recovery Runbook — Storey Peak / FT232H

## Recovery rapide

```bash
pkill -9 -f jtagd || true
sleep 1
openocd -f interface/ftdi/um232h.cfg \
  -c "adapter speed 1000; transport select jtag; \
      jtag newtap auto0 tap -irlen 10 -expected-id 0x029070dd; init; exit;"
~/altera_pro/26.1/quartus/bin/quartus_pgm -c 1 -a
# → 1) OTMA FT232H [bus-instance]
#      029070DD   5SGSMD5H(1|2|3)/5SGSMD5K1/..
```

## Causes racines documentées

- `LIBUSB_ERROR_BUSY` : jtagd tient l'USB → `pkill -9 jtagd`
- Hang `refresh_defined_devices` : plugin non patché (voir `plugin/`)
- Scan SLD infini sur FPGA vierge : bug do_flush, corrigé dans plugin patché

## Diagnostics sans sudo

```bash
# Qui tient l'USB ?
lsof /dev/bus/usb/ 2>/dev/null | grep -E 'jtagd|openocd|quartus'

# Stack trace du hang (sans root)
timeout 45 strace -ff -tt -s 256 -yy -k -o /tmp/strace_log \
  quartus_pgm -c 1 -m JTAG -o 'p;design.sof'
# Chercher AJI_CLIENT::refresh_defined_devices ou TCPLINK::receive
```

## Erreurs communes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `LIBUSB_ERROR_BUSY` | jtagd tient USB | `pkill -9 jtagd; sleep 1` |
| Hang 45s RC=124 | Bug do_flush | Installer plugin patché |
| SLD scan infini | FPGA vierge + bug bypass | Plugin patché |
| `Family Stratix V not supported` | Quartus Pro ou Lite | Utiliser Standard 21.1 |
| `ddb_stratixv_hdr.ddb not installed` | Device pack manquant | `unzip stratixv-21.1.1.850.qdz -d ~/intelFPGA/21.1/` |

## Script

```bash
./scripts/fpga_jtag_recover.sh           # recovery complet
./scripts/fpga_jtag_recover.sh --scan-only
./scripts/fpga_jtag_recover.sh --program design.sof
```
