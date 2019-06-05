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

localparam SLAVE3_ID = 3'b101;

//////////////////////////////////////////////////////////////////////

// Port declaration
reg                        clk         = 1'b0;
reg                        rstn        = 1'b1;

// // Common
// wire [11:0] b_request;

// Arbiter
wire [11:0] m_reqs;
wire [11:0] m_grants;
//wire [5:0]  slaves;   //inout

wire [3:0] state;
wire [3:0] mid_current;



//MASTERS
// module side
reg                        m_hold5      = 1'b0;
reg                        m_execute5   =1'b0;
reg                        m_RW5        = 1'b0;
reg      [ADDRS_WIDTH-1:0] m_address5   = EXAMPLE_ADDR;
reg      [DATA_WIDTH-1:0]  m_din5       = EXAMPLE_DATA;
wire                       m_dvalid5;
wire                       m_master_bsy5;
wire     [DATA_WIDTH-1:0]  m_dout5;
// BUS side
wire    (strong0,weak1)    b_BUS           = 1'b1;  
wire                       b_request5;
wire    (weak0,strong1)    b_RW            = 1'b0;  // Usually pulldown
wire    (weak0,strong1)    b_bus_utilizing = 1'b0;  // Usually pulldown


assign m_reqs = {6'b0,b_request5,5'b0};
//SLAVE
// module side
reg                      sm_dv3 = 1'b0;
reg [DATA_WIDTH-1:0]     sm_data3 = EXAMPLE_DATA-25;
wire                     sm_write_en_internal3;
wire [DATA_WIDTH-1:0]    sm_data_internal3;
wire [ADDRS_WIDTH-1:0]   sm_address3;
wire                     sm_grant_data3;
// BUS side
wire  (weak0,strong1)  [5:0] slaves = 6'b0;





// General conditions


//////////////////////////////////////////////////////////////////////



// Instantiations
// Arbiter
bus_controller bus_cntrlr(
    .clk(clk),
    .rstn(rstn),
    .m_reqs(m_reqs),
    .m_grants(m_grants),
    .slaves(slaves),
    .bus_util(b_bus_utilizing),
    .state(state),
    .mid_current(mid_current)
);

// Masters
master #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRS_WIDTH(ADDRS_WIDTH),
    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
    .BIT_LENGTH(BIT_LENGTH)
)
master_5(
    .clk(clk),
    .rstn(rstn),

    .m_hold(m_hold5),
    .m_execute(m_execute5),
    .m_RW(m_RW5),
    .m_address(m_address5),
    .m_din(m_din5),
    .m_dout(m_dout5),
    .m_dvalid(m_dvalid5),
    .m_master_bsy(m_master_bsy5),

    .b_grant(m_grants[5]),
    .b_BUS(b_BUS),
    .b_request(b_request5),
    .b_RW(b_RW),
    .b_bus_utilizing(b_bus_utilizing)
);


// Slaves
slave #(
    .ADDRESS_WIDTH(ADDRS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SELF_ID(SLAVE3_ID)
)
slave_3
(
    .clk(clk), 
    .rstn(rstn), 
    .rd_wrt(b_RW), 
    .bus_util(b_bus_utilizing), 
    .module_dv(sm_dv3),
    .data_in_parellel(sm_data3),

    .write_en_internal(sm_write_en_internal3), //make done bidirectional
    .req_int_data(sm_grant_data3),
    .data_out_parellel(sm_data_internal3),
    .addr_buff(sm_address3),

    .data_bus_serial(b_BUS), 
    .slave_busy(slaves[3])
);


// Generating clock pulse
always
begin
    clk = ~clk; 
    #(CLK_PERIOD/2);
end


initial
begin
    async_reset;

    @(posedge clk);
    rstn        <= 1'b1;
    m_hold5      <= 1'b0;
    m_execute5   <= 1'b0;
    m_RW5        <= 1'b1;
    m_address5   <= EXAMPLE_ADDR;
    m_din5       <= EXAMPLE_DATA;

    // Write to slave
    @(posedge clk);
    m_hold5 <= 1'b1;
    @(negedge m_master_bsy5);
    @(posedge clk);
    m_execute5 <= 1'b1;
    @(posedge clk);
    m_execute5 <= 1'b0;

    @(posedge(sm_write_en_internal3));
    //done
    @(posedge m_dvalid5);
    @(posedge clk);
    m_hold5 <= 1'b0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    sm_dv3 <= 1'b1;
    @(posedge clk);
    sm_dv3 <= 1'b0;

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

endmodule