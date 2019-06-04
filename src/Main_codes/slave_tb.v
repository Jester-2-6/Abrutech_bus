module slave_tb();

localparam DATA_WIDTH = 8;
localparam ADDRESS_WIDTH = 15;

reg clk = 1'b0; 
reg rstn = 1'b0; 
reg rd_wrt = 1'b0; 
reg bus_util = 1'b0; 
reg module_dv = 1'b0; 
reg data_bus_serial = 1'b1; 
reg slave_busy = 1'b0;
reg [DATA_WIDTH - 1:0] data_in_parellel = {DATA_WIDTH{1'b0}};

wire write_en_internal;
wire [DATA_WIDTH - 1:0] data_out_parellel;
wire [ADDRESS_WIDTH -1:0] addr_out;

wire serial_wire;
wire busy_wire;

assign serial_wire = data_bus_serial;
assign busy_wire = slave_busy ? 1'b1 : 1'bZ;

slave #(
    .ADDRESS_WIDTH(15),
    .DATA_WIDTH(8),
    .SELF_ID(2'b11)
) slave_inst (
    .clk(clk),
    .rstn(rstn),
    .rd_wrt(rd_wrt),
    .bus_util(bus_util),
    .module_dv(module_dv),
    .data_bus_serial(serial_wire),
    .slave_busy(busy_wire),
    .data_in_parellel(data_in_parellel),

    .write_en_internal(write_en_internal),
    .data_out_parellel(data_out_parellel),
    .addr_buff(addr_out)
);

initial begin
    forever #5 clk = ~clk;
end

initial begin
    #15
    rstn = 1'b1;

    #10
    bus_util = 1'b1;

    #10
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 1;

    #10
    data_bus_serial <= 1;

    #10
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 0;

    #10
    data_bus_serial <= 1;

    #10
    data_bus_serial <= 0;
    bus_util        <= 0;

    #10
    data_bus_serial <= 1'b0;
    data_in_parellel <= 8'd159;

    #10
    data_bus_serial <= 1'b1;

    #300
    module_dv = 1'b1;
    data_bus_serial <= 1'bZ;
    
    #10
    module_dv = 1'b0;

    #20
    slave_busy = 1'b0;

    #10
    slave_busy = 1'b1;

    #10
    slave_busy = 1'b0;

    #100
    data_bus_serial <= 1'b0;
    rd_wrt <= 1;

    #10
    data_bus_serial <= 1'b1;

    #600
    module_dv = 1'b1;

    #10
    module_dv = 1'b0;

end

endmodule