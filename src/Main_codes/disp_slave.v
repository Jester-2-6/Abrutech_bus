module disp_slave(
    input clk, rstn, bus_util,

    inout data_bus_serial, slave_busy,

    output [6:0] dout0,
    output [6:0] dout1,
    output [6:0] dout2
);

localparam DATA_WIDTH = 8;
localparam ADDRESS_WIDTH = 15;

wire [DATA_WIDTH - 1:0] data_out_parellel;
wire update_disp;

reg [DATA_WIDTH - 1:0] display_buffer;


slave #(
    .ADDRESS_WIDTH(15),
    .DATA_WIDTH(8),
    .SELF_ID(2'b0)
) slave_inst(
    .clk(clk), 
    .rstn(rstn), 
    .rd_wrt(1'b0), 
    .bus_util(bus_util), 
    .module_dv(1'b0),
    .data_in_parellel({DATA_WIDTH{0'b0}}),

    .write_en_internal(update_disp),
    .data_out_parellel(data_out_parellel),
    .data_bus_serial(data_bus_serial), 
    .slave_busy(slave_busy)
);

bi2bcd display(
    .din(display_buffer),
    .dout2(dout0),
    .dout1(dout1),
    .dout0(dout2)
);

always @(posedge update_disp) display_buffer <= data_in_parellel;

endmodule