module parallel_serial_tb;

    localparam PARALLEL_PORT_WIDTH = 14;
    localparam BIT_LENGTH = 4;

    reg clk = 1'b0, rstn = 1'b0, dv_in = 1'b0;
    reg [PARALLEL_PORT_WIDTH - 1:0] din;
    reg [BIT_LENGTH - 1:0] bit_lngt;

    wire out_wire;

    parallel_serial #(
        .PARALLEL_PORT_WIDTH(PARALLEL_PORT_WIDTH),
        .BIT_LENGTH(BIT_LENGTH)
    ) p2s_inst (
        .clk(clk),
        .rstn(rstn),
        .dv_in(dv_in),
        .din(din),
        .bit_lngt(bit_lngt),
        .dout(out_wire)
    );

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin

        rstn = 1'b0;
        dv_in = 1'b0;
        din = {PARALLEL_PORT_WIDTH{1'b0}};
        bit_lngt = 4'd14;

        #10
        rstn = 1'b1;
        
        #10
        din = 4'd9;
        dv_in = 1'b1;

        #10
        dv_in = 1'b0;

        #200
        din = 4'd12;
        dv_in = 1'b1;

        #10
        dv_in = 1'b0;

    end
endmodule