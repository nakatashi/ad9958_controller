`timescale 1ns / 1ps
module four_bit_spi(
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

   // where to put initiation of send
   parameter
	 STATE_IDLE = 0,
	 STATE_SEND = 1;

   reg [1:0] 						  state;
   reg [4:0] 						  packs_cntr;
   reg [63:0] 						  data_send;

   reg 								  triggered;

   initial begin
	  cs = 0;
   end

   always @(posedge clock or negedge clock) begin
	  if(~reset_n) begin
		 sclk <= 1'b1;
	  end else begin
		 case(state)
		   STATE_IDLE : begin
			  sclk <= 1'b1; //clock stall high
			  busy <= 0;
		   end
		   STATE_SEND : begin
			  sclk <= ~sclk;
			  busy <= 1;
		   end
		 endcase // case (state)
	  end
   end // always @ (posedge clock or negedge clock)

   // handle statemachine transition
   always @(posedge clock) begin
	  if(~reset_n) begin
		 state <= STATE_IDLE;
		 triggered <= 0;
	  end
	  case(state)
		STATE_IDLE : begin
		   if(trigger & ~busy) begin
			  triggered <= 1;
			  state <= STATE_SEND;
		   end else begin
			  triggered <= 0;
		   end
		end
		STATE_SEND : begin
		   triggered <= 0;
		   if(packs_cntr == 0) begin
			  state <= STATE_IDLE;
		   end
		end
	  endcase
   end


   always @(negedge sclk) begin
	  if(~reset_n) begin
		 sdio <= 4'b0;
	  end else begin
		 case(state)
		   STATE_IDLE : begin
			  sdio <= 4'b0;
		   end

		   STATE_SEND : begin
			  if(triggered) begin
				 sdio[0] <= data_input[0];
				 sdio[1] <= data_input[1];
				 sdio[2] <= data_input[2];
				 sdio[3] <= data_input[3];
				 packs_cntr <= packs_to_send - 1;
				 data_send <= (data_input >> 4);
			  end else begin
				 sdio[0] <= data_send[0];
				 sdio[1] <= data_send[1];
				 sdio[2] <= data_send[2];
				 sdio[3] <= data_send[3];
				 packs_cntr <= packs_cntr - 1;
				 data_send <= (data_send >> 4);
			  end // else: !if(triggered)
		   end
		 endcase // case (state)
	  end
	  
   end // always @ (negedge sclk)

   always @(posedge sclk) begin
	  
   end
endmodule
