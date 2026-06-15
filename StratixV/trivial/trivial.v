// trivial.v — Circuit de vérification Storey Peak / Stratix V GS
// Validé 2026-06-15 :
//   jtagconfig -d → + Node 00486E00  Source/Probe #0
//                  + Design hash    080F144288D793FD861D
// LEDs physiques clignotantes (motif walking).
//
// Compiler avec Quartus Prime Standard 21.1.1 (device pack stratixv requis)

module trivial (
    input  wire clkin,       // 125 MHz, PIN_M23 (SSTL-135)
    output wire [7:0] LED    // PIN_A8..A11, B8, B10, C8-C10 (2.5V)
);

reg [26:0] counter = 0;
always @(posedge clkin)
    counter <= counter + 1;

assign LED[0] = counter[24];   // ~3.7 Hz
assign LED[1] = counter[23];
assign LED[2] = counter[22];
assign LED[3] = counter[21];
assign LED[4] = counter[20];
assign LED[5] = counter[19];
assign LED[6] = counter[18];
assign LED[7] = counter[17];   // ~476 Hz

// ISSP : probe = 0xA5 (visible via jtagconfig -d après programmation)
altsource_probe #(
    .sld_instance_index   (0),
    .sld_ir_width         (4),
    .instance_id          ("TRIV"),
    .probe_width          (8),
    .source_width         (8),
    .source_initial_value ("0"),
    .enable_metastability ("NO")
) u_issp (
    .probe  (8'hA5),
    .source ()
);

endmodule
