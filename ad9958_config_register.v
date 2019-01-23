`timescale 1ns / 1ps
/*
 * ad9958_config_register.v
 * 
 * temporaly, this module just returns default values.
 * ref_clk = 30 MHz, clock_multiplier = 10
 * sys_clk = 30 * 10 MHz -> vco gain = enabled
 */
`include "ad9958_vars.vh"

module ad9958_config_register(
							  output reg 	   vco_gain,
							  output reg [4:0] clock_multiplier,
							  output reg [1:0] dac_fscale_ch0,
							  output reg [1:0] dac_fscale_ch1
);
   initial begin
	  vco_gain = 1'b1;
	  clock_multiplier = 5'd10;
	  dac_fscale_ch0 = `DAC_FSCALE_HALF;
	  dac_fscale_ch1 = `DAC_FSCALE_HALF;
   end
   
endmodule
