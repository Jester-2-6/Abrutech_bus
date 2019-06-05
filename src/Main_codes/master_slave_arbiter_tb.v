/*
Module name  : master_slave_arbiter_tb.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 03/06/2019
Organization : ABruTECH
Description  : Testbench for master,slave,arbiter integration
*/
`timescale 1 ns / 1 ps

module master_slave_arbiter_tb;

// Parameters
localparam DATA_WIDTH   = 8;
localparam ADDRS_WIDTH  = 15;
localparam TIMEOUT_LEN  = 6; //in bits 4 means 16 clocks
localparam BIT_LENGTH   = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD   = 10; //10ns 
localparam EXAMPLE_DATA = 8'd203;
localparam EXAMPLE_ADDR = 15'd21845;

localparam SLAVE0_ID = 3'b101;

//////////////////////////////////////////////////////////////////////

// Port declaration
reg                        clk         = 1'b0;
reg                        rstn        = 1'b1;

//MASTER
// module side
reg                        m_hold      = 1'b0;
reg                        m_execute   =1'b0;
reg                        m_RW        = 1'b0;
reg      [ADDRS_WIDTH-1:0] m_address   = {ADDRS_WIDTH{1'b0}};
reg      [DATA_WIDTH-1:0]  m_din       = {DATA_WIDTH{1'b0}};
wire                       m_dvalid;
wire                       m_master_bsy;
wire     [DATA_WIDTH-1:0]  m_dout;
// BUS side
reg                        b_grant         = 1'b0;
wire    (strong0,weak1)    b_BUS           = 1'b1;  
wire                       b_request;
wire    (weak0,strong1)    b_RW            = 1'b0;  // Usually pulldown
wire    (weak0,strong1)    b_bus_utilizing = 1'b0;  // Usually pulldown

//SLAVE
// module side
reg                      sm_dv = 1'b0;
reg [DATA_WIDTH-1:0]     sm_data = EXAMPLE_DATA-25;
wire                     sm_write_en_internal;
wire [DATA_WIDTH-1:0]    sm_data_internal;
wire [ADDRS_WIDTH-1:0]   sm_address;
wire                     sm_grant_data;
// BUS side
wire   (weak0,strong1)   slv_bsy = 1'b0;

// ARBITER
reg                      arbiter_drive = 1'b0;
reg                      arb_out       = 1'b1;



// General conditions
assign slv_bsy = arbiter_drive?arb_out:1'bZ;

//////////////////////////////////////////////////////////////////////



// Instantiations
// Arbiter

// Masters
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


// Slaves
slave #(
    .ADDRESS_WIDTH(ADDRS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SELF_ID(SLAVE0_ID)
)
slave_0
(
    .clk(clk), 
    .rstn(rstn), 
    .rd_wrt(b_RW), 
    .bus_util(b_bus_utilizing), 
    .module_dv(sm_dv),
    .data_in_parellel(sm_data),

    .write_en_internal(sm_write_en_internal), //make done bidirectional
    .req_int_data(sm_grant_data),
    .data_out_parellel(sm_data_internal),
    .addr_buff(sm_address),

    .data_bus_serial(b_BUS), 
    .slave_busy(slv_bsy)
);





endmodule