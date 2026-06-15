# Plugin libjtag_hw_otma.so — Patches appliqués (2026-06-14)

Source upstream : [j-marjanovic/jtag-quartus-ft232h](https://github.com/j-marjanovic/jtag-quartus-ft232h)

## Trois bugs corrigés

### Bug 1 — `do_flush` bit-par-bit (root cause du hang)

L'implémentation originale appelait `mpsse_clock_tms_cs()` pour chaque bit,
y compris les longues séquences TMS=0 (SHIFT-DR/SHIFT-IR data clocking).
`mpsse_clock_tms_cs()` est limité à **7 bits par commande MPSSE** →
overvhead USB massif → jtagd attendait la fin du scan SLD indéfiniment.

**Fix** : utiliser `mpsse_clock_data()` (65536 bytes/commande) pour les runs TMS=0.

### Bug 2 — SLD hub scan infini sur FPGA vierge

jtagd décale des 1s dans le DR SLD jusqu'à trouver un 0 (fin du registre).
Sur FPGA vierge, BYPASS propage TDO=TDI=1 → boucle infinie.

**Fix** : si 128 bits TMS=0, TDI=0xFF, TDO=0xFF → substituer TDO=0x00
(signale "no SLD hub" à jtagd).

### Bug 3 — TCK non contrôlé

`mpsse_open()` sans `mpsse_set_frequency()` → TCK par défaut indéfini.

**Fix** : `mpsse_set_frequency(ctx, 3000000)` (3 MHz conservatif).

## Preuves

Avant patch :
```
# quartus_pgm -c 1 -m JTAG -o 'p;design.sof'
# → accroché indéfiniment (timeout 45s, RC=124)
# strace → AJI_CLIENT::refresh_defined_devices → recvfrom infini
```

Après patch :
```
Info (209007): Configuration succeeded -- 1 device(s) configured
Info: Elapsed time: 00:01:29
```

## Build

```bash
git clone https://github.com/j-marjanovic/jtag-quartus-ft232h
cd jtag-quartus-ft232h
git apply ../StratixV/plugin/do_flush_patch.diff  # ou appliquer manuellement
mkdir build && cd build && cmake .. && make -j$(nproc)
cp build/libjtag_hw_otma.so ~/intelFPGA/21.1/quartus/linux64/
cp build/libjtag_hw_otma.so ~/altera_pro/26.1/quartus/linux64/  # pour Pro aussi
```
