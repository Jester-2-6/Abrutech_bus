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

    b_util,
    slave_busy,

    b_grant,
    b_request,
    b_RW
);
localparam   PACKET_WIDTH= 10;
localparam   DATA_WIDTH  = 8;
localparam   ADDRS_WIDTH = 15;
localparam   PORT_WIDTH  = 10;
localparam   BIT_LENGTH  = 4;
localparam   TIMEOUT_LEN = 6;

localparam   RX_MODE     = 1'b0;
localparam   TX_MODE     = 1'b1;
localparam   TX_MANUAL   = 1'b0;
localparam   TX_CONVERTER= 1'b1;

localparam   DISPLAY_ADDRESS = 15'd0;

input       clk;
input       rstn;
output      tx;
input       rx;
inout       bus;
inout       b_util;
inout       slave_busy;
input       b_grant;
output      b_request;
inout       b_RW;             // Usually pulldown
output [3:0] slv_state;
output [3:0] mst_state;


reg                     mode        = RX_MODE;
reg                     tx_control  = TX_MANUAL;
reg [4:0]               state;

reg                     m_hold      = 0;
reg                     m_execute   = 0;
reg [DATA_WIDTH-1:0]    m_din       = 0;
wire [DATA_WIDTH-1:0]   m_dout;
wire                    m_dvalid;
wire                    m_busy;

wire                    s_read_req;
wire                    s_out_addr;
wire                    s_out_dv;
wire [DATA_WIDTH - 1:0] s_out_data;
reg                     s_in_dv     = 1;
reg [DATA_WIDTH-1:0]    s_in_data   = 0;

reg                     c_rst_reg   = 0;
wire                    c_rst_wire;
reg                     c_in_dv     = 0;
reg                     c_en_s2p    = 0;
wire                    c_out_dv;
wire                    c_s_tx_done;
reg[PACKET_WIDTH - 1:0] c_p_reg     = 10'd0;
wire[PACKET_WIDTH- 1:0] c_p_wire;
wire                    c_s_wire;

reg                     tx_manual_reg = 1; // TX is normally high

reg [15:0]  baud_size   = BAUD_SIZE;
reg [15:0]  count       = 16'd0;
reg [15:0]   count_20    = 16'd0;
reg         baud_clk    = 16'd0;
wire[15:0]  half_baud_size;


