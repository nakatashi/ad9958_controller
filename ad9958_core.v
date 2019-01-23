`timescale 1ns / 1ps
/*
 * ad9958_core.v
 * 
 */
`include "ad9958_address.vh"
`include "ad9958_vars.vh"

module ad9958_core(
				   input 		  clock,
				   input 		  reset_n,
				   // input from ftw, asf buffer registers.
				   input [32-1:0] ftw_ch0,
				   input [32-1:0] ftw_ch1,
				   input [32-1:0] asf_ch0,
				   input [32-1:0] asf_ch1,

				   // input from initizalization configuration registers.
				   input 		  vco_gain,
				   input [4:0] 	  clock_multiplier,
				   input [1:0] 	  dac_fscale_ch0,
				   input [1:0] 	  dac_fscale_ch1,

				   input 		  busy,

				   output 		  trigger,
				   output [4:0]   packs_to_send,
				   output [63:0]  data_input,

				   output 		  master_reset,
				   output 		  io_update
				   );

   /* STATEMACHINE DEFINITION */
   /*
	* soon after initialization is completed, this module moves to main loop of just setting asf and ftw.
	*/
   parameter
	 STATE_MASTER_RESET = 0,
	 STATE_IO_UPDATE = 1,
	 STATE_INSTRUCTION_WRITE = 2,
	 STATE_CSR_CONFIG = 3,
	 STATE_CFR_CONFIG = 4,
	 STATE_FR1_CONFIG = 5,
	 STATE_FR2_CONFIG = 6,
	 STATE_FTW_CONFIG = 7,
	 STATE_ASF_CONFIG = 8,
	 STATE_WAIT = 9;
   
   parameter
	 NONE_SELECTED = 0,
	 CH0_SELECTED = 1,
	 CH1_SELECTED = 2,
	 BOTH_SELECTED = 3;
   reg 							  init_done;
   reg [1:0] 					  channel_select;   

   reg [3:0] 					  state;
   reg [3:0] 					  next_state;
   
   reg [7:0] 					  reg_address;
   
   parameter
	 IO_MODE = `IOMODE_4_BIT;
   
   reg [32-1:0] 				  ftw_ch0_buf;
   reg [32-1:0] 				  ftw_ch1_buf;
   reg [32-1:0] 				  asf_ch0_buf;
   reg [32-1:0] 				  asf_ch1_buf;

   // Update internal buffer on io update, because next dds update sequence begins soon after io update.
   always @(posedge io_update) begin
	  ftw_ch0_buf <= ftw_ch0;
	  ftw_ch1_buf <= ftw_ch1;

	  asf_ch0_buf <= asf_ch0;
	  asf_ch1_buf <= asf_ch1;
   end

   always @(posedge clock) begin
	  if(~reset_n) begin
		 init_done <= 0;
		 state <= STATE_MASTER_RESET;
	  end else begin
		 case(state)
		   STATE_MASTER_RESET : begin
			  master_reset <= 1;
			  state <= STATE_INSTRUCTION_WRITE;
			  next_state <= STATE_CSR_CONFIG;
			  channel_select <= NONE_SELECTED;
			  reg_address <= `ADDR_CSR;
		   end

		   STATE_IO_UPDATE : begin
			  io_update <= 1;
			  state <= STATE_WAIT;
			  next_state <= STATE_INSTRUCTION_WRITE;
			  
			  if(init_done) begin
				 reg_address <= `ADDR_CSR;
				 channel_select <= CH0_SELECTED;
			  end else begin
				 reg_address <= `ADDR_CFR;
			  end
		   end // case: STATE_IO_UPDATE

		   STATE_INSTRUCTION_WRITE : begin
			  state <= STATE_WAIT;
			  master_reset <= 0;
			  trigger <= 1;
			  
			  case(reg_address)
				`ADDR_CSR : begin
				   next_state <= STATE_CSR_CONFIG;
				end
				`ADDR_FR1 : begin
				   next_state <= STATE_FR1_CONFIG;
				end
				`ADDR_FR2 : begin
				   next_state <= STATE_FR2_CONFIG;
				end
				`ADDR_CFR : begin
				   next_state <= STATE_CFR_CONFIG;
				end
				`ADDR_CFTW0 : begin
				   next_state <= STATE_FTW_CONFIG;
				end
				`ADDR_ACR : begin
				   next_state <= STATE_ASF_CONFIG;
				end
				default : begin
				   next_state <= STATE_INSTRUCTION_WRITE;
				end
			  endcase // case (reg_address)
			  
		   end // case: STATE_INSTRUCTION_WRITE

		   STATE_CSR_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_INSTRUCTION_WRITE;
			  trigger <= 1;

			  if(channel_select == NONE_SELECTED) begin
				 reg_address <= `ADDR_FR1;
			  end else begin
				 reg_address <= `ADDR_CFTW0;
			  end
		   end

		   STATE_CFR_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_IO_UPDATE;
			  reg_address <= `ADDR_CSR;
		   end

		   STATE_FR1_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_IO_UPDATE;
			  reg_address <= `ADDR_CSR;
		   end

		   // this state will be ignored, if needed, change reg_address assignments in STATE_FR1_CONFIG from ADDR_CSR to ADDR_FR2 and next_state from STATE_IO_UPDATE to STATE_INSTRUCTION_WRITE
		   STATE_FR2_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_IO_UPDATE;
			  reg_address <= `ADDR_CSR;
		   end

		   STATE_FTW_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_INSTRUCTION_WRITE;
			  reg_address <= `ADDR_ACR;
			  
			  case (channel_select)
				CH0_SELECTED : begin
				   channel_select <= CH1_SELECTED;
				end

				CH1_SELECTED : begin
				   channel_select <= CH0_SELECTED;
				end
				default : begin
				   channel_select <= CH0_SELECTED;
				end
			  endcase // case (channel_select)
		   end // case: STATE_FTW_CONFIG

		   STATE_ASF_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_INSTRUCTION_WRITE;
			  reg_address <= `ADDR_CSR;
		   end

		   STATE_WAIT : begin
			  master_reset <= 0;
			  io_update <= 0;
			  // wait for spi data transfer to complete
			  if(~busy) begin
				 state <= next_state;
			  end
		   end
		   default : begin
		   end
		 endcase // case (state)
	  end // else: !if(~reset_n)
   end // always @ (posedge clock)
endmodule // ad9958_core
   
