module ram_noip(
    input [11:0] addr,
    input [7:0] data_in,
    input wrt_en,
    input clk,

    output reg [7:0] data_out
);

    reg [7:0] mem_array [11:0] = '{
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0, 
        8'b0};

    always @(posedge clk) begin
        if (wrt_en) mem_array[addr] <= data_in;
        else data_out <= mem_array[addr];
    end
endmodule