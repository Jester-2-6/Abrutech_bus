/*
Module name  : serial_parallel.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Master module of the bus
*/

module serial_parallel(
    clk,
    rstn,
    din,
    dout,
    dv_out,
    bit_lngth,
    en
);

// Parameters
PORT_WIDTH = 14;
BIT_LENGTH = 4;


// Port declaration
input                        clk;
input                        rstn;
input                        din;
input  wire [BIT_LENGTH-1:0] bit_lngth;
input                        en;
output reg                   dv_out = 1'b0;
output reg [PORT_WIDTH-1:0]  dout;

// Internal registers and wires
reg [] counter = {BIT_LENGTH{1'b0}};

endmodule

/*
if en low dont do anything except reset
*/