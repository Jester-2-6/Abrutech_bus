module slave #(
    parameter mem_offset = 0,
    parameter mem_size = 2048,
    parameter addr_width = 12,
    parameter data_width = 8
)(
    input [addr_width - 1:0] addr_in,
    input clk, rstn, rw_select,
    input [data_width - 1:0] data_in_parellel,

    output ready, done,
    output [data_width - 1:0] data_out_parellel,

    inout data_bus_serial
);

wire addr_valid;

// address range checking
addr_in_range #(
    mem_offset = mem_offset, 
    mem_size = mem_size
)(
    .addr_in(addr_in),
    .in_range(addr_valid)
)

endmodule 