/*
Module name  : memory_slave_4k.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module with memory of the bus
*/
module memory_slave_4k #(
    parameter ADDRESS_WIDTH = 4'd15,
    parameter DATA_WIDTH    = 4'd8,
    parameter SELF_ID       = 3'd0
)(
    input clk, 
    input rstn,
    input rd_wrt,
    input bus_util,
    input arbiter_cmd_in,

    output wire busy_out,
    output wire [6:0] disp_out2, 
    output wire [6:0] disp_out1, 
    output wire [6:0] disp_out0,        

    inout data_bus_serial
);

    wire [DATA_WIDTH - 1:0]     data_in_parellel;
    wire [DATA_WIDTH - 1:0]     data_out_parellel;
    wire [ADDRESS_WIDTH -1:0]   addr_out;
    wire                        write_en_internal;
    wire                        req_int_data;

    reg module_dv   = 1'b0;

    reg [DATA_WIDTH - 1:0]      data_out_buff;

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
        .data_in_parellel(data_out_buff),

        .write_en_internal(write_en_internal),
        .req_int_data(req_int_data),
        .data_out_parellel(data_out_parellel),
        .addr_buff(addr_out)
    );

    bi2bcd display(
        .din(data_in_parellel),
        .dout2(disp_out2),
        .dout1(disp_out1),
        .dout0(disp_out0)
    );

    ram_4k ram_inst(
        .address(addr_out[ADDRESS_WIDTH-4:0]),
        .clock(clk),
        .data(data_out_parellel),
        .wren(write_en_internal),
        .q(data_in_parellel)
    );

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            module_dv       <= 1'b0;
            data_out_buff   <= {DATA_WIDTH{1'b0}};

        end else begin
            if (req_int_data) begin
                data_out_buff   <= data_in_parellel;
                module_dv       <= 1'b1;

            end else module_dv  <= 1'b0;
        end
    end

endmodule