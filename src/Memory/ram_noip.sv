module ram_noip(
    input [11:0] address,
    input [7:0] data_in,
    input wren,
    input clock,
    input rstn,

    output [7:0] data_out
);

    reg [7:0] mem_array [11:0] = '{
        8'd234, 
        8'd12, 
        8'd153, 
        8'd25, 
        8'd55, 
        8'd197, 
        8'd42, 
        8'd1, 
        8'd25, 
        8'd16, 
        8'd11, 
        8'd65};

    always @(posedge clock,negedge rstn) begin
        if (~rstn) begin
            mem_array <= '{8'd234,8'd12,8'd153,8'd25,8'd55,8'd197,8'd42,8'd1,8'd25,8'd16,8'd11,8'd65};
            
        end else begin
            if (wren) mem_array[address] <= data_in;
            
        end
    end

    assign data_out = mem_array[address];
endmodule 