/*
Module name  : memory_slave_4k.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module with memory of the bus
*/
module memory_slave_noip #(
    parameter ADDRESS_WIDTH = 4'd15,
    parameter DATA_WIDTH    = 4'd8,
    parameter SELF_ID       = 3'd0
)(
    input clk, 
    input rstn,
    input rd_wrt,
    input bus_util,
    input arbiter_cmd_in,
    input freeze_slv,
    output wire busy_out,
    output [3:0] state,
    output wire [6:0] disp_out2, 
    output wire [6:0] disp_out1, 
    output wire [6:0] disp_out0,        

    inout data_bus_serial
);

    wire [DATA_WIDTH - 1:0]     slave_to_mem_wire;
    wire [DATA_WIDTH - 1:0]     mem_to_slave_wire;
    wire [ADDRESS_WIDTH -1:0]   addr_out_wire;
    wire                        write_en_internal;
    wire                        req_int_data;

    reg module_dv   = 1'b0;

    
    // reg [ADDRESS_WIDTH -1:0]   addr_buff;

    slave #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SELF_ID(SELF_ID)
    )Slave_inst(
        .clk(clk),
        .rstn(rstn),
        .rd_wrt(rd_wrt),
        .bus_util(bus_util),
        .module_dv(module_dv),
        .data_bus_serial(data_bus_serial),
        .arbiter_cmd_in(arbiter_cmd_in),
        .busy_out(busy_out),
        .data_in_parellel(mem_to_slave_wire),
        .state_out(state),
        .freeze_sw(freeze_slv),
        .write_en_internal(write_en_internal),
        .req_int_data(req_int_data),
        .data_out_parellel(slave_to_mem_wire),
        .addr_buff(addr_out_wire)
    );

    bi2bcd display(
        .din(mem_to_slave_wire),
        .dout2(disp_out2),
        .dout1(disp_out1),
        .dout0(disp_out0)
    );

    ram_noip ram_inst(
        .address(addr_out_wire[ADDRESS_WIDTH-4:0]), //change if the memory size is changed
        .rstn(rstn),
        .clock(clk),
        .data_out(mem_to_slave_wire),
        .wren(write_en_internal),
        .data_in(slave_to_mem_wire)
    );

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            module_dv       <= 1'b0;
        end else begin
            if (req_int_data|write_en_internal)  module_dv <= 1'b1;
            else                                 module_dv <= 1'b0;
        end
    end



endmodule


/*
force -freeze sim:/memory_slave_noip/clk 1 0, 0 {50000 ps} -r 100ns
force -freeze sim:/memory_slave_noip/rstn 1 0
force -freeze sim:/memory_slave_noip/rd_wrt 0 0
force -freeze sim:/memory_slave_noip/bus_util 1 0
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 0 0
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0
run 200ns
force -freeze sim:/memory_slave_noip/rstn 0 0; run 300 ns
force -freeze sim:/memory_slave_noip/rstn 1 0; run 300 ns
force -freeze sim:/memory_slave_noip/rd_wrt 1 0
force -freeze sim:/memory_slave_noip/bus_util 0 0
run 300 ns
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 900ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 300ns;
noforce sim:/memory_slave_noip/data_bus_serial
run 100;
run 100;
run 100;
run 100;
run 100;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
noforce sim:/memory_slave_noip/bus_util
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/bus_util 1 0
noforce sim:/memory_slave_noip/data_bus_serial
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/bus_util 0 0
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;


///read

restart
force -freeze sim:/memory_slave_noip/clk 1 0, 0 {50000 ps} -r 100ns
force -freeze sim:/memory_slave_noip/rstn 1 0
force -freeze sim:/memory_slave_noip/rd_wrt 0 0
force -freeze sim:/memory_slave_noip/bus_util 1 0
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 0 0
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0
run 200ns
force -freeze sim:/memory_slave_noip/rstn 0 0; run 300 ns
force -freeze sim:/memory_slave_noip/rstn 1 0; run 300 ns
force -freeze sim:/memory_slave_noip/rd_wrt 1 0
force -freeze sim:/memory_slave_noip/bus_util 0 0
run 300 ns
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 900ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 300ns;
noforce sim:/memory_slave_noip/data_bus_serial
run 100;
run 100;
run 100;
run 100;
run 100;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 100ns;
noforce sim:/memory_slave_noip/bus_util
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/bus_util 1 0
noforce sim:/memory_slave_noip/data_bus_serial
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/bus_util 0 0
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
force -freeze sim:/memory_slave_noip/rd_wrt 0 0
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 100ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 0 0;run 900ns;
force -freeze sim:/memory_slave_noip/data_bus_serial 1 0;run 300ns;
noforce sim:/memory_slave_noip/data_bus_serial
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 1 0;run 100ns;
force -freeze sim:/memory_slave_noip/arbiter_cmd_in 0 0;run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
run 100ns;
*/