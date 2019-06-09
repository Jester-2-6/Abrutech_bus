module disp_slave(
    input clk, 
    input rstn, 
    input bus_util,
    input arbiter_cmd_in,

    inout data_bus_serial,

    output wire busy_out,
    output [6:0] dout0,
    output [6:0] dout1,
    output [6:0] dout2
);

localparam DATA_WIDTH    = 8;
localparam ADDRESS_WIDTH = 15;

wire [DATA_WIDTH - 1:0] data_out_parellel;
wire update_disp;

reg [DATA_WIDTH - 1:0] display_buffer = {DATA_WIDTH{1'b0}};


slave #(
    .ADDRESS_WIDTH(15),
    .DATA_WIDTH(8),
    .SELF_ID(2'b0)
) slave_inst(
    .clk(clk), 
    .rstn(rstn), 
    .rd_wrt(1'b1), 
    .bus_util(bus_util), 
    .module_dv(1'b1),
    .arbiter_cmd_in(),
    .data_in_parellel({DATA_WIDTH{1'b0}}),

    .write_en_internal(update_disp),
    .req_int_data(),//not used (not reading from this slave)
    .data_out_parellel(data_out_parellel),
    .data_bus_serial(data_bus_serial), 
    .arbiter_cmd_in(arbiter_cmd_in),
    .busy_out(busy_out),
);

bi2bcd display(
    .din(display_buffer),
    .dout2(dout0),
    .dout1(dout1),
    .dout0(dout2)
);

always @(posedge update_disp) display_buffer <= data_out_parellel;

endmodule

/*
force -freeze sim:/disp_slave/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/disp_slave/rstn 0 0
run
force -freeze sim:/disp_slave/rstn St1 0
run
force -freeze sim:/disp_slave/rd_wrt 1 0
run
force -freeze sim:/disp_slave/data_bus_serial 0 0
run
run
run
force -freeze sim:/disp_slave/data_bus_serial 1 0
force -freeze sim:/disp_slave/data_bus_serial 0 0
run
force -freeze sim:/disp_slave/data_bus_serial 1 0
run
force -freeze sim:/disp_slave/data_bus_serial 0 0
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
force -freeze sim:/disp_slave/data_bus_serial 1 0
run
force -freeze sim:/disp_slave/data_bus_serial 0 0
run
force -freeze sim:/disp_slave/data_bus_serial 1 0
run
force -freeze sim:/disp_slave/data_bus_serial 0 0
run
run
run
run
run
run
run
run
run
run
run
run
run
run
force -freeze sim:/disp_slave/data_bus_serial 1 0
run
force -freeze sim:/disp_slave/data_bus_serial 0 0
run
force -freeze sim:/disp_slave/data_bus_serial 1 0
run
force -freeze sim:/disp_slave/data_bus_serial 0 0
force -freeze sim:/disp_slave/data_bus_serial 1 0
run
force -freeze sim:/disp_slave/data_bus_serial 0 0
run
force -freeze sim:/disp_slave/data_bus_serial 1 0
run
*/