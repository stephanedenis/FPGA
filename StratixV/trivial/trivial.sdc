# Timing constraints pour Storey Peak (horloge embarquée 125 MHz)
create_clock -name clkin -period 8.000 [get_ports clkin]
derive_pll_clocks
derive_clock_uncertainty
