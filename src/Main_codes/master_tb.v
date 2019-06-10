/*
Module name  : master_tb.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 04/06/2019
Organization : ABruTECH
Description  : Test bench for Master module of the bus
*/
`timescale 1 ns / 1 ps

module master_tb;


// Parameters
localparam DATA_WIDTH   = 8;
localparam ADDRS_WIDTH  = 15;
localparam TIMEOUT_LEN  = 3; //in bits 4 means 16 clocks
localparam BIT_LENGTH   = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD   = 100; //100ns 
localparam EXAMPLE_DATA = 8'd203;
localparam EXAMPLE_ADDR = 15'd21845;



// Port declaration
reg                        clk         = 1'b0;
reg                        rstn        = 1'b1;
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
reg                        b_grant     = 1'b0;
wire    (strong0,weak1)    b_BUS       = 1'b1;   // Master bus. Have to rout the converter inout
wire                       b_request;
wire                       b_RW;                 // Usually pulldown
wire                       b_bus_utilizing;      // Usually pullup

// To simulate slave side responses
reg                        slave_drive = 1'b0;
reg                        slave_out   = 1'b1;


// General conditions
pullup(b_bus_utilizing);
pulldown(b_RW);
// pullup(b_Bus);
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
    
    .state(),
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

    // resetting
    async_reset;

////////////////////////////////// PURE WRITING A BYTE //////////////////////////////



    @(posedge clk);
    rstn        <= 1'b1;
    m_hold      <= 1'b0;
    m_execute   <= 1'b0;
    m_RW        <= 1'b1;
    m_address   <= EXAMPLE_ADDR+1;
    m_din       <= EXAMPLE_DATA+1;
    b_grant     <= 1'b0;
    slave_drive <= 1'b0;
    slave_out   <= 1'b1;

    @(posedge clk);
    m_hold <= 1'b1;
    @(posedge b_request);
    @(posedge clk);
    b_grant <= 1'b1;
    @(negedge m_master_bsy);
    @(posedge clk);
    m_execute <= 1'b1;
    @(posedge clk);
    m_execute <= 1'b0;

    // // missing 3 tries
    // @(posedge(b_bus_utilizing));
    // @(posedge(b_bus_utilizing));
    // @(negedge(b_request));
    // @(posedge(clk));
    // b_grant <= 1'b0;

    // @(posedge(clk));
    // @(posedge(clk));
    // @(posedge(clk));
    // @(posedge(clk));
    // b_grant <= 1'b1;

    // 4th try

    // sending ack from slave
    // @(posedge(b_bus_utilizing));
    pass_clocks(25);


    @(posedge clk);
    slave_drive <= 1'b1;
    slave_out   <= 1'b0;
    @(posedge clk);
    slave_out   <= 1'b0;
    @(posedge clk);
    slave_drive <= 1'b0;  


    // Data write ack
    pass_clocks(20);

    @(posedge clk);
    slave_drive <= 1'b1;
    slave_out   <= 1'b0;
    @(posedge clk);
    slave_out   <= 1'b1;
    @(posedge clk);
    slave_drive <= 1'b0;  


    //done
    @(posedge m_dvalid);
    @(posedge clk);
    m_hold <= 1'b0;


////////////////////////////////// PURE READING A BYTE //////////////////////////////


    pass_clocks(10);


    rstn        <= 1'b1;
    m_hold      <= 1'b0;
    m_execute   <= 1'b0;
    m_RW        <= 1'b0;
    m_address   <= EXAMPLE_ADDR;
    m_din       <= EXAMPLE_DATA-132;
    b_grant     <= 1'b0;
    slave_drive <= 1'b0;
    slave_out   <= 1'b1;

    @(posedge clk);
    m_hold <= 1'b1;
    @(posedge b_request);
    @(posedge clk);
    b_grant <= 1'b1;
    @(negedge m_master_bsy);
    @(posedge clk);
    m_execute <= 1'b1;
    @(posedge clk);
    m_execute <= 1'b0;

    // @(posedge(b_bus_utilizing));
    // @(posedge(b_bus_utilizing));
    // @(negedge(b_request));
    // @(posedge(clk));
    // b_grant <= 1'b0;

    // @(posedge(clk));
    // @(posedge(clk));
    // @(posedge(clk));
    // @(posedge(clk));
    // b_grant <= 1'b1;

    // sending ack from slave
    // @(posedge(b_bus_utilizing));
    pass_clocks(25);


    @(posedge clk);
    slave_drive <= 1'b1;
    slave_out   <= 1'b0;
    @(posedge clk);
    slave_out   <= 1'b0;
    @(posedge clk);
    slave_drive <= 1'b0;  
    
    @(posedge clk);
    transmit_data(EXAMPLE_DATA-132);

    //done
    @(posedge m_dvalid);
    @(posedge clk);
    m_hold <= 1'b0;



    


    
end

// Task definitions
task async_reset;     
    //input [3:0] load_value;     
    begin//@(negedge clk_50);
        @(posedge clk);
        #(CLK_PERIOD/4);
        rstn      <= 1'b0;
        #(CLK_PERIOD*2);
        rstn      <= 1'b1;   
    end  
endtask 

task pass_clocks;     
    input num_clks;
    integer num_clks;
    
    //input [3:0] load_value;     
    begin: psclk//@(negedge clk_50);
        integer i;
        for( i=0; i<num_clks; i=i+1)
        begin
            @(posedge clk);
        end
    end  
endtask 


// Transmits a single byte from slave side through bus
task transmit_data;     
    input [DATA_WIDTH-1:0] data;
    
    //input [3:0] load_value;     
    begin: data_trnsmit//@(negedge clk_50);
        integer i;
        @(posedge clk);
        slave_drive <= 1'b1; 
        slave_out   <= 1'b0;
        @(posedge clk);
        slave_out   <= 1'b1;
        
        for( i=DATA_WIDTH-1; i>=0; i=i-1)
        begin
            @(posedge clk);
            slave_out <= data[i];
        end
        @(posedge clk);
        slave_drive <= 1'b0;
    end  
endtask 

endmodule