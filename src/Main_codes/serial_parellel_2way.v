/*
Module name  : serial_parallel_2way.v
Author 	     : C. Wimalasuriya
Date Modified: 02/06/2019
Organization : ABruTECH
Description  : 2 way parellel serial converter
*/
module seial_parellel_2way#(
    parellel_port_width = 14
)(
    input clk, rstn, dv_in, invert_serial_parellel,
    input [3:0] bit_lngt,
    
    output reg dv_out = 1'b0,

    inout [parellel_port_width - 1:0] parellel_port,
    inout serial_port
);

endmodule