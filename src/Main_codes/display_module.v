module display_module(
    input clk, 
    input rstn, 

    inout bus_util,
    inout data_bus_serial, 
    inout slave_busy,

    output [6:0] dout0,
    output [6:0] dout1,
    output [6:0] dout2
);

    localparam DATA_WIDTH   = 4'd8;
    localparam ADDRS_WIDTH  = 4'd15;
    localparam TIMEOUT_LEN  = 4'd6; //in bits 4 means 16 clocks
    localparam BIT_LENGTH   = 4'd4; //size of bit_length port 4=> can
    localparam SELF_ID      = 3'd0;

    reg slave_dv        = 1'b0; // ===========> MODIFY THIS <=================
    reg display_buffer  = {DATA_WIDTH{1'b0}};

    // Master instantiation
    master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRS_WIDTH(ADDRS_WIDTH),
        .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
        .BIT_LENGTH(BIT_LENGTH)
    )
    master_0(
        .clk(clk),
        .rstn(rstn),

        .m_hold(m_hold),
        .m_execute(m_execute),
        .m_RW(m_RW),
        .m_address(m_address),
        .m_din(m_din),
        .m_dout(m_dout),
        .m_dvalid(m_dvalid),
        .m_master_bsy(m_master_bsy),

        .b_grant(b_grant),
        .b_BUS(b_BUS),
        .b_request(b_request),
        .b_RW(b_RW),
        .b_bus_utilizing(b_bus_utilizing)
    );

    slave #(
        .ADDRESS_WIDTH(ADDRS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SELF_ID(SELF_ID)
    ) slave_inst(
        .clk(clk), 
        .rstn(rstn), 
        .rd_wrt(1'b0), 
        .bus_util(bus_util), 
        .module_dv(slave_dv),
        .data_in_parellel({DATA_WIDTH{1'b0}}),

        .write_en_internal(update_disp),
        .data_out_parellel(data_out_parellel),
        .data_bus_serial(data_bus_serial), 
        .slave_busy(slave_busy)
    );

    bi2bcd disp (
        .din(display_buffer),
        .dout2(dout0),
        .dout1(dout1),
        .dout0(dout2)
    );

    always @(posedge update_disp) display_buffer <= data_out_parellel;

    always @(negedge rstn, posedge clk) begin
        if (~rstn) begin
            display_buffer <= {DATA_WIDTH{1'b0}}
            slave_dv    <= 1'b0;
        end

        // ===========> BOO CODE HERE <==================

    end



endmodule