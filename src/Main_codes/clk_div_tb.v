module clk_div_tb(
    input clk_in,

    output [6:0] ss0,
    output [6:0] ss1,
    output [6:0] ss2
);

    reg [7:0] sm_data_internal = 8'b0;
    wire clk_out;

    clock_divider clk_div (
        .inclk(clk_in),
        .ena(1'b1),
        .clk(clk_out)
    );

    bi2bcd display(
        .din(sm_data_internal),
        .dout2(ss2),
        .dout1(ss1),
        .dout0(ss0)
    );

    always @(posedge clk_out) begin
        sm_data_internal <= sm_data_internal + 1;
    end

endmodule