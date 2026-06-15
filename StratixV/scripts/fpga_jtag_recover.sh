#!/usr/bin/env bash
set -euo pipefail
# Fast recovery helper for Storey Peak FT232H/JTAG incidents.
# Validated on Storey Peak / Stratix V 5SGSMD5K1F40 (JTAG ID 0x029070DD)

QUARTUS_PGM="${QUARTUS_PGM:-/home/stephane/altera_pro/26.1/quartus/bin/quartus_pgm}"
OPENOCD="${OPENOCD_BIN:-openocd}"
ADAPTER_CFG="${ADAPTER_CFG:-interface/ftdi/um232h.cfg}"
EXPECTED_ID="${EXPECTED_ID:-0x029070dd}"
JTAG_SPEED="${JTAG_SPEED:-1000}"
USB_FILTER="${USB_FILTER:-0403:6014}"
PROGRAM_FILE=""

DO_KILL_JTAGD=1; DO_KILL_QUARTUS=0; DO_OPENOCD_INIT=1; DO_SCAN=1; DO_PROGRAM=0

usage() { cat <<'EOF'
Usage: fpga_jtag_recover.sh [options]

Options:
  --scan-only               Scan Quartus seulement
  --init-only               Kill jtagd + OpenOCD init seulement
  --program <file>          Programmer un SOF/JIC
  --kill-quartus            Kill quartus_pgm avant recovery
  --speed <kHz>             Vitesse JTAG pour OpenOCD (défaut: 1000)
  --expected-id <hex>       JTAG ID attendu (défaut: 0x029070dd)
  --no-kill-jtagd           Ne pas tuer jtagd
  --quartus-pgm <path>      Override quartus_pgm
  --openocd <path>          Override openocd
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scan-only)     DO_KILL_JTAGD=1;DO_OPENOCD_INIT=0;DO_SCAN=1;DO_PROGRAM=0;shift;;
    --init-only)     DO_KILL_JTAGD=1;DO_OPENOCD_INIT=1;DO_SCAN=0;DO_PROGRAM=0;shift;;
    --program)       PROGRAM_FILE="${2:-}";DO_PROGRAM=1;shift 2;;
    --kill-quartus)  DO_KILL_QUARTUS=1;shift;;
    --speed)         JTAG_SPEED="${2:-}";shift 2;;
    --expected-id)   EXPECTED_ID="${2:-}";shift 2;;
    --no-kill-jtagd) DO_KILL_JTAGD=0;shift;;
    --quartus-pgm)   QUARTUS_PGM="${2:-}";shift 2;;
    --openocd)       OPENOCD="${2:-}";shift 2;;
    -h|--help)       usage;exit 0;;
    *)               echo "ERROR: $1" >&2;usage;exit 1;;
  esac
done

if ! lsusb -d "$USB_FILTER" >/dev/null 2>&1; then
  echo "ERROR: FTDI $USB_FILTER introuvable" >&2; exit 1
fi
echo "[1/4] FTDI: $(lsusb -d "$USB_FILTER")"

[[ "$DO_KILL_JTAGD" -eq 1 ]]    && { echo "[2/4] pkill jtagd"; pkill -9 -f jtagd 2>/dev/null||true; sleep 1; }
[[ "$DO_KILL_QUARTUS" -eq 1 ]]  && pkill -f 'quartus_pgm -c 1' 2>/dev/null||true

if [[ "$DO_OPENOCD_INIT" -eq 1 ]]; then
  echo "[3/4] OpenOCD init speed=${JTAG_SPEED} id=${EXPECTED_ID}"
  "$OPENOCD" -f "$ADAPTER_CFG" \
    -c "adapter speed ${JTAG_SPEED}; transport select jtag; \
        jtag newtap auto0 tap -irlen 10 -expected-id ${EXPECTED_ID}; init; exit;"
fi

[[ "$DO_SCAN" -eq 1 ]]    && { echo "[4/4] Quartus scan"; "$QUARTUS_PGM" -c 1 -a; }
[[ "$DO_PROGRAM" -eq 1 ]] && { echo "[5/5] Programming: $PROGRAM_FILE"; "$QUARTUS_PGM" -c 1 -m JTAG -o "p;${PROGRAM_FILE}"; }

echo "Done."
