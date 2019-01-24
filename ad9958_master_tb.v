`timescale 1ns / 1ps

module ad9958_master_tb;

   wire cs;
   wire sclk;
   wire [3:0] sdio;
   wire 	  master_reset;
   wire 	  io_update;

   reg 		  clock;
   reg 		  reset_n;

   reg [32-1:0] ftw_ch0;
   reg [32-1:0] ftw_ch1;
   reg [32-1:0] asf_ch0;
   reg [32-1:0] asf_ch1;

   ad9958_master ad9958_master_inst(/*AUTOINST*/
									// Outputs
									.cs					(cs),
									.sclk				(sclk),
									.sdio				(sdio[3:0]),
									.master_reset		(master_reset),
									.io_update			(io_update),
									// Inputs
									.clock				(clock),
									.reset_n			(reset_n),
									.ftw_ch0			(ftw_ch0[32-1:0]),
									.ftw_ch1			(ftw_ch1[32-1:0]),
									.asf_ch0			(asf_ch0[32-1:0]),
									.asf_ch1			(asf_ch1[32-1:0]));

   always begin
	  #10 	 clock = ~clock;
   end

   always @(posedge clock) begin
	  ftw_ch0 <= ftw_ch0 + 10;
	  ftw_ch1 <= ftw_ch1 + 10;
	  asf_ch0 <= asf_ch0 + 20;
	  asf_ch1 <= asf_ch1 + 20;
   end

   initial begin
	  $dumpfile("ad9958_master.vcd");
	  $dumpvars(0, ad9958_master_tb);

	  $display("START");
	  clock <= 0;
	  reset_n <= 0;

	  ftw_ch0 <= 0;
	  ftw_ch1 <= 0;
	  asf_ch0 <= 0;
	  asf_ch1 <= 0;
	  
	  #100 reset_n <= 1;


	  #100000
		$display("END");
	  $finish;	  
	  
   end // initial begin

endmodule
