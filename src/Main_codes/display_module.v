/*
Module name  : display_module.v
Author 	     : C.Wimalasuriya/W.M.R.R.Wickramasinghe
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave and Master integrated for display module
*/

module display_module(
    input clk, 
    input rstn,
    input b_grant, 

    inout bus_util,
    inout data_bus_serial, 
    inout b_RW,
    input arbiter_cmd_in,

    output busy_out,
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

    //STATES
    
    localparam IDLE         = 2'd0;
    localparam TIMEOUT      = 2'd1;
    localparam SEND         = 2'd2;
    localparam WAIT_FOR_ACK = 2'd3;
    reg [1:0] STATE         = IDLE;
    


    reg slave_dv        = 1'b0; 
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
        .rd_wrt(b_RW), 
        .bus_util(bus_util), 
        .module_dv(slave_dv),
        .data_in_parellel(display_buffer),

        .write_en_internal(update_disp),
        .req_int_data(req_int_data),  // slave asks to send data to bus. grant it using module_dv
        .data_out_parellel(display_buffer),
        .data_bus_serial(data_bus_serial), 
        .arbiter_cmd_in(arbiter_cmd_in),
        .busy_out(busy_out),
        .addr_buff()
    );

    bi2bcd disp (
        .din(display_buffer),
        .dout2(dout2),
        .dout1(dout1),
        .dout0(dout0)
    );


    always@(posedge clk,negedge rstn)
    begin
        if (~rstn) begin
            slave_dv       <= 1'b0;
            display_buffer <= {DATA_WIDTH{1'b0}};
            timer          <= {TIMEOUT_LEN{1'b0}};
            STATE          <= IDLE;
        end else begin
            case(STATE)
                IDLE:
                begin
                    // slave_dv       <= 1'b0;
                    timer          <= {TIMEOUT_LEN{1'b0}};
                    m_hold         <= 1'b0;
                    m_execute      <= 1'b0;
                    if(update_disp)
                    begin
                        slave_dv       <= 1'b0;
                        STATE <= TIMEOUT;
                        display_buffer <= data_out_parallel;
                    end else if(req_int_data) begin 
                        slave_dv       <= 1'b1;
                    end else begin
                        slave_dv       <= 1'b0;
                        STATE <= IDLE;
                    end   
                end

                TIMEOUT:
                begin
                    slave_dv       <= 1'b0;
                    timer          <= timer +1'b1;
                    m_execute      <= 1'b0;
                    if(timer == {TIMEOUT_LEN{1'b1}}) 
                    begin
                        STATE  <= SEND;
                        m_hold <= 1'b1;
                    end else begin
                        STATE          <= TIMEOUT;
                        m_hold         <= 1'b0;
                    end  
                end

                SEND:
                begin
                    slave_dv       <= 1'b0;
                    m_hold         <= 1'b1;
                    if(~m_master_bsy)
                    begin
                        STATE <= WAIT_FOR_ACK;
                        m_execute <= 1'b1;
                    end else begin
                        STATE <= SEND;
                        m_execute      <= 1'b0;
                    end
                end

                WAIT_FOR_ACK:
                begin
                    m_execute      <= 1'b0;
                    timer          <= {TIMEOUT_LEN{1'b0}};
                    if(m_dvalid) 
                    begin
                        m_hold <= 1'b0;
                        slave_dv <= 1'b1;
                        STATE <= IDLE;
                    end else begin
                        STATE <= WAIT_FOR_ACK;
                        slave_dv       <= 1'b0; 
                        m_hold         <= 1'b1;
                    end
                end
                default: STATE <= IDLE;
            endcase
        end
    end



endmodule