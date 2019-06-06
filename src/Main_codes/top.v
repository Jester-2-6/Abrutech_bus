module top(
    ss0,
    ss1,
    ss2,
    clk_high,
    boun_rstn,
    boun_m_hold,
    boun_m_execute,
    m_dvalid,
    boun_b_grant,
    m_master_bsy,
    boun_sm_dv,
	 slv_bsy



);


output [6:0] ss0;
output [6:0] ss1;
output [6:0] ss2;
input clk_high;
input boun_rstn;
input boun_m_hold;
input boun_m_execute;
output m_dvalid;
input boun_b_grant;
output m_master_bsy;
input boun_sm_dv;
output slv_bsy;

//clk_1hz clk_cnvrt(
//    .clk_in(clk_high), 
//    .rst(rstn),
//    .clk_1hz_out(clk)
//);
assign clk = clk_high;


debouncer db0(
    .button_in(boun_rstn),
    .clk(clk_high),
    .button_out(rstn));

debouncer db1(
    .button_in(boun_m_hold),
    .clk(clk_high),
    .button_out(m_hold));

debouncer db2(
    .button_in(~boun_m_execute),
    .clk(clk_high),
    .button_out(m_execute));

debouncer db3(
    .button_in(boun_b_grant),
    .clk(clk_high),
    .button_out(b_grant));

debouncer db4(
    .button_in(~boun_sm_dv),
    .clk(clk_high),
    .button_out(sm_dv));






// Parameters
localparam DATA_WIDTH   = 8;
localparam ADDRS_WIDTH  = 15;
localparam TIMEOUT_LEN  = 6; //in bits 4 means 16 clocks
localparam BIT_LENGTH   = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD   = 10; //10ns 
localparam EXAMPLE_DATA = 8'd203;
localparam EXAMPLE_ADDR = 15'd21845;


// Port declaration



//MASTER
// module side
wire rstn;
wire clk;
wire m_hold;
wire m_execute;
wire b_grant;
wire sm_dv;

reg                        m_RW        = 1'b1;
reg      [ADDRS_WIDTH-1:0] m_address   = EXAMPLE_ADDR;
reg      [DATA_WIDTH-1:0]  m_din       = EXAMPLE_DATA;
wire                       m_dvalid;
wire                       m_master_bsy;
wire     [DATA_WIDTH-1:0]  m_dout;
// BUS side
wire    (strong0,weak1)    b_BUS           ;  
wire                       b_request;
wire    (weak0,strong1)    b_RW            ;  // Usually pulldown
wire    (weak0,strong1)    b_bus_utilizing ;  // Usually pulldown

//SLAVE
// module side

reg [DATA_WIDTH-1:0]     sm_data = EXAMPLE_DATA-8'd25;
wire                     sm_write_en_internal;
wire [DATA_WIDTH-1:0]    sm_data_internal;
wire [ADDRS_WIDTH-1:0]   sm_address;
wire                     sm_grant_data;
// BUS side
wire   (weak0,strong1)   slv_bsy ;

// ARBITER
reg                      arbiter_drive = 1'b0;
reg                      arb_out       = 1'b1;



// General conditions
assign slv_bsy = arbiter_drive?arb_out:1'bZ;

// DUT instantiation

// Master instantiation
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

// Slave instantiation
/*slave #(
    .ADDRESS_WIDTH(ADDRS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SELF_ID(3'b101)
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
);*/

memory_slave #(
    .ADDRESS_WIDTH(ADDRS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SELF_ID(3'b101)
)
slave_0
(
    .clk(clk), 
    .rstn(rstn), 
    .rd_wrt(b_RW), 
    .bus_util(b_bus_utilizing), 

    .disp_out2(ss2),
    .disp_out1(ss1),
    .disp_out0(ss0),

    .data_bus_serial(b_BUS), 
    .slave_busy(slv_bsy)
);


// Display
/*bi2bcd display(
    .din(sm_data_internal),
    .dout2(ss2),
    .dout1(ss1),
    .dout0(ss0)
    );*/

endmodule