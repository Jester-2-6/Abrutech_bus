module addr_in_range #(
    parameter mem_offset = 0,
    parameter mem_size = 2048,
    parameter addr_width = 12
)(
    input [addr_width - 1:0] addr_in,
    input addr_in,
    output wire in_range
);

    assign in_range = (mem_offset < addr_in) & (addr_in < mem_offset + mem_size); 

endmodule