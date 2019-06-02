/*
Module name  : memory_slave.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module with memory of the bus
*/
module memory_slave#(
    parameter MEM_OFFSET = 0,
    parameter MEM_SIZE = 2048,
    parameter ADDRESS_WIDTH = 12
)(
    input [ADDRESS_WIDTH - 1:0] addr_in,
    input clk, rstn, write_en,

    output wire ready, done,

    inout data_bus_serial
);

    wire [7:0]                  data_in_parellel;
    wire [7:0]                  data_out_parellel;
    wire [ADDRESS_WIDTH -1:0]   addr_out;
    wire                        write_en_int;

    slave #(
        .MEM_OFFSET(MEM_OFFSET),
        .MEM_SIZE(MEM_SIZE),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(8)
    )Slave_inst(
        .addr_in(addr_in),
        .write_en(write_en),
        .data_in_parellel(data_in_parellel),
        .clk(clk),
        .ready(ready),
        .done(done),
        .rstn(rstn),
        .data_out_parellel(data_out_parellel),
        .addr_out(addr_out),
        .data_bus_serial(data_bus_serial)
    );

    ram_2k ram_inst(
        .address(addr_out),
        .clock(clk),
        .data(data_out_parellel),
        .wren(write_en_int),
        .q(data_in_parellel)
    );

endmodule