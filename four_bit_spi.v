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
					 output  	  sclk,
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

/*   always @(posedge clock or negedge clock) begin
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
   end // always @ (posedge clock or negedge clock)*/

   reg pos;
   reg neg;

   assign sclk = !(neg^pos);
   // Phase of sclk is constant because reset_n is evaluated at the edge of clock.
   always @(posedge clock)begin
	  if(~reset_n) pos <= 0;
	  else begin
		 if(state == STATE_SEND) pos <= ~pos;

	  end
   end

   always @(negedge clock)begin
	  if(~reset_n) begin
		 neg <= 0;
	  end
	  else begin
		 if(state == STATE_SEND) neg <= ~neg;
	  end
   end

   // handle statemachine transition
   always @(posedge clock) begin
	  if(~reset_n) begin
		 state <= STATE_IDLE;
		 triggered <= 0;
		 busy <= 0;
	  end
	  case(state)
		STATE_IDLE : begin
		   if(trigger & ~busy) begin
			  busy <=1 ;
			  triggered <= 1;
			  state <= STATE_SEND;
		   end else begin
			  busy <= 0;
			  triggered <= 0;
		   end
		end
		STATE_SEND : begin
		   busy <= 1;
		   triggered <= 0;
		   if(packs_cntr == 0) begin
			  state <= STATE_IDLE;
		   end
		end
	  endcase
   end // always @ (posedge clock)

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
endmodule
