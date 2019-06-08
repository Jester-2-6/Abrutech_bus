module ram_noip(
    input [11:0] address,
    input [7:0] data_in,
    input wren,
    input clock,
    input rstn,

    output [7:0] data_out
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

    always @(posedge clock,negedge rstn) begin
        if (~rstn) begin
            mem_array <= '{8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};
            
        end else begin
            if (wren) mem_array[address] <= data_in;
            
        end
    end

    assign data_out = mem_array[address];
endmodule 