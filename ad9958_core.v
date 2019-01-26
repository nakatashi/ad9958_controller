`timescale 1ns / 1ps
/*
 * ad9958_core.v
 * 
 */
`include "ad9958_registers.vh"
`include "ad9958_vars.vh"

module ad9958_core(
				   input 			 clock,
				   input 			 reset_n,
				   // input from ftw, asf buffer registers.
				   input [32-1:0] 	 ftw_ch0,
				   input [32-1:0] 	 ftw_ch1,
				   input [10-1:0] 	 asf_ch0,
				   input [10-1:0] 	 asf_ch1,

				   // input from initizalization configuration registers.
				   input 			 vco_gain,
				   input [4:0] 		 clock_multiplier,
				   // dac_fscale_ch1 is ignored
				   input [1:0] 		 dac_fscale_ch0,
				   input [1:0] 		 dac_fscale_ch1,

				   input 			 busy,

				   output reg 		 trigger,
				   output reg 		 four_bit,
				   output reg [5:0]  bits_to_send,
				   output reg [63:0] data_input,

				   output reg 		 master_reset,
				   output reg 		 io_update
				   );

   // Configuration bits.
   parameter
	 MSB_FIRST = 0,
	 LSB_FIRST = 1;

   parameter
	 ASF_EN = 13'b1000000000000;

   parameter
	 CH0_ENABLE = 8'b01000000,
	 CH1_ENABLE = 8'b10000000;

   parameter
	 IO_MODE = `IOMODE_4_BIT;

   
   /* STATEMACHINE DEFINITION */
   /*
	* soon after initialization is completed, this module moves to main loop of just setting asf and ftw.
	*/
   parameter
	 STATE_MASTER_RESET = 0,
	 STATE_IO_UPDATE = 1,
	 STATE_INSTRUCTION_WRITE = 2,
	 STATE_CSR_CONFIG = 3,
	 STATE_FR1_CONFIG = 4,
	 STATE_FR2_CONFIG = 5,
	 STATE_CFR_CONFIG = 6,
	 STATE_FTW_CONFIG = 7,
	 STATE_ASF_CONFIG = 8,
	 STATE_WAIT = 9;
   
   parameter
	 NONE_SELECTED = 0,
	 CH0_SELECTED = 1,
	 CH1_SELECTED = 2,
	 BOTH_SELECTED = 3;

   parameter
	 TUNE_FREQ = 0,
	 TUNE_AMPL = 1;
   
   reg 								 init_done;
   reg [1:0] 						 channel_select;
   reg 								 io_mode_set;

   reg [3:0] 						 state;
   reg [3:0] 						 next_state;
   
   reg [7:0] 						 reg_address;

   reg [1:0] 						 tune_target;
   
   reg [32-1:0] 					 ftw_ch0_buf;
   reg [32-1:0] 					 ftw_ch1_buf;
   reg [32-1:0] 					 asf_ch0_buf;
   reg [32-1:0] 					 asf_ch1_buf;

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
		 master_reset <= 0;
		 state <= STATE_MASTER_RESET;
		 io_mode_set <= 0;
	  end else begin
		 case(state)
		   STATE_MASTER_RESET : begin
			  four_bit <= 0;
			  master_reset <= 0;
			  state <= STATE_INSTRUCTION_WRITE;
			  next_state <= STATE_CSR_CONFIG;
			  channel_select <= BOTH_SELECTED;
			  reg_address <= `ADDR_CSR;
			  tune_target <= TUNE_FREQ;

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
			  data_input <= reg_address | `INSTRUCTION_WRITE;
			  bits_to_send <= `SIZE_INST;

			  if(io_mode_set) begin
				 four_bit <= 1;
			  end else begin
				 four_bit <= 0;
			  end
			  
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

			  bits_to_send <= `SIZE_CSR;
			  
			  case (channel_select)
				CH0_SELECTED : begin
				   // LSB first.
				   data_input <= CH0_ENABLE | MSB_FIRST | IO_MODE;
				   case(tune_target)
					 TUNE_FREQ : begin
						reg_address <= `ADDR_CFTW0;
					 end
					 TUNE_AMPL :begin
						reg_address <= `ADDR_ACR;
					 end
				   endcase
				end

				CH1_SELECTED : begin
				   data_input <= CH1_ENABLE | MSB_FIRST | IO_MODE;
				   case(tune_target)
					 TUNE_FREQ : begin
						reg_address <= `ADDR_CFTW0;
					 end
					 TUNE_AMPL :begin
						reg_address <= `ADDR_ACR;
					 end
				   endcase
				end

				BOTH_SELECTED : begin
				   io_mode_set <= 1;
					data_input <= CH0_ENABLE | CH1_ENABLE | MSB_FIRST | IO_MODE;
				   reg_address <= `ADDR_FR1;
				end
				
				default : begin /*NONE_SELECTED*/
				   data_input <= MSB_FIRST | IO_MODE;
				   reg_address <= `ADDR_FR1;
				end
			  endcase // case (channel_select)
		   end // case: STATE_CSR_CONFIG

		   STATE_FR1_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_IO_UPDATE;
			  reg_address <= `ADDR_CSR;

			  trigger <= 1;
			  bits_to_send <= `SIZE_FR1;
			  data_input <= (vco_gain << 23) | (clock_multiplier << 18);
			  
		   end

		   // this state will be ignored, if needed, change reg_address assignments in STATE_FR1_CONFIG from ADDR_CSR to ADDR_FR2 and next_state from STATE_IO_UPDATE to STATE_INSTRUCTION_WRITE
		   STATE_FR2_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_IO_UPDATE;
			  reg_address <= `ADDR_CSR;
		   end

		   STATE_CFR_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_IO_UPDATE;
			  init_done <= 1;

			  trigger <= 1;

			  bits_to_send <= `SIZE_CFR;
			  data_input <= (dac_fscale_ch0 << 8);
			  
			  reg_address <= `ADDR_CSR;
		   end // case: STATE_CFR_CONFIG

		   STATE_FTW_CONFIG : begin
			  state <= STATE_WAIT;
			  next_state <= STATE_INSTRUCTION_WRITE;

			  trigger <= 1;
			  bits_to_send <= `SIZE_CFTW0;
			  
			  case(channel_select)
				CH0_SELECTED : begin
				   channel_select <= CH1_SELECTED;
				   data_input <= ftw_ch0_buf;
				   next_state <= STATE_INSTRUCTION_WRITE;
				   tune_target <= TUNE_FREQ;

				end
				CH1_SELECTED : begin
				   channel_select <= CH0_SELECTED;
				   data_input <= ftw_ch1_buf;
				   next_state <= STATE_IO_UPDATE;
				   tune_target <= TUNE_AMPL;

				end
				default : begin
				   // THIS IS EXCEPTION, DO NOTHING
				end
			  endcase // case (channel_select)
