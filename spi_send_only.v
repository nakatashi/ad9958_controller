`timescale 1ns / 1ps
/* PASSED TEST */

/*
 * Send-only-spi module
 * 1 pack (= 4 bit) of data are read every posedge of sclk.
 * Send only, Clock stall high, update sdio on negedge of sclk.
 * Data is sent in LSB first
 * packs[0] -> sdio[0]
 * packs[1] -> sdio[1]
 * ..
 * 
 * Usage of this module
 * 1. Set data to send on data_input and packs_to_send. see manual for AD9958.
 * 2. set trigger high when busy is low.
 * 3. wait for busy turn to low before sending next data.
 */
module spi_send_only(
					 input 			  clock,
					 input 			  reset_n,
					 input 			  trigger,
					 output reg 	  busy,
					 input [4:0] 	  packs_to_send,
					 // 
					 input [63:0] 	  data_input,
					 // SPI interface
					 output reg 	  cs,
					 output reg 	  sclk,
					 output reg [3:0] sdio
);
   /* STATEMACHINE DEFINITION */
   parameter
	 STATE_IDLE = 0,
	 STATE_SEND = 1;

   reg 								  state;
   reg [4:0] 						  packs_cntr;

   // Send buffer
   reg [63:0] 						  data_send;
   
   
   // set to low by default
   //assign sdio = 4'b0;
   // clock stall high
   //assign sclk = 1'b1;
   
   always @(posedge clock) begin
	  if(~reset_n) begin
		 cs <= 0; // assuming single device is connected.		 
		 state <= STATE_IDLE;
		 busy <= 1;
		 sclk <= 1'b1;
		 sdio <= 4'b0;
		 packs_cntr <= 5'b0;
	  end else begin
		 case(state)
		   STATE_IDLE : begin
			  if(trigger & ~busy) begin
				 state <= STATE_SEND;
				 busy <= 1;
				 packs_cntr <= packs_to_send;
				 data_send <= data_input;				 
			  end else begin
				 busy <= 0;
				 sclk <= 1'b1;
				 sdio <= 4'b0;
				 packs_cntr <= 5'b0;
			  end // else: !if(trigger & ~busy)
		   end // case: STATE_IDLE
		   
		   STATE_SEND : begin
			  sclk <= 1'b0;
		   end
		   
		   default : begin
		   end
		 endcase // case (state)
	  end // else: !if(~reset_n)
   end // always @ (posedge clock)

   always @(negedge clock)begin
	  if(~reset_n) begin
	  end else begin
		 case(state)
		   STATE_IDLE : begin
		   end

		   STATE_SEND : begin
			  sclk <= 1'b1;
		   end

		   default :begin
		   end

		 endcase // case (state)
	  end // else: !if(~reset_n)
   end // always @ (negedge clock)

   /*
	* Update sdio registers.
	*/
   always @(negedge sclk) begin
	  if(~reset_n) begin
		 sdio <= 4'b0;
	  end else begin
		 case (state)
		   STATE_IDLE : begin
		   end

		   STATE_SEND : begin
			  // once sdio is updated, shift data_send @ posedge of sclk
			  sdio[0] <= data_send[0];
			  sdio[1] <= data_send[1];
			  sdio[2] <= data_send[2];
			  sdio[3] <= data_send[3];

			  packs_cntr <= packs_cntr - 1;
		   end

		   default : begin
		   end
		 endcase // case (state)
	  end // else: !if(~reset_n)
   end // always @ (negedge sclk)

   always @(posedge sclk) begin
	  case (state)
		STATE_IDLE :begin
		end

		STATE_SEND : begin
		   if(packs_cntr == 0) begin
			  data_send <= 64'h0;
			  state <= STATE_IDLE;
		   end else begin
			  // shift data for next pack
			  //data_send <= {4'b0, data_send[32:4]};
			  data_send <= (data_send >> 4);
		   end
		end
	  endcase // case (state)
   end // always @ (posedge sclk)
endmodule // spi_send_only
