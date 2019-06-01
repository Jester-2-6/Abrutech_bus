/*
Module name  : master.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Master module of the bus
*/

module master(
    clk,
    rstn,
    m_hold,
    m_rd_wrt_idle,
    m_addrs,
    m_din,
    m_dout,
    m_vld,

    b_grntd,
    b_dinout,
    b_slv_rdy,
    b_req,
    b_addrs,
    b_rd_wrt,
    b_bus_utilizing
);

// Parameters
parameter ADDRESS_WIDTH = 14;
parameter DATA_WIDTH    = 8;
parameter INDX_COUNTER  = $ceil($clog2(DATA_WIDTH));

// Module side
input                           clk;
input                           rstn;
input                           m_hold;
input  wire [1:0]               m_rd_wrt_idle;
input  wire [ADDRESS_WIDTH-1:0] m_addrs;
input  wire [DATA_WIDTH-1:0]    m_din;
output reg  [DATA_WIDTH-1:0]    m_dout = {DATA_WIDTH {1'b0}};
output reg                      m_vld = 1'b0;

// Bus Side
input  b_grntd;
inout  b_dinout;
input  b_slv_rdy;
output reg  b_req    = 1'b0;
output wire [ADDRESS_WIDTH-1:0] b_addrs;
output wire  b_rd_wrt;
output wire b_bus_utilizing;


// Registers and internal wires
reg                     bus_utilizing_reg = 1'b0;
reg [DATA_WIDTH-1:0]    byt_reg           = {DATA_WIDTH {1'b0}};
reg [ADDRESS_WIDTH-1:0] address_reg       = {ADDRESS_WIDTH {1'b0}};
reg [INDX_COUNTER-1:0]  indx              = {INDX_COUNTER {1'b0}};
reg                     rd_wrt_reg        = 1'b0;
reg [5:0]               STATE             = 6'd0;



//States
parameter IDLE  = 6'd0;



//Assignments
assign b_addrs  = (b_grntd|bus_utilizing_reg) ? address_reg: {ADDRESS_WIDTH{1'bZ}};
assign b_dinout = (bus_utilizing_reg && rd_wrt_reg) ? byt_reg[indx]: 1'bZ; 
assign b_bus_utilizing = bus_utilizing_reg ? 1'b1: 1'bZ;
assign b_rd_wrt = bus_utilizing_reg ? rd_wrt_reg: 1'bZ;

always@(posedge clk,negedge rstn)
    begin
    if(rstn == 0)
        begin
            //reset the module
            b_req             <= 1'b0;
            m_dout            <= {DATA_WIDTH {1'b0}};
            m_vld             <= 1'b0;
            b_req             <= 1'b0;
            bus_utilizing_reg <= 1'b0;
            byt_reg           <= {DATA_WIDTH {1'b0}};
            address_reg       <= {ADDRESS_WIDTH {1'b0}};
            indx              <= {INDX_COUNTER {1'b0}};
            rd_wrt_reg        <= 1'b0;
            STATE             <= 0;

        end  else  begin
            
        end 
    end
endmodule 