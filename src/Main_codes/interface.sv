/*
Module name  : interface.v
Author 	     : Abarajithan G
Date Modified: 
Organization : ABruTECH
Description  : TX, RX interface
*/

module interface #(
    parameter SLAVE_ID = 3'b001;
)(
    clk,
    rstn,

    tx,
    rx,
    bus,

    b_util,
    slave_busy,

    b_grant,
    b_request,
    b_RW,
);
parameter   PACKET_WIDTH  = 10;
parameter   DATA_WIDTH    = 8;
parameter   ADDRS_WIDTH   = 15;
parameter   PORT_WIDTH    = 10;
parameter   BIT_LENGTH    = 4;
parameter   TIMEOUT_LEN  = 6;

parameter   DISPLAY_ADDRESS = 15'd0;

input       clk;
input       rstn;

output reg  tx;
input       rx;
inout       bus;

inout       b_util;
inout       slave_busy;

input       b_grant;
output reg  b_request = 1'b0;
inout       b_RW;             // Usually pulldown

reg                     m_hold = 0;
reg                     m_execute = 0;
reg [DATA_WIDTH-1:0]    m_din = 0;

wire [DATA_WIDTH-1:0]   m_dout;
wire                    m_dvalid;
wire                    m_busy;

wire                    s_read_req;
wire                    s_out_addr;
wire                    s_out_dv;
wire [DATA_WIDTH - 1:0] s_out_data;

reg                     s_in_dv     = 1;
reg [DATA_WIDTH-1:0]    s_data      = 0;

reg                     c_in_dv;
reg                     c_is_p2s;
reg                     c_en_p2s;
reg[PACKET_WIDTH - 1:0] c_parallel_reg;
wire                    c_serial_reg;
wire                    c_out_dv;
wire                    c_dv_out;
wire                    c_serial_tx_done;
wire[PACKET_WIDTH- 1:0] c_parallel_inout;
wire                    c_serial_inout;

assign c_parallel_inout ?



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
    .m_RW(0),
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
    .PORT_WIDTH = PACKET_WIDTH,
    .BIT_LENGTH = BIT_LENGTH
)
converter(
    .clk(clk), 
    .rstn(rstn), 
    .dv_in(c_in_dv), 
    .invert_s2p(c_is_p2s), 
    .en(c_en_p2s),
    .bit_length(BIT_LENGTH),
    .dv_out(c_dv_out), 
    .serial_tx_done(c_serial_tx_done),

    .parallel_port(),
    .serial_port()
);


endmodule