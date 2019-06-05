/*
Module name  : master_tb.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 04/06/2019
Organization : ABruTECH
Description  : Test bench for Master module of the bus
*/

module master_tb;


// Parameters
localparam DATA_WIDTH  = 8;
localparam ADDRS_WIDTH = 15;
localparam TIMEOUT_LEN = 6; //in bits 4 means 16 clocks
localparam BIT_LENGTH  = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD  = 10; //10ns 

`timescale 1 ns / 1 ps


// Port declaration
reg                        clk  = 1'b0;
reg                        rstn = 1'b1;
// module side
reg                        m_hold = 1'b0;
reg                        m_execute =1'b0;
reg                        m_RW = 1'b0;
reg      [ADDRS_WIDTH-1:0] m_address = {ADDRS_WIDTH{1'b0}};
reg      [DATA_WIDTH-1:0]  m_din = {DATA_WIDTH{1'b0}};
wire                       m_dvalid;
wire                       m_master_bsy;
wire     [DATA_WIDTH-1:0]  m_dout;
// BUS side
reg                        b_grant = 1'b0;
wire                       b_BUS;            // Master bus. Have to rout the converter inout
wire                       b_request;
wire                       b_RW;             // Usually pulldown
wire                       b_bus_utilizing;  // Usually pulldown

reg                        slave_drive = 1'b0;
reg                        slave_out   = 1'b1;

// General conditions
pulldown(b_bus_utilizing);
pulldown(b_RW);
pullup(b_Bus);
assign b_BUS = slave_drive?slave_out:1'bZ;

// DUT instantiation
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

// Generating clock pulse
always
begin
    clk = ~clk; 
    #(CLK_PERIOD/2);
end

initial
begin
    #(CLK_PERIOD);
    rstn        <= 1'b1;
    m_hold      <= 1'b0;
    m_execute   <= 1'b0;
    m_RW        <= 1'b1;
    m_address   <= 15'd21845;
    m_din       <= 8'd113;
    b_grant     <= 1'b0;
    slave_drive <= 1'b0;
    slave_out   <= 1'b1;

    // resetting
    #(CLK_PERIOD/4);
    rstn      <= 1'b0;
    #(CLK_PERIOD*2);
    rstn      <= 1'b1;

    @(posedge clk);
    #(CLK_PERIOD*4);

    m_hold <= 1'b1;
    @(posedge b_request);
    @(posedge clk);
    b_grant <= 1'b1;
    @(negedge m_master_bsy);
    m_execute <= 1'b1;
    @(posedge clk);
    m_execute <= 1'b1;

    


    
end

endmodule