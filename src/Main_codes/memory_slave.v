/*
Module name  : memory_slave.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module with memory of the bus
*/
module memory_slave #(
    parameter MEM_OFFSET = 0,
    parameter MEM_SIZE = 2048,
    parameter ADDRESS_WIDTH = 12
)(
    input clk, rstn,

    output wire [6:0] disp_out2, 
    output wire [6:0] disp_out1, 
    output wire [6:0] disp_out0,        

    inout data_bus_serial, slave_busy
);

    localparam IDLE     = 1'd0;
    localparam MEM_WRT  = 1'd1;

    wire [7:0]                  data_in_parellel;
    wire [7:0]                  data_out_parellel;
    wire [ADDRESS_WIDTH -1:0]   addr_out;
    wire                        write_en_int;

    reg state = IDLE;
    reg module_dv   = 1'b0;

    slave #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(8)
    )Slave_inst(
        .clk(clk),
        .rstn(rstn),
        .rd_wrt(rd_wrt),
        .bus_util(bus_util),
        .module_dv(module_dv),
        .data_bus_serial(data_bus_serial),
        .slave_busy(busy_wire),
        .data_in_parellel(data_in_parellel),

        .write_en_internal(write_en_internal),
        .data_out_parellel(data_out_parellel),
        .addr_buff(addr_out)
    );

    bi2bcd display(
        .din(data_in_parellel),
        .dout2(disp_out2),
        .dout1(disp_out1),
        .dout0(disp_out0)
    );

    ram_2k ram_inst(
        .address(addr_out),
        .clock(clk),
        .data(data_out_parellel),
        .wren(write_en_internal),
        .q(data_in_parellel)
    );

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            state <= IDLE;
            module_dv <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    module_dv <= 1'b0;
                    if (write_en_internal) state <= MEM_WRT;
                end

                MEM_WRT: begin
                    state       <= IDLE;
                    module_dv   <= 1'b1;
                end
            endcase
        end

    end

endmodule

/*force -freeze sim:/memory_slave/Slave_inst/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/memory_slave/Slave_inst/rstn 0 0
force -freeze sim:/memory_slave/Slave_inst/rd_wrt 1 0
run
force -freeze sim:/memory_slave/Slave_inst/rstn St1 0
run
force -freeze sim:/memory_slave/data_bus_serial 0 0
run
run
run
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
run
force -freeze sim:/memory_slave/data_bus_serial St0 0
run
run
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
force -freeze sim:/memory_slave/data_bus_serial St0 0
run
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
force -freeze sim:/memory_slave/data_bus_serial St0 0
run
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
force -freeze sim:/memory_slave/data_bus_serial St0 0
run
run
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
run
noforce sim:/memory_slave/data_bus_serial
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
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
force -freeze sim:/memory_slave/data_bus_serial St0 0
run
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
force -freeze sim:/memory_slave/data_bus_serial St0 0
run
force -freeze sim:/memory_slave/data_bus_serial St1 0
run
force -freeze sim:/memory_slave/data_bus_serial St0 0
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
noforce sim:/memory_slave/data_bus_serial
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
run
run
run
run
run
run
run
*/