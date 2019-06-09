module slave_tb();

localparam DATA_WIDTH = 8;
localparam ADDRESS_WIDTH = 15;

reg clk = 1'b0; 
reg rstn = 1'b0; 
reg rd_wrt = 1'b0; 
reg bus_util = 1'b1; 
reg module_dv = 1'b0; 
reg data_bus_serial = 1'bZ; 
reg arbiter_cmd_in = 1'b0;
reg [DATA_WIDTH - 1:0] data_in_parellel = {DATA_WIDTH{1'b0}};

wire write_en_internal;
wire [DATA_WIDTH - 1:0] data_out_parellel;
wire [ADDRESS_WIDTH -1:0] addr_out;

wire serial_wire;
wire busy_wire;

assign serial_wire = data_bus_serial;

slave #(
    .ADDRESS_WIDTH(15),
    .DATA_WIDTH(8),
    .SELF_ID(3'b110)
) slave_inst (
    .clk(clk),
    .rstn(rstn),
    .rd_wrt(rd_wrt),
    .bus_util(bus_util),
    .module_dv(module_dv),
    .data_bus_serial(serial_wire),
    .arbiter_cmd_in(arbiter_cmd_in),
    .data_in_parellel(data_in_parellel),

    .write_en_internal(write_en_internal),
    .data_out_parellel(data_out_parellel),
    .addr_buff(addr_out),
    .busy_out(busy_wire)
);

initial begin
    forever #5 clk = ~clk;
end

initial begin
    #20
    rstn = 1'b1;

    #10
    bus_util = 1'b0;

    #10
    data_bus_serial <= 0;

    #20
    data_bus_serial <= 1;

    #20
    data_bus_serial <= 0;

    #40
    data_bus_serial <= 1;

    #10
    data_bus_serial <= 0;
    bus_util        <= 1'b1;

    #10
    data_bus_serial <= 1'b0;
    data_in_parellel <= 8'd159;

    #70
    data_bus_serial <= 1'bZ;

    #50
    module_dv = 1'b1;
    
    #10
    module_dv = 1'b0;

    #20
    arbiter_cmd_in = 1'b0;

    #10
    arbiter_cmd_in = 1'b1;

    #10
    arbiter_cmd_in = 1'b0;

    // data write
    #200
    bus_util = 1'b0;
    rd_wrt = 1'b1;

    #10
    data_bus_serial <= 0;

    #20
    data_bus_serial <= 1;

    #20
    data_bus_serial <= 0;

    #40
    data_bus_serial <= 1;

    #10
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 1'b0;

    #10
    data_bus_serial <= 1;

    #30
    data_bus_serial <= 0;

    #30
    data_bus_serial <= 1'bZ;
    bus_util        <= 1'b1;

    #60
    bus_util <= 1'b0;
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 1'b1;

    #10
    data_bus_serial <= 1;

    #30
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 0;

    #20
    data_bus_serial <= 1;

    #10
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 1'bZ;
    bus_util <= 1'b1;

    #40
    module_dv = 1'b1;
    
    #10
    module_dv = 1'b0;

    #10
    arbiter_cmd_in = 1'b1;

    #10
    arbiter_cmd_in = 1'b0;
end

endmodule