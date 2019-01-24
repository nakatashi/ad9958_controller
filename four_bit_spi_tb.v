`timescale 1ns / 1ps

module four_bit_spi_tb;
   wire busy;
   wire cs;
   wire sclk;
   wire [3:0] sdio;

   reg 		 clock;
   reg 		 reset_n;
   reg 		 trigger;
   reg [4:0] packs_to_send;
   reg [63:0] data_input;
   
   four_bit_spi dut(/*AUTOINST*/
					 // Outputs
					 .busy				(busy),
					 .cs				(cs),
					 .sclk				(sclk),
					 .sdio				(sdio[3:0]),
					 // Inputs
					 .clock				(clock),
					 .reset_n			(reset_n),
					 .trigger			(trigger),
					 .packs_to_send		(packs_to_send[4:0]),
					 .data_input		(data_input[63:0]));
   // clock generation   
   always begin
	  #10 	 clock = ~clock;
   end
   integer 	   i;


   initial begin
	  $dumpfile("four_bit_spi_tb.vcd");
	  $dumpvars(0, four_bit_spi_tb);
	  data_input = 0;
	  for(i = 0;i < 10; i = i+1)begin
	//	 data_input[i*4+3:i*4] <= i;
		 data_input = data_input | (i & 4'hF) << (i << 2);
	  end


	  
	  $display("START");
	  clock <= 0;
	  reset_n <= 0;
	  #100 reset_n <= 1;
	  #10 packs_to_send <= 10;

	  #10 trigger <= 1;

	  #20 trigger <= 0;

	  # 1000 trigger <= 1;
	  packs_to_send <= 10;
	  # 20 trigger <= 0;
	  
	  #10000
		$display("END");
	  $finish;
	  
   end // initial begin
   
   
endmodule // testbench