assign c_p_wire         =  mode         ? c_p_reg   : {PACKET_WIDTH{1'bZ}};
assign c_s_wire         =  mode         ? 1'bZ      : rx;
assign tx               =  tx_control   ? c_s_wire  : tx_manual_reg;
assign c_rst_wire       =  c_rst_reg    ? 0         : rstn;

assign half_baud_size   = {1'b0, baud_size[15:1]};


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
    .m_RW(1),
    .m_address(DISPLAY_ADDRESS),
    .m_din(m_din),
    .m_dout(m_dout),
    .m_dvalid(m_dvalid),
    .m_master_bsy(m_busy),

    .b_grant(b_grant),
    .b_BUS(bus),
    .b_request(b_request),
    .b_RW(b_RW),
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
    .slave_busy(slave_busy)
);

serial_parallel_2way#(
    .PORT_WIDTH (PACKET_WIDTH),
    .BIT_LENGTH (BIT_LENGTH)
)
converter(
    .clk(baud_clk), 
    .rstn(c_rst_wire), 
    .dv_in(c_in_dv), 
    .invert_s2p(mode), 
    .en(c_en_s2p),
    .bit_length(PACKET_WIDTH),
    .dv_out(c_out_dv), 
    .serial_tx_done(c_s_tx_done),

    .parallel_port(c_p_wire),
    .serial_port(c_s_wire)
);

// STATES (32 bit)

localparam IDLE             = 5'd0;
localparam RX_1_COUNT       = 5'd1;
localparam RX_2_ACK_1       = 5'd2;
localparam RX_2_ACK_2       = 5'd3;
localparam RX_3_RECEIVE_1   = 5'd4;
localparam RX_3_RECEIVE_2   = 5'd5;
localparam RX_3_RECEIVE_3   = 5'd6;
localparam RX_3_RECEIVE_4   = 5'd7;
localparam RX_4_ACK_1       = 5'd8;
localparam RX_4_ACK_2       = 5'd9;
localparam M_WRITE_1        = 5'd10;
localparam M_WRITE_2        = 5'd11;
localparam M_WRITE_3        = 5'd12;
localparam SLAVE_READ       = 5'd13;
localparam TX_1_START       = 5'd14;
localparam TX_2_ACK_1       = 5'd15;
localparam TX_2_ACK_2       = 5'd16;
localparam TX_3_WASTE       = 5'd17;
localparam TX_4_TRANSMIT_1  = 5'd18;
localparam TX_4_TRANSMIT_2  = 5'd19;
localparam TX_4_TRANSMIT_3  = 5'd20;
localparam TX_4_TRANSMIT_4  = 5'd21;
localparam TX_4_TRANSMIT_5  = 5'd22;
localparam TX_4_TRANSMIT_6  = 5'd23;
localparam TX_4_TRANSMIT_7  = 5'd24;
localparam TX_4_TRANSMIT_8  = 5'd25;
localparam TX_4_TRANSMIT_9  = 5'd26;
localparam TX_5_ACK_1       = 5'd27;
localparam TX_5_ACK_2       = 5'd28;
localparam TX_5_ACK_3       = 5'd29;


always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        state           <= IDLE;
        mode            <= RX_MODE;
        tx_control      <= TX_MANUAL;
        m_hold          <= 0;
        m_execute       <= 0;
        m_din           <= 0;
        s_in_dv         <= 1;
        c_in_dv         <= 0;
        c_en_s2p        <= 0;
        tx_manual_reg   <= 1; // TX is normally high
        baud_size       <= BAUD_SIZE;
        count           <= 16'd0;
        count_20        <= 16'd0;
        baud_clk        <= 16'd0;
    end
    else begin
        case(state)
            IDLE        :   begin
                mode    <=  RX_MODE;
                tx_control      <= TX_MANUAL;
                m_hold          <= 0;
                m_execute       <= 0;
                m_din           <= 0;
                s_in_dv         <= 1;
                c_in_dv         <= 0;
                c_en_s2p        <= 0;
                tx_manual_reg   <= 1; // TX is normally high
                baud_size       <= BAUD_SIZE;
                count           <= 16'd0;
                count_20        <= 16'd0;
                baud_clk        <= 16'd0;
                
                if      (~rx) begin
                    baud_size   <= 16'd1;
                    state       <= RX_1_COUNT;
                end
                else if (s_out_dv)
                    state   <=  SLAVE_READ;
                else
                    state   <=  IDLE;
            end

            RX_1_COUNT  :   begin
                if (~rx) begin
                    baud_size   <= baud_size + 16'd1;
                    state       <= RX_1_COUNT;
                end
                else begin
                    count   <= 16'd0;
                    state   <= RX_2_ACK_1;
                end
            end

            RX_2_ACK_1  :   begin
                tx_control      <=  TX_MANUAL;
                tx_manual_reg   <=  0;
                count           <= count + 16'd1;
                state           <= RX_2_ACK_2;
            end

            RX_2_ACK_2  :   begin
                if (count == baud_size) begin
                    tx_manual_reg   <= 1;
                    count           <= 16'd0;
                    state           <= RX_3_RECEIVE_1;
                end
                else begin
                    count           <= count + 16'd1;
                    state           <= RX_2_ACK_2;
                end
            end

            RX_3_RECEIVE_1: begin
                if (~rx)    begin
                    count           <= 16'd2;
                    state           <= RX_3_RECEIVE_2;
                end
                else
                    state           <= RX_3_RECEIVE_1;
            end

            RX_3_RECEIVE_2: begin

                if (count == baud_size) begin  // start reading
                    count    <= 16'd1;
                    state    <= RX_3_RECEIVE_3;
                end
                else begin
                    count   <= count + 16'd1;
                    state   <= RX_3_RECEIVE_2;
                end
            end

            RX_3_RECEIVE_3: begin

                if (count == half_baud_size) begin
                    c_en_s2p <= 1;
                    baud_clk <= ~baud_clk;
                    count <= 16'd1;
                end
                else
                    count <= count + 16'd1;
                
                if (c_out_dv) begin
                    c_en_s2p <= 0;      // stop reading
                    count    <= 16'd0;
                    state    <= RX_3_RECEIVE_4;
                end
                else
                    state    <= RX_3_RECEIVE_3;
            end

            RX_3_RECEIVE_4: begin
                
                baud_clk     <= ~baud_clk;
                m_din        <= c_p_wire;   // copy data
                m_hold       <= 1;
                count        <= 16'd0;
                state        <= RX_4_ACK_1;
            end

            RX_4_ACK_1  :   begin
                baud_clk        <= ~baud_clk;
                tx_control      <=  TX_MANUAL;
                tx_manual_reg   <=  0;
                count           <= count + 16'd1;
                state           <= RX_4_ACK_2;
            end

            RX_4_ACK_2  :   begin
                baud_clk <= ~baud_clk;

                if (count == baud_size) begin
                    tx_manual_reg   <= 1;
                    count           <= 16'd0;
                    state           <= M_WRITE_1;
                end
                else begin
                    count           <= count + 16'd1;
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
                    baud_clk  <= 0;
                    state     <= IDLE;
                end
                else
                    state   <= M_WRITE_3;
            end

            // Transmission states

            SLAVE_READ  :   begin
                c_p_reg     <= {AD_PREFIX, s_out_data};  // copy data
                count       <= 16'd1;
                tx_control  <= TX_MANUAL;
                tx_manual_reg   <= 0;
                state       <= TX_1_START;
            end

            TX_1_START  :   begin
                if (count == baud_size) begin
                    tx_manual_reg   <= 1;
                    count           <= 0;
                    state           <= TX_2_ACK_1;
                end
                else begin
                    tx_manual_reg <= 0;
                    count         <= count + 16'd1;
                    state         <= TX_1_START;
                end
            end

            TX_2_ACK_1  :   begin           // Ack starts
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
                if (count == baud_size) begin
                    count           <= 0;
                    c_en_s2p        <= 0;
                    mode            <= TX_MODE;
                    tx_control      <= TX_MANUAL;
                    baud_clk        <= 0;
                    c_in_dv         <= 1;
                    
                    state           <= TX_4_TRANSMIT_1;

                end
                else begin
                    count         <= count + 16'd1;
                    state         <= TX_3_WASTE;
                end
            end
            TX_4_TRANSMIT_1:  begin                 // skip half
                if (count == half_baud_size) begin
                    count         <= 0;
                    baud_clk      <= ~baud_clk;
                    state         <= TX_4_TRANSMIT_2;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end
            TX_4_TRANSMIT_2:  begin                 // skip half
                if (count == half_baud_size) begin
                    count         <= 0;
                    baud_clk      <= ~baud_clk;
                    state         <= TX_4_TRANSMIT_3;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end
            TX_4_TRANSMIT_3:  begin                 // skip half
                if (count == half_baud_size) begin
                    count         <= 0;
                    baud_clk      <= ~baud_clk;
                    state         <= TX_4_TRANSMIT_4;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end
            TX_4_TRANSMIT_4:  begin                 // skip half
                if (count == half_baud_size) begin
                    count         <= 0;
                    baud_clk      <= ~baud_clk;
                    state         <= TX_4_TRANSMIT_5;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end
            TX_4_TRANSMIT_5:  begin                 // skip half
                if (count == half_baud_size) begin
                    count         <= 0;
                    baud_clk      <= ~baud_clk;
                    tx_manual_reg <= 0;
                    state         <= TX_4_TRANSMIT_6;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end

            TX_4_TRANSMIT_6:  begin                 // skip one
                if (count == half_baud_size) begin
                    count         <= 0;
                    baud_clk      <= ~baud_clk;
                    state         <= TX_4_TRANSMIT_7;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end
            TX_4_TRANSMIT_7:  begin                 
                if (count == half_baud_size) begin
                    count         <= 0;
                    count_20      <= 0;
                    baud_clk      <= ~baud_clk;
                    tx_manual_reg <= 1;
                    tx_control    <= TX_CONVERTER;
                    state         <= TX_4_TRANSMIT_8;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end                                     // start bit done
            TX_4_TRANSMIT_8:  begin                 // wait for dv to go high
                if (count_20 == 16'd20) begin
                    count_20      <= 16'd0;
                    state         <= TX_4_TRANSMIT_9;
                end
                else
                    state         <= TX_4_TRANSMIT_8;

                if (count == half_baud_size) begin
                    count         <= 0;
                    count_20      <= count_20 + 16'd1;
                    baud_clk      <= ~baud_clk;
                end
                else begin
                    count         <= count + 16'd1;
                end
            end
            TX_4_TRANSMIT_9:  begin
                c_rst_reg     <= 1;    
                baud_clk      <= ~baud_clk;
                mode          <= RX_MODE;
                tx_control    <= TX_MANUAL;
                c_in_dv       <= 0;
                baud_clk      <= 0;
                state         <= TX_5_ACK_1;
                
            end

            TX_5_ACK_1  :   begin           // Ack starts
                c_rst_reg     <= 0;
                baud_clk      <= ~baud_clk;
                if (~rx) begin
                    s_in_dv <= 0;
                    state <= TX_5_ACK_2;
                end
                else
                    state <= TX_5_ACK_1;
            end

            TX_5_ACK_2  :   begin           // Ack ends
                baud_clk      <= ~baud_clk;
                if (rx) begin
                    s_in_dv <= 1;
                    state   <= TX_5_ACK_3;
                end
                else
                    state <= TX_5_ACK_2;
            end

            TX_5_ACK_3  :   begin           // Ack ends
                baud_clk    <= 0;
                state       <= IDLE;
            end







            
                

            default : state <=  IDLE;
        endcase
    end
end



endmodule