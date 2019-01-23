`timescale 1ns / 1ps
module four_bit_spi(
   input reset_n,
    input clock,
    input send_en,

    input [3:0] send_data,
    input [3:0] packs_to_send, //1 pack = 4 bit

    output reg cs,
    output reg sclk,
    output reg [3:0] sdio,
    output reg req_complete
);
/*
four-bit spi module optimized for AD9958
*/

//

//reg [3:0] data_to_send;

reg [3:0] packs_sent;

always @(posedge clock)
begin
    if(~(reset_n & send_en))
    begin
        cs <= 0;
        sclk <= 1'b1;
        sdio <= 4'b0;
        packs_sent <= 0;
        req_complete <= 0;
    end
    else if(send_en) begin
        sclk <= 1'b1;
    end
end

always @(negedge clock)
begin
    if(send_en)
    begin
        sclk <= 1'b0;
    end
    else begin
        sclk <= 1'b1;
    end
end

always @(posedge sclk)
begin
    if(send_en)
    begin
        if(packs_sent == packs_to_send)
        begin
            req_complete = 1'b1;
        end
    end
end

// Update SDIO on negedge of SCLK
always @(negedge sclk)
begin
    if(send_en)
    begin
        sdio <= send_data;
        packs_sent <= packs_sent + 1;
    end
end


endmodule
