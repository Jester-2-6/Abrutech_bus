module clk_1hz(
    input clk_in, rst,
    output reg clk_1hz_out = 1'b0
);

wire clk_1k;
reg [8:0] counter = 9'b0;

clk_div pll_inst(
    .areset(rst),
	.inclk0(clk_in),
	.c0(clk_1k)
);

always @(posedge clk_1k) begin
    counter <= counter + 1'b1;

    if (counter == 9'd50) begin
        clk_1hz_out <= ~clk_1hz_out;
        counter <= 9'b0;
    end
end

endmodule