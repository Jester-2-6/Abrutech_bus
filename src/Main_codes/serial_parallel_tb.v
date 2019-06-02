/*
Module name  : serial_parallel_tb.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Serial to parallel data converter module test bench
*/

module serial_parallel_tb();

parameter PORT_WIDTH    = 14;
parameter EXTRACT_LNGTH = 4;
parameter NB_BITS_TO_EX = 4'd8;
parameter STATE_BW      = 1;
parameter delay         = 10;
parameter data          = 8'd154;

reg                      clk = 1'b0;
reg                      rstn = 1'b1;
reg                      din = 1'b1;
reg  [EXTRACT_LNGTH-1:0] bit_length = 4'd8;
reg                      en = 1'b0;
wire                     dv_out;
wire [PORT_WIDTH-1:0]    dout;
reg  [3:0]               indx = 4'b0;    



serial_parallel #(.PORT_WIDTH(PORT_WIDTH),
                  .EXTRACT_LNGTH(EXTRACT_LNGTH),
                  .STATE_BW(STATE_BW)) 
            DUT(
                .clk(clk),
                .rstn(rstn),
                .din(din),
                .dout(dout),
                .dv_out(dv_out),
                .bit_length(bit_length),
                .en(en)
            );

always
begin
    #delay;
    clk<=~clk;
end

initial
begin
    repeat(3) @(posedge clk);
    #(delay>>2);
    rstn <= 0;
    repeat(3) @(posedge clk);
    #(delay>>2);
    rstn <= 1;
    @(posedge clk);
    din <= 1'b0;
    @(posedge clk);
    en <= 1'b1;
    din <= data[indx];
    indx<= indx+1'b1;
    repeat(7)
    begin
        @(posedge clk);
        din <= data[indx];
        indx<= indx+1'b1;
    end
    @(posedge clk); 
    din <= 1'b1;
    repeat(3) @(posedge clk);
    en<=1'b0;
    repeat(3) @(posedge clk);
end

endmodule