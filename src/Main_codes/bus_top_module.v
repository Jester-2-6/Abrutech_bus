/*
Module name  : bus_top_module.v
Author 	     : W.M.R.R.Wickramasinghe
Date Modified: 06/06/2019
Organization : ABruTECH
Description  : Top module containig the arbiter,masters and slaves
*/

module bus_top_module(
    rstn,
    in_clk,
    tx0,  //handle
    rx0,  //handle
    tx1,  //handle
    rx1,  //handle
    hex0,
    hex1,
    hex2,
    hex3,
    //hex4,
    //hex5,
    //hex6,
    hex7,
    requests,
    utilization,
    slave_busy,
    current_m_bsy,
    //mux_switch,
    master2_hold,
    master4_hold,
    master5_hold,
    master2_ex,
    master4_ex,
    master5_ex,
    master2_RW,
    master4_RW,
    master5_RW,
);

///////////////////////////////// Parameters ///////////////////////////////
localparam DATA_WIDTH   = 8;
localparam ADDRS_WIDTH  = 15;
localparam TIMEOUT_LEN  = 6; //in bits 4 means 16 clocks
localparam BIT_LENGTH   = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD   = 10; //10ns 
localparam EXAMPLE_DATA = 8'd203;
localparam EXAMPLE_ADDR = 15'd27306;

localparam MSTR2_ADDRS  = 15'b010001100011110;
localparam MSTR4_ADDRS  = 15'b010001100011110;
localparam MSTR5_ADDRS  = 15'b010001100011110;

localparam MSTR2_DIN    = 8'd231;
localparam MSTR4_DIN    = 8'd153;
localparam MSTR5_DIN    = 8'd29;



////////////////////////////// Port declaration ////////////////////////////

input in_clk;
input rstn;
input rx0;
input rx1;
//input mux_switch;
input master2_hold;
input master4_hold;
input master5_hold;
input master2_ex;
input master4_ex;
input master5_ex;
input master2_RW;
input master4_RW;
input master5_RW;


output tx0;
output tx1;
output [6:0] hex0;
output [6:0] hex1;
output [6:0] hex2;
output [6:0] hex3;
// output [6:0] hex4;
// output [6:0] hex5;
//output [6:0] hex6;
output [6:0] hex7;
output [11:0] requests;
output current_m_bsy;
output utilization;
output [5:0] slave_busy;


///////////////////////////// Wires and Regs ///////////////////////////////
// Common
wire                    deb_rstn;
wire                    clk;
wire (strong0,weak1)    b_BUS;           // Pullup
wire (weak0,strong1)    b_RW ;           // Pulldown
wire (weak0,strong1)    b_bus_utilizing; // Pulldown
wire                    _10MHz;

//Bus controller
wire                  [11:0] m_reqs;
wire                  [11:0] m_grants;
wire  (weak0,strong1) [5:0]  slaves;            // Pulldown
wire                  [3:0]  mid_current;
//wire [3:0] state;

// Master2
wire deb_master2_hold;
wire deb_master2_ex;
wire pul_master2_ex;
wire deb_master2_RW;
wire [DATA_WIDTH-1:0] m_dout2;
wire m_dvalid2;
wire m_master_bsy2;
wire b_request2;

// Master4
wire deb_master4_hold;
wire deb_master4_ex;
wire pul_master4_ex;
wire deb_master4_RW;
wire [DATA_WIDTH-1:0] m_dout4;
wire m_dvalid4;
wire m_master_bsy4;
wire b_request4;

// Master5
wire deb_master5_hold;
wire deb_master5_ex;
wire pul_master5_ex;
wire deb_master5_RW;
wire [DATA_WIDTH-1:0] m_dout5;
wire m_dvalid5;
wire m_master_bsy5;
wire b_request5;


////////////////////////////// Instantiations //////////////////////////////

/////// Bus controller
bus_controller Bus_Controller(
    .clk(clk),
    .rstn(deb_rstn),
    .m_reqs(m_reqs),
    .m_grants(m_grants),
    .slaves(slaves),
    .bus_util(b_bus_utilizing),
    .state(),//.state(state),
    .mid_current(mid_current)
);

//////// Masters

// Master2
master #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRS_WIDTH(ADDRS_WIDTH),
    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
    .BIT_LENGTH(BIT_LENGTH)
)
master_2(
    .clk(clk),
    .rstn(deb_rstn),

    .m_hold(deb_master2_hold),
    .m_execute(pul_master2_ex),
    .m_RW(deb_master2_RW),
    .m_address(MSTR2_ADDRS),
    .m_din(MSTR2_DIN),
    .m_dout(m_dout2),
    .m_dvalid(m_dvalid2),
    .m_master_bsy(m_master_bsy2),

    .b_grant(m_grants[2]),
    .b_BUS(b_BUS),
    .b_request(b_request2),
    .b_RW(b_RW),
    .b_bus_utilizing(b_bus_utilizing)
);

// Master4
master #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRS_WIDTH(ADDRS_WIDTH),
    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
    .BIT_LENGTH(BIT_LENGTH)
)
master_4(
    .clk(clk),
    .rstn(deb_rstn),

    .m_hold(deb_master4_hold),
    .m_execute(pul_master4_ex),
    .m_RW(deb_master4_RW),
    .m_address(MSTR4_ADDRS),
    .m_din(MSTR4_DIN),
    .m_dout(m_dout4),
    .m_dvalid(m_dvalid4),
    .m_master_bsy(m_master_bsy4),

    .b_grant(m_grants[4]),
    .b_BUS(b_BUS),
    .b_request(b_request4),
    .b_RW(b_RW),
    .b_bus_utilizing(b_bus_utilizing)
);

// Master5
master #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRS_WIDTH(ADDRS_WIDTH),
    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
    .BIT_LENGTH(BIT_LENGTH)
)
master_5(
    .clk(clk),
    .rstn(deb_rstn),

    .m_hold(deb_master5_hold),
    .m_execute(pul_master5_ex),
    .m_RW(deb_master5_RW),
    .m_address(MSTR5_ADDRS),
    .m_din(MSTR5_DIN),
    .m_dout(m_dout5),
    .m_dvalid(m_dvalid5),
    .m_master_bsy(m_master_bsy5),

    .b_grant(m_grants[5]),
    .b_BUS(b_BUS),
    .b_request(b_request5),
    .b_RW(b_RW),
    .b_bus_utilizing(b_bus_utilizing)
);

///////// Slaves

// Slave000 -0
display_module display_slave000(
    .clk(clk), 
    .rstn(deb_rstn),
    .b_grant(m_grants[0]), 

    .bus_util(b_bus_utilizing),
    .data_bus_serial(b_BUS), 
    .b_RW(b_RW),
    .slave_busy(slaves[0]),

    .b_request(),
    .dout0(dout0),
    .dout1(dout1),
    .dout2(dout2)
);

-----------memory slaves instatiate

// Slave101 -3
slave #(
    .ADDRESS_WIDTH(ADDRS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SELF_ID(SLAVE3_ID)
)
slave_3
(
    .clk(clk), 
    .rstn(deb_rstn), 
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

// Slave100 -4
slave #(
    .ADDRESS_WIDTH(ADDRS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SELF_ID(SLAVE4_ID)
)
slave_4
(
    .clk(clk), 
    .rstn(deb_rstn), 
    .rd_wrt(b_RW), 
    .bus_util(b_bus_utilizing), 
    .module_dv(sm_dv3),
    .data_in_parellel(sm_data3),

    .write_en_internal(sm_write_en_internal3), //make done bidirectional
    .req_int_data(sm_grant_data3),
    .data_out_parellel(sm_data_internal3),
    .addr_buff(sm_address3),

    .data_bus_serial(b_BUS), 
    .slave_busy(slaves[4])
);




// Debouncers
debouncer debounce0(
    .button_in(master2_hold),
    .clk(in_clk),
    .button_out(deb_master2_hold));

debouncer debounce1(
    .button_in(master4_hold),
    .clk(in_clk),
    .button_out(deb_master4_hold));

debouncer debounce2(
    .button_in(master5_hold),
    .clk(in_clk),
    .button_out(deb_master5_hold));

debouncer debounce3(
    .button_in(master2_ex),
    .clk(in_clk),
    .button_out(deb_master2_ex));


debouncer debounce4(
    .button_in(master4_ex),
    .clk(in_clk),
    .button_out(deb_master4_ex));
    
debouncer debounce5(
    .button_in(master5_ex),
    .clk(in_clk),
    .button_out(deb_master5_ex));

debouncer debounce6(
    .button_in(master2_RW),
    .clk(in_clk),
    .button_out(deb_master2_RW));

debouncer debounce7(
    .button_in(master4_RW),
    .clk(in_clk),
    .button_out(deb_master4_RW));


debouncer debounce8(
    .button_in(master5_RW),
    .clk(in_clk),
    .button_out(deb_master5_RW));

// debouncer debounce7(
//     .button_in(),
//     .clk(in_clk),
//     .button_out(deb_));


// debouncer debounce7(
//     .button_in(),
//     .clk(in_clk),
//     .button_out(deb_));




// Pulses

pulse pulse0(
    .din(deb_master2_ex),
    .dout(pul_master2_ex),
    .clk(clk),
    .rstn(deb_rstn)
);

pulse pulse1(
    .din(deb_master4_ex),
    .dout(pul_master4_ex),
    .clk(clk),
    .rstn(deb_rstn)
);

pulse pulse2(
    .din(deb_master5_ex),
    .dout(pul_master5_ex),
    .clk(clk),
    .rstn(deb_rstn)
);

// pulse pulse3(
//     .din(deb_),
//     .dout(pul_),
//     .clk(clk),
//     .rstn(deb_rstn)
// );








// Clocks
// clk_1hz clock_1HZ(
//     .clk_in, 
//     .rst,
//     .clk_1hz_out
// );
//Convert 10MHz clock to 1Hz clock						
						
clock_divider _10MHz_to_1Hz(
			.inclk(_10MHz),
			.ena(1),
			.clk(clk));
			
//Convert 50MHz clock to 10MHz clock	
			
pll _50MHz_to_10MHz(
	.inclk0(in_clk),
.c0(_10MHz));



// Assignments
assign hex7             = {4'b0,mid_current};
assign requests         = m_reqs;
assign utilization      = b_bus_utilizing;
assign slave_busy       = slaves;
assign current_m_bsy    = {0,0,0,0,0,0,m_master_bsy5,m_master_bsy4,0,m_master_bsy2,0,0}[mid_current];
assign m_reqs           = {0,0,0,0,0,0,b_request5,b_request4,0,b_request2,0,0};
assign {hex2,hex1,hex0} = {dout2,dout1,dout0};//?{dout2,dout1,dout0}:{,,};



endmodule