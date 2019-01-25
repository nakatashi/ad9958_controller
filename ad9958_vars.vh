`ifndef _AD9958_VARS_VH_

 `define _AD9958_VARS_VH_
 `define INSTRUCTION_WRITE 8'h00
 `define INSTRUCTION_READ 8'80

// bit-shifted
 `define IOMODE_2_WIRE 3'b000
 `define IOMODE_3_WIRE 3'b010
 `define IOMODE_2_BIT 3'b100
 `define IOMODE_4_BIT 3'b110

 `define DAC_FSCALE_FULL 2'b11
 `define DAC_FSCALE_HALF 2'b01
 `define DAC_FSCALE_QUARTER 2'b10
 `define DAC_FSCALE_EIGHTH 2'b00

`endif