//			  reg_address <= `ADDR_ACR;
			  reg_address <= `ADDR_CSR;
			  // case (channel_select)
		   end // case: STATE_FTW_CONFIG

		   STATE_ASF_CONFIG : begin
			  state <= STATE_WAIT;

			  trigger <= 1;
			  bits_to_send <= `SIZE_ACR;
			  
			  case (channel_select)
				CH0_SELECTED : begin
				   channel_select <= CH1_SELECTED;
				   // only channel0 is configured, configure channel1 without issuing io_update.
				   next_state <= STATE_INSTRUCTION_WRITE;
				   data_input <= ASF_EN | asf_ch0_buf;
				   tune_target <= TUNE_AMPL;

				end

				CH1_SELECTED : begin
				   channel_select <= CH0_SELECTED;
				   // both channels are configured, issue io_update to reflect changes.
				   next_state <= STATE_IO_UPDATE;
				   data_input <= ASF_EN | asf_ch1_buf;
				   tune_target <= TUNE_FREQ;
				end
				default : begin
				   channel_select <= CH0_SELECTED;
				end
			  endcase // case (channel_select)
			  
			  reg_address <= `ADDR_CSR;
		   end // case: STATE_ASF_CONFIG

		   STATE_WAIT : begin
			  master_reset <= 0;
			  io_update <= 0;
			  trigger <= 0;
			  // wait for spi data transfer to complete
			  if(~ (busy | trigger)) begin
				 state <= next_state;
			  end
		   end
		   default : begin
		   end
		 endcase // case (state)
	  end // else: !if(~reset_n)
   end // always @ (posedge clock)
endmodule // ad9958_core

