/*
Module name  : serial_parallel_2way.v
Author 	     : C. Wimalasuriya
Date Modified: 02/06/2019
Organization : ABruTECH
Description  : 2 way parallel serial converter
*/
module serial_parallel_2way#(
    parameter PORT_WIDTH = 14,
    parameter BIT_LENGTH = 4
)(
    input clk, rstn, dv_in, invert_s2p, en,
    input [BIT_LENGTH - 1:0] bit_length,
    
    output wire dv_out, serial_tx_done,

    inout [PORT_WIDTH - 1:0] parallel_port,
    inout serial_port
);
    // wire defs
    wire serial_wire;
    wire [PORT_WIDTH - 1:0] parallel_wire;

    // tristate buffers
    assign parallel_port = invert_s2p ? parallel_wire : {PORT_WIDTH{1'bZ}};
    assign serial_port = invert_s2p ? 1'bZ : serial_wire;

    // serial to parallel converter instance
    serial_parallel #(
        .PORT_WIDTH(PORT_WIDTH),
        .EXTRACT_LNGTH(BIT_LENGTH)
    ) s2p_inst(
        .clk(clk),
        .rstn(rstn),
        .din(serial_port),
        .dout(parallel_wire),
        .dv_out(dv_out),
        .bit_length(bit_length),
        .en(en)
    );

    // parallel to serial converter instance
    parallel_serial #(
        .PARALLEL_PORT_WIDTH(PORT_WIDTH),
        .BIT_LENGTH(BIT_LENGTH)
    ) p2s_inst(
        .clk(clk), 
        .rstn(rstn), 
        .dv_in(dv_in),
        .din(parallel_port), 
        .bit_length(bit_length),
        .dout(serial_wire),
        .data_sent(serial_tx_done)
    );

endmodule