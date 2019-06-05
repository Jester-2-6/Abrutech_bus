module addr_in_range #(
    parameter MEM_OFFSET = 0,
    parameter MEM_SIZE = 2048,
    parameter ADDR_WIDTH = 12
)(
    input [ADDR_WIDTH - 1:0] addr_in,
    output wire in_range
);

    assign in_range = (MEM_OFFSET < addr_in) & (addr_in < MEM_OFFSET + MEM_SIZE); 

endmodule