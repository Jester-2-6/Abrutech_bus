/*
Module name  : slave.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module of the bus
*/
module slave #(
    parameter MEM_OFFSET = 0,
    parameter MEM_SIZE = 2048,
    parameter ADDRESS_WIDTH = 12,
    parameter DATA_WIDTH = 8
)(
    input [ADDRESS_WIDTH - 1:0] addr_in,
    input clk, rstn, rw_select,
    input [DATA_WIDTH - 1:0] data_in_parellel,

    output reg ready, done,
    output reg [DATA_WIDTH - 1:0] data_out_parellel,

    inout data_bus_serial
);

wire addr_valid;

// address range checking
addr_in_range #(
    MEM_OFFSET = MEM_OFFSET, 
    MEM_SIZE = MEM_SIZE
)(
    .addr_in(addr_in),
    .in_range(addr_valid)
);

// tristate buffers


// main execution
always @(posedge clk, negedge rstn) begin
    if (rstn == 1'b0) begin
        //reset logic
        ready               <= 1'b0;
        done                <= 1'b0;
        data_out_parellel   <= (DATA_WIDTH{1'b0});
    
    end else begin

    end
end

endmodule 