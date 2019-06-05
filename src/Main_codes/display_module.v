module display_module(
    input clk, 
    input rstn,
    input b_grant, 

    inout bus_util,
    inout data_bus_serial, 
    inout b_RW,
    inout slave_busy,

    output b_request,
    output [6:0] dout0,
    output [6:0] dout1,
    output [6:0] dout2
);

    localparam DATA_WIDTH   = 4'd8;
    localparam ADDRS_WIDTH  = 4'd15;
    localparam TIMEOUT_LEN  = 4'd6; //in bits 4 means 16 clocks
    localparam BIT_LENGTH   = 4'd4; //size of bit_length port 4=> can
    localparam SELF_ID      = 3'd0;
    localparam INTERFACE1_ADD = {3'b010,12'b0};  // The data will be sent to this port

    reg slave_dv        = 1'b0; // ===========> MODIFY THIS <=================
    reg [DATA_WIDTH-1:0] display_buffer = {DATA_WIDTH{1'b0}};
    reg [TIMEOUT_LEN-1:0] timer  = {TIMEOUT_LEN{1'b0}};

    reg m_hold    = 1'b0;
    reg m_execute = 1'b0;

    wire m_dvalid;
    wire m_master_bsy;


    //Slave wires
    wire data_out_parallel;

    // Master instantiation
    master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRS_WIDTH(ADDRS_WIDTH),
        .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
        .BIT_LENGTH(BIT_LENGTH)
    )
    master_display(
        .clk(clk),
        .rstn(rstn),

        .m_hold(m_hold),
        .m_execute(m_execute),
        .m_RW(1'b1),
        .m_address(INTERFACE1_ADD),
        .m_din(display_buffer+1'b1),
        .m_dout(),
        .m_dvalid(m_dvalid),
        .m_master_bsy(m_master_bsy),

        .b_grant(b_grant),
        .b_BUS(data_bus_serial),
        .b_request(b_request),
        .b_RW(b_RW),
        .b_bus_utilizing(bus_util)
    );

    slave #(
        .ADDRESS_WIDTH(ADDRS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SELF_ID(SELF_ID)
    ) slave_display(
        .clk(clk), 
        .rstn(rstn), 
        .rd_wrt(1'b0), 
        .bus_util(bus_util), 
        .module_dv(slave_dv),
        .data_in_parellel(display_buffer),

        .write_en_internal(update_disp),
        .data_out_parellel(data_out_parallel),
        .data_bus_serial(data_bus_serial), 
        .slave_busy(slave_busy)
    );

    bi2bcd disp (
        .din(display_buffer),
        .dout2(dout2),
        .dout1(dout1),
        .dout0(dout0)
    );

    always @(posedge update_disp) display_buffer <= data_out_parallel;

    always @(negedge rstn, posedge clk) begin
        if (~rstn) begin
            display_buffer <= {DATA_WIDTH{1'b0}}
            slave_dv    <= 1'b0;
        end

    end

        // ===========> BOO CODE HERE <==================
    always@(posedge clk,negedge rstn)
    begin
        if (~rstn) begin
            slave_dv       <= 1'b0; // ===========> MODIFY THIS <=================
            display_buffer <= {DATA_WIDTH{1'b0}};
            timer  <= {TIMEOUT_LEN{1'b0}};
        end else begin
            
        end
    end



endmodule