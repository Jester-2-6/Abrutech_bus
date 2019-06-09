/*
Module name  : interface.v
Author 	     : Abarajithan G
Date Modified: 
Organization : ABruTECH
Description  : TX, RX interface
*/

module ext_interface #(
    parameter SLAVE_ID = 3'b001,
    parameter BAUD_SIZE= 16'd8,
    parameter AD_PREFIX= 2'b00
)(
    clk,
    rstn,

    tx,
    rx,
    bus,

    slv_state,
    mst_state,
    intrfc_state,
    arbiter_cmd_in,
    busy_out,
    mst_busy,
    

    b_util,

    b_grant,
    b_request,
    b_RW
);
localparam   PACKET_WIDTH= 4'd10;
localparam   DATA_WIDTH  = 8;
localparam   ADDRS_WIDTH = 15;
localparam   PORT_WIDTH  = 10;
localparam   BIT_LENGTH  = 4;
localparam   TIMEOUT_LEN = 6;

localparam   DISPLAY_ADDRESS = 15'b0;//{3'd3,12'd0};//15'd0;----------------------------------------------revert

input       clk;
input       rstn;
output reg  tx      =   1;
input       rx;
inout       bus;
inout       b_util;
input       b_grant;
output      b_request;
inout       b_RW;             // Usually pulldown
input       arbiter_cmd_in;
output      busy_out;
output [3:0] slv_state;
output [3:0] mst_state;
output [4:0] intrfc_state;
output       mst_busy;


reg [4:0]               state;

reg                     m_hold      = 0;
reg                     m_execute   = 0;
reg [DATA_WIDTH-1:0]    m_din       = 0;
wire [DATA_WIDTH-1:0]   m_dout;
wire                    m_dvalid;
wire                    m_busy;

wire                    s_read_req;
wire [ADDRS_WIDTH-1:0]  s_out_addr;
wire                    s_out_dv;
wire [DATA_WIDTH - 1:0] s_out_data;
reg                     s_in_dv     = 1'b0;
reg [DATA_WIDTH-1:0]    s_in_data   = 0;

reg [9:0]   buffer      = 10'd0;

reg [15:0]  baud_size   = BAUD_SIZE;
reg [15:0]  count       = 16'd1;
reg [3:0]   count_0_9   = 4'd10;
wire[15:0]  half_baud_size;
wire        is_half;
wire        is_full;


assign half_baud_size   = {1'b0, baud_size[15:1]};
assign mst_busy         = m_busy;
assign intrfc_state     = state;

assign is_half          = count == half_baud_size;
assign is_full          = count == baud_size;

// Master instantiation
master #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRS_WIDTH(ADDRS_WIDTH),
    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
    .BIT_LENGTH(BIT_LENGTH)
)
master(
    .clk(clk),
    .rstn(rstn),

    .m_hold(m_hold),
    .m_execute(m_execute),
    .m_RW(1'b1),
    .m_address(DISPLAY_ADDRESS),
    .m_din(m_din),
    .m_dout(m_dout),
    .m_dvalid(m_dvalid),
    .m_master_bsy(m_busy),

    .b_grant(b_grant),
    .b_BUS(bus),
    .b_request(b_request),
    .b_RW(b_RW),
    .state(mst_state), 
    .b_bus_utilizing(b_util)
);

slave #(
    .ADDRESS_WIDTH(ADDRS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SELF_ID(SLAVE_ID)
)
slave
(
    .clk(clk), 
    .rstn(rstn), 
    .rd_wrt(b_RW), 
    .bus_util(b_util), 
    .module_dv(s_in_dv),
    .data_in_parellel(s_in_data),

    .write_en_internal(s_out_dv), //make done bidirectional
    .req_int_data(s_read_req),
    .data_out_parellel(s_out_data),
    .addr_buff(s_out_addr),

    .data_bus_serial(bus), 
    .arbiter_cmd_in(arbiter_cmd_in),
    .busy_out(busy_out),
    .state_out(slv_state)
);


// STATES (32 bit)

localparam IDLE             = 5'd0;
localparam RX_1_COUNT       = 5'd1;
localparam RX_2_WASTE       = 5'd2;
localparam RX_2_ACK         = 5'd3;
localparam RX_3_RECEIVE_1   = 5'd4;
localparam RX_3_RECEIVE_2   = 5'd5;
localparam RX_3_RECEIVE_3   = 5'd6;
localparam RX_4_ACK_1       = 5'd7;
localparam RX_4_ACK_2       = 5'd8; 
localparam M_WRITE_1        = 5'd9; 
localparam M_WRITE_2        = 5'd10;
localparam M_WRITE_3        = 5'd11;
localparam SLAVE_READ       = 5'd12;
localparam TX_1_START       = 5'd13;
localparam TX_2_ACK_1       = 5'd14;
localparam TX_2_ACK_2       = 5'd15;
localparam TX_3_WASTE       = 5'd16;
localparam TX_4_TRANSMIT_1  = 5'd17;
localparam TX_4_TRANSMIT_2  = 5'd18;
localparam TX_5_ACK_1       = 5'd19;
localparam TX_5_ACK_2       = 5'd20;
localparam TX_5_ACK_3       = 5'd21;


always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        state           <= IDLE;
        m_hold          <= 0;
        m_execute       <= 0;
        m_din           <= 0;
        s_in_dv         <= 1'b0;
        tx              <= 1; // TX is normally high
        baud_size       <= BAUD_SIZE;
        buffer          <= 10'b0;
        baud_size       <= BAUD_SIZE;
        count           <= 16'd1;
        count_0_9       <= 4'd10;
    end
    else begin

        if (is_full) begin
            count       <= 16'd1;
            count_0_9   <= count_0_9 -  4'd1;
        end
        else
            count       <= count + 1;

        case(state)
            IDLE        :   begin
                m_hold          <= 0;
                m_execute       <= 0;
                m_din           <= 0;
                s_in_dv         <= 1'b0;
                tx              <= 1; // TX is normally high
                baud_size       <= BAUD_SIZE;
                buffer          <= 10'b0;
                count           <= 16'd1;
                count_0_9       <= 4'd10;
                
                if      (~rx) begin
                    baud_size   <= 16'd1;
                    state       <= RX_1_COUNT;          // baud bit recieved
                end
                else if (s_out_dv)
                    state   <=  SLAVE_READ;
                else
                    state   <=  IDLE;
            end

            RX_1_COUNT  :   begin
                if (~rx) begin                          // continue counting
                    baud_size   <= baud_size + 16'd1;
                    state       <= RX_1_COUNT;
                end
                else     begin                          // done counting
                    count       <= 16'd0;
                    state       <= RX_2_WASTE;
                end
            end

            RX_2_WASTE  :   begin
                if (is_full) begin
                    tx          <= 0;                   // start ack bit
                    state       <= RX_2_ACK;
                end
                else begin
                    state       <= RX_2_WASTE;
                end
            end

            RX_2_ACK  :   begin
                if (is_full) begin
                    tx              <= 1;
                    state           <= RX_3_RECEIVE_1;      // end ack bit
                end
                else
                    state           <= RX_2_ACK;      // continue ack bit
                
            end

            RX_3_RECEIVE_1: begin                       // start bit starts
                if (~rx)    begin
                    count           <= 16'd1;
                    state           <= RX_3_RECEIVE_2;
                end
                else
                    state           <= RX_3_RECEIVE_1;
            end

            RX_3_RECEIVE_2: begin

                if (is_half) begin                      // Middle of start bit
                    count           <= 16'd1;
                    count_0_9       <= 4'd10;
                    state           <= RX_3_RECEIVE_3;
                end
                else
                    state           <= RX_3_RECEIVE_2;
                
            end

            RX_3_RECEIVE_3: begin                       // Recieving
                if (count_0_9 == 4'd0) begin
                    count_0_9       <= 4'd1;
                    state           <= RX_4_ACK_1;
                end
                else if (is_full) begin                      // Middle of each bit
                    buffer[count_0_9 - 4'd1]<= rx;
                    state            <= RX_3_RECEIVE_3;
                end
                else
                    state           <= RX_3_RECEIVE_3;
                
            end

            RX_4_ACK_1: begin                       // Wait 1 baud

                if (count_0_9 == 4'd0) begin
                    tx              <= 0;
                    m_din           <= buffer[7:0];
                    m_hold          <= 1;
                    state           <= RX_4_ACK_2;
                end
                else
                    state           <= RX_4_ACK_1;

            end
            
            RX_4_ACK_2  :   begin
                if (is_full) begin
                    tx              <= 1;
                    state           <= M_WRITE_1;
                end
                else begin
                    state           <= RX_4_ACK_2;
                end
            end

            M_WRITE_1   :   begin

                if (~m_busy)
                    state   <=  M_WRITE_2;
                else begin
                    state   <=  M_WRITE_1;
                end
            end

            M_WRITE_2   :   begin
                m_execute   <= 1;
                state       <= M_WRITE_3;
            end

            M_WRITE_3   :   begin
                m_execute   <= 0;

                if (m_dvalid) begin         // Master done writing
                    m_hold    <= 0;
                    baud_size <= BAUD_SIZE;
                    state     <= IDLE;
                end
                else
                    state   <= M_WRITE_3;
            end

            // Transmission states

            SLAVE_READ  :   begin
                buffer     <=  {AD_PREFIX, s_out_data};  // copy data
                count       <= 16'd1;
                tx          <= 0;                   // start the baud bit
                state       <= TX_1_START;
            end

            TX_1_START  :   begin
                if (is_full) begin                  // end the baud bit
                    tx              <= 1;
                    state           <= TX_2_ACK_1;
                end
                else 
                    state           <= TX_1_START;
            end

            TX_2_ACK_1  :   begin           // Ack comes
                if (~rx)
                    state <= TX_2_ACK_2;
                else
                    state <= TX_2_ACK_1;
            end

            TX_2_ACK_2  :   begin           // Ack ends
                if (rx)
                    state <= TX_3_WASTE;
                else
                    state <= TX_2_ACK_2;
            end

            TX_3_WASTE  :   begin
                if (is_full) begin
                    tx              <= 0;           // start the start bit                    
                    count_0_9       <= 4'd9;

                    state           <= TX_4_TRANSMIT_1;
                end
                else 
                    state           <= TX_3_WASTE;
                
            end

            TX_4_TRANSMIT_1: begin                  // Transmission
                if (is_full & (count_0_9 == 4'd0)) begin
                    tx               <= buffer[count_0_9];

                    state            <= TX_4_TRANSMIT_2;
                end
                else if (is_full) begin                  
                    tx               <= buffer[count_0_9];
                    state            <= TX_4_TRANSMIT_1;
                end
                else      
                    state            <= TX_4_TRANSMIT_1;
            end

            TX_4_TRANSMIT_2: begin
                if (is_full) begin
                    tx               <= 1;                  // last bit ends
                    state            <= TX_5_ACK_1;
                end
                else
                    state            <= TX_4_TRANSMIT_2;    // last bit continues
            end

            TX_5_ACK_1  :   begin           // Wait for ack  
                if (~rx) begin              // Ack starts
                    state <= TX_5_ACK_2;
                end
                else
                    state <= TX_5_ACK_1;
            end

            TX_5_ACK_2  :   begin           
                if (rx) begin               // Ack ends, ack to slave begins
                    s_in_dv <= 1'b1;
                    state   <= TX_5_ACK_3;
                end
                else
                    state <= TX_5_ACK_2;
            end

            TX_5_ACK_3  :   begin           // Ack to Slave ends
                s_in_dv     <= 1'b0;
                state       <= IDLE;
            end


            default : state <=  IDLE;
        endcase
    end
end



endmodule