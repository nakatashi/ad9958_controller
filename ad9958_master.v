`timescale 1ns / 1ps

module ad9958_master(
					 input 			  clock,
					 input 			  reset_n,

					 output 		  cs,
					 output 		  sclk,
					 output [3:0] 	  sdio,

					 output 		  master_reset,
					 output 		  io_update,


					 input [32-1:0] ftw_ch0,
					 input [32-1:0] ftw_ch1,
					 input [10-1:0] asf_ch0,
					 input [10-1:0] asf_ch1
);
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [5:0]			bits_to_send;			// From ad9958_core_inst of ad9958_core.v
   wire					busy;					// From spi_master of four_bit_spi.v
   wire [4:0]			clock_multiplier;		// From config_register of ad9958_config_register.v
   wire [1:0]			dac_fscale_ch0;			// From config_register of ad9958_config_register.v
   wire [1:0]			dac_fscale_ch1;			// From config_register of ad9958_config_register.v
   wire [63:0]			data_input;				// From ad9958_core_inst of ad9958_core.v
   wire					four_bit;				// From ad9958_core_inst of ad9958_core.v
   wire					trigger;				// From ad9958_core_inst of ad9958_core.v
   wire					vco_gain;				// From config_register of ad9958_config_register.v
   // End of automatics
   
   ad9958_core ad9958_core_inst(/*AUTOINST*/
								// Outputs
								.trigger		(trigger),
								.four_bit		(four_bit),
								.bits_to_send	(bits_to_send[5:0]),
								.data_input		(data_input[63:0]),
								.master_reset	(master_reset),
								.io_update		(io_update),
								// Inputs
								.clock			(clock),
								.reset_n		(reset_n),
								.ftw_ch0		(ftw_ch0[32-1:0]),
								.ftw_ch1		(ftw_ch1[32-1:0]),
								.asf_ch0		(asf_ch0[10-1:0]),
								.asf_ch1		(asf_ch1[10-1:0]),
								.vco_gain		(vco_gain),
								.clock_multiplier(clock_multiplier[4:0]),
								.dac_fscale_ch0	(dac_fscale_ch0[1:0]),
								.dac_fscale_ch1	(dac_fscale_ch1[1:0]),
								.busy			(busy));
   

   four_bit_spi spi_master(/*AUTOINST*/
						   // Outputs
						   .busy				(busy),
						   .cs					(cs),
						   .sclk				(sclk),
						   .sdio				(sdio[3:0]),
						   // Inputs
						   .clock				(clock),
						   .reset_n				(reset_n),
						   .trigger				(trigger),
						   .four_bit			(four_bit),
						   .bits_to_send		(bits_to_send[5:0]),
						   .data_input			(data_input[63:0]));

   ad9958_config_register config_register(/*AUTOINST*/
										  // Outputs
										  .vco_gain				(vco_gain),
										  .clock_multiplier		(clock_multiplier[4:0]),
										  .dac_fscale_ch0		(dac_fscale_ch0[1:0]),
										  .dac_fscale_ch1		(dac_fscale_ch1[1:0]));

endmodule
