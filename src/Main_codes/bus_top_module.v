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
    hex4,
    hex5,
    hex6,
    hex7,
    requests,
    utilization,
    slave_busy,
    current_m_bsy,
    mux_switch,
    clk_mux,
    master3_hold,
    master4_hold,
    master5_hold,
    master3_ex,
    master4_ex,
    master5_ex,
    master3_RW,
    master4_RW,
    test,
    BUS,
    master5_RW
);
//assign test = clk;
wire [3:0] st_arb;
wire [3:0] st_ms0;
wire [3:0] st_ms3;
wire [3:0] st_ms4;
wire [3:0] st_ms5;
wire [3:0] st_slv0;
wire [3:0] st_slv3;
wire [3:0] st_slv4;
bi2bcd test_2(  // Display Current master's slave
    .din({4'b0,st_ms4}), // find a way to find its slave
    .dout2(),
    .dout1(),
    .dout0(hex3)
    );

bi2bcd ssd54(  // Display Current master's slave
    .din({4'b0,st_slv3}), // find a way to find its slave
    .dout2(),
    .dout1(hex5),
    .dout0(hex4)
    );
///////////////////////////////// Parameters ///////////////////////////////
localparam DATA_WIDTH   = 8;
localparam ADDRS_WIDTH  = 15;
localparam TIMEOUT_LEN  = 6; //in bits 4 means 16 clocks
localparam BIT_LENGTH   = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD   = 10; //10ns 
// localparam EXAMPLE_DATA = 8'd203;
// localparam EXAMPLE_ADDR = 15'd27306;

localparam MSTR3_ADDRS  = {3'd4,12'd5};
localparam MSTR4_ADDRS  = {3'd3,12'd5};
localparam MSTR5_ADDRS  = {3'd4,12'd3};

localparam MSTR3_DIN    = 8'd231;
localparam MSTR4_DIN    = 8'd153;
localparam MSTR5_DIN    = 8'd29;

localparam SLAVE3_ID    = 3'd3;
localparam SLAVE4_ID    = 3'd4;
localparam SLAVE5_ID    = 3'd5;



////////////////////////////// Port declaration ////////////////////////////

input in_clk;       
input rstn;          // Key0
input rx0;
input rx1;
input [2:0] mux_switch; //SW17 SW16 SW15
input clk_mux;
input master3_hold;  // SW0
input master4_hold;  // SW2
input master5_hold;  // SW4
input master3_ex;    // Key1
input master4_ex;    // Key2
input master5_ex;    // Key3
input master3_RW;    // SW1
input master4_RW;    // SW3
input master5_RW;    // SW5

output BUS;
output test;
output tx0;
output tx1;
output [6:0] hex0;
output [6:0] hex1;
output [6:0] hex2;
output [6:0] hex3;
output [6:0] hex4;
output [6:0] hex5;
output [6:0] hex6;
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
wire (strong0,weak1)    b_bus_utilizing; // Pullup
wire                    _10MHz;
wire                    _1Hz;
wire [20:0]             mux_out;
wire                    current_m_bsy_mux_out;

//Bus controller
wire                  [11:0] m_reqs;
wire                  [11:0] m_grants;
wire                  [5:0]  slave2arbiter;
wire                  [5:0]  arbiter2slave;
wire                  [3:0]  mid_current;
//wire [3:0] state;


// Master0 Display master
wire b_request0;
wire m_master_bsy0;


// Master3
wire deb_master3_hold;
wire deb_master3_ex;
wire pul_master3_ex;
wire deb_master3_RW;
wire [DATA_WIDTH-1:0] m_dout3;
wire m_dvalid2;
wire m_master_bsy3;
wire b_request3;
wire [6:0] dout0_m3;
wire [6:0] dout1_m3;
wire [6:0] dout2_m3;

// Master4
wire deb_master4_hold;
wire deb_master4_ex;
wire pul_master4_ex;
wire deb_master4_RW;
wire [DATA_WIDTH-1:0] m_dout4;
wire m_dvalid4;
wire m_master_bsy4;
wire b_request4;
wire [6:0] dout0_m4;
wire [6:0] dout1_m4;
wire [6:0] dout2_m4;

// Master5
wire deb_master5_hold;
wire deb_master5_ex;
wire pul_master5_ex;
wire deb_master5_RW;
wire [DATA_WIDTH-1:0] m_dout5;
wire m_dvalid5;
wire m_master_bsy5;
wire b_request5;
wire [6:0] dout0_m5;
wire [6:0] dout1_m5;
wire [6:0] dout2_m5;

// Slave000 0   display slave
wire [6:0] dout2_s0;
wire [6:0] dout0_s0;
wire [6:0] dout1_s0;


// Slave001 1   Interface slave0 (receive)
// Slave010 2   Interface slave1 (tranmit)

// Slave011 3   
wire [6:0] dout0_s3;
wire [6:0] dout1_s3;
wire [6:0] dout2_s3;
//-//
// Slave100 4
wire [6:0] dout0_s4;
wire [6:0] dout1_s4;
wire [6:0] dout2_s4;

//-//// Slave101 5
//-//wire [6:0] dout0_s5;
//-//wire [6:0] dout1_s5;
//-//wire [6:0] dout2_s5;
//-//

////////////////// testing purpose ////////////
assign test = clk;

//////////////////////////////////////////////


////////////////////////////// Instantiations //////////////////////////////

/////// Bus controller
bus_controller Bus_Controller(
    .clk(clk),
    .rstn(deb_rstn),
    .m_reqs(m_reqs),
    .m_grants(m_grants),
    .slaves_in(slave2arbiter),
    .slaves_out(arbiter2slave),
    .bus_util(b_bus_utilizing),
    .state(st_arb),//.state(state),
    .mid_current(mid_current)
);


////////////////////////////////// Masters ////////////////////////////////

// Master3
master #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRS_WIDTH(ADDRS_WIDTH),
    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
    .BIT_LENGTH(BIT_LENGTH)
)
master_3(
    .clk(clk),
    .rstn(deb_rstn),

    .m_hold(deb_master3_hold),
    .m_execute(pul_master3_ex),
    .m_RW(deb_master3_RW),
    .m_address(MSTR3_ADDRS),
    .m_din(MSTR3_DIN),
    .m_dout(m_dout2),
    .m_dvalid(m_dvalid3),
    .m_master_bsy(m_master_bsy3),

    .b_grant(m_grants[3]),
    .b_BUS(b_BUS),
    .b_request(b_request3),
    .b_RW(b_RW),
    .state(st_ms3), //remove
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
    .state(st_ms4),
    .b_bus_utilizing(b_bus_utilizing)
);

//-//// Master5
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
    .state(st_ms5),
    .b_bus_utilizing(b_bus_utilizing)
);
//-//master #(
//-//    .DATA_WIDTH(DATA_WIDTH),
//-//    .ADDRS_WIDTH(ADDRS_WIDTH),
//-//    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
//-//    .BIT_LENGTH(BIT_LENGTH)
//-//)
//-//master_5(
//-//    .clk(clk),
//-//    .rstn(deb_rstn),
//-//
//-//    .m_hold(deb_master5_hold),
//-//    .m_execute(pul_master5_ex),
//-//    .m_RW(deb_master5_RW),
//-//    .m_address(MSTR5_ADDRS),
//-//    .m_din(MSTR5_DIN),
//-//    .m_dout(m_dout5),
//-//    .m_dvalid(m_dvalid5),
//-//    .m_master_bsy(m_master_bsy5),
//-//
//-//    .b_grant(m_grants[5]),
//-//    .b_BUS(b_BUS),
//-//    .b_request(b_request5),
//-//    .b_RW(b_RW),
//-//    .b_bus_utilizing(b_bus_utilizing)
//-//);

/////////////////////////////// Slaves ////////////////////////////

// Slave000 -0
display_module display_slave000(
    .clk(clk), 
    .rstn(deb_rstn),
    .b_grant(m_grants[0]), 

    .bus_util(b_bus_utilizing),
    .data_bus_serial(b_BUS), 
    .b_RW(b_RW),
    .arbiter_cmd_in(arbiter2slave[0]),
    .mst_state(st_ms0),
    .slv_state(st_slv0),
    .busy_out(slave2arbiter[0]),

    .m_master_bsy(m_master_bsy0),
    .b_request(b_request0),
    .dout0(dout0_s0),
    .dout1(dout1_s0),
    .dout2(dout2_s0)
);
//////////////////////////////////////////////////////////////////


// Slave011 -3
memory_slave_noip #(
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

    .disp_out2(dout2_s3), 
    .disp_out1(dout1_s3), 
    .disp_out0(dout0_s3), 
    .state(st_slv3),       

    .data_bus_serial(b_BUS), 
    .arbiter_cmd_in(arbiter2slave[3]),
    .busy_out(slave2arbiter[3])
);


// Slave100 -4
memory_slave_noip #(
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

    .disp_out2(dout2_s4), 
    .disp_out1(dout1_s4), 
    .disp_out0(dout0_s4), 
    .state(st_slv4),       

    .data_bus_serial(b_BUS), 
    .arbiter_cmd_in(arbiter2slave[4]),
    .busy_out(slave2arbiter[4])
);


//-//// Slave101 -5
//-//memory_slave_2k #(
//-//    .ADDRESS_WIDTH(ADDRS_WIDTH),
//-//    .DATA_WIDTH(DATA_WIDTH),
//-//    .SELF_ID(SLAVE5_ID)
//-//    )
//-//slave_5
//-//(
//-//    .clk(clk), 
//-//    .rstn(deb_rstn),
//-//    .rd_wrt(b_RW),
//-//    .bus_util(b_bus_utilizing),
//-//
//-//    .disp_out2(dout2_s5), 
//-//    .disp_out1(dout1_s5), 
//-//    .disp_out0(dout0_s5),        
//-//
//-//    .data_bus_serial(b_BUS), 
//-//    .slave_busy(slaves[5])
//-//);

// // Slave101 -3
// slave #(
//     .ADDRESS_WIDTH(ADDRS_WIDTH),
//     .DATA_WIDTH(DATA_WIDTH),
//     .SELF_ID(SLAVE3_ID)
// )
// slave_3
// (
//     .clk(clk), 
//     .rstn(deb_rstn), 
//     .rd_wrt(b_RW), 
//     .bus_util(b_bus_utilizing), 
//     .module_dv(sm_dv3),
//     .data_in_parellel(sm_data3),

//     .write_en_internal(sm_write_en_internal3), //make done bidirectional
//     .req_int_data(sm_grant_data3),
//     .data_out_parellel(sm_data_internal3),
//     .addr_buff(sm_address3),

//     .data_bus_serial(b_BUS), 
//     .slave_busy(slaves[3])
// );



///////////////////////// Debouncers /////////////////////////////
debouncer debounce0(
    .button_in(master3_hold),
    .clk(in_clk),
    .button_out(deb_master3_hold));

debouncer debounce1(
    .button_in(master4_hold),
    .clk(in_clk),
    .button_out(deb_master4_hold));

debouncer debounce2(
    .button_in(master5_hold),
    .clk(in_clk),
    .button_out(deb_master5_hold));

debouncer debounce3(
    .button_in(~master3_ex),
    .clk(in_clk),
    .button_out(deb_master3_ex));


debouncer debounce4(
    .button_in(~master4_ex),
    .clk(in_clk),
    .button_out(deb_master4_ex));
    
debouncer debounce5(
    .button_in(~master5_ex),
    .clk(in_clk),
    .button_out(deb_master5_ex));

debouncer debounce6(
    .button_in(master3_RW),
    .clk(in_clk),
    .button_out(deb_master3_RW));

debouncer debounce7(
    .button_in(master4_RW),
    .clk(in_clk),
    .button_out(deb_master4_RW));


debouncer debounce8(
    .button_in(master5_RW),
    .clk(in_clk),
    .button_out(deb_master5_RW));

debouncer debounce9(
    .button_in(rstn),
    .clk(in_clk),
    .button_out(deb_rstn));


// debouncer debounce7(
//     .button_in(),
//     .clk(in_clk),
//     .button_out(deb_));




//////////////////////////// Pulses ////////////////////////////

pulse pulse0(
    .din(deb_master3_ex),
    .dout(pul_master3_ex),
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








////////////////////////////////////// Clocks //////////////////////////////////
 
//Convert 10MHz clock to 1Hz clock						
						
clock_divider _10MHz_to_1Hz(
			.inclk(_10MHz),
			.ena(1),
			.clk(_1Hz));
			
//Convert 50MHz clock to 10MHz clock	
			
pll _50MHz_to_10MHz(
	.inclk0(in_clk),
.c0(_10MHz));


// SSDisplays
bi2bcd ssd76(  // Display Current master
    .din({4'b0,mid_current}),
    .dout2(),
    .dout1(hex7),
    .dout0(hex6)
    );

// bi2bcd ssd54(  // Display Current master's slave
//     .din({4'b0,mid_current}), // find a way to find its slave
//     .dout2(),
//     .dout1(hex5),
//     .dout0(hex4)
//     );

// master data decoding
bi2bcd master_data3(  
    .din(m_dout3), 
    .dout2(dout2_m3),
    .dout1(dout1_m3),
    .dout0(dout0_m3)
    );

bi2bcd master_data4(  
    .din(m_dout4), 
    .dout2(dout2_m4),
    .dout1(dout1_m4),
    .dout0(dout0_m4)
    );

bi2bcd master_data5(  
    .din(m_dout5), 
    .dout2(dout2_m5),
    .dout1(dout1_m5),
    .dout0(dout0_m5)
    );

///////////////////////// Muxes ///////////////////

// To rout 3 digit SS Display to slave's/master's written data
mux_21_8 multiplexer(
    .data0x({dout2_s0,dout1_s0,dout0_s0}), // Slave 0 output 000
    .data1x({dout2_s3,dout1_s3,dout0_s3}), // Slave 3 output 001
    .data2x({dout2_s4,dout1_s4,dout0_s4}), // Slave 4 output 010
    .data3x({dout2_s5,dout1_s5,dout0_s5}), // Slave 5 output 011
    .data4x({dout2_m3,dout1_m3,dout0_m3}), // Master 3 data  100
    .data5x({dout2_m4,dout1_m4,dout0_m4}), // Master 4 data  101
    .data6x({dout2_m5,dout1_m5,dout0_m5}), // Master 5 data  110
    .data7x({dout2_s0,dout1_s0,dout0_s0}), // Slave 0 data   111
    .sel(mux_switch),
    .result(mux_out)
);


// To rout the clock between 1Hz and 10MHz
mux_1_1 clk_multiplexer(
    .data0(_10MHz),
    .data1(_1Hz),
    .sel(clk_mux),
    .result(clk)
);

// To mux the busy status of the current master
mux_1_16 current_master_bsy_mux(
    .data0(m_master_bsy0),//-//m_master_bsy0),    
    .data1(1'b0),
    .data2(1'b0),
    .data3(m_master_bsy3),
    .data4(m_master_bsy4),
    .data5(m_master_bsy5),
    .data6(1'b0),
    .data7(1'b0),
    .data8(1'b0),
    .data9(1'b0),
    .data10(1'b0),
    .data11(1'b0),
    .data12(1'b0),
    .data13(1'b0),
    .data14(1'b0),
    .data15(1'b0),
    .sel(mid_current),
    .result(current_m_bsy_mux_out)
);



///////////////////////////////////////// Assignments //////////////////////////////////
assign requests         = m_reqs;
assign utilization      = ~b_bus_utilizing;
assign BUS              = b_BUS;



// Assigning 0 to free ports .comment connected slaves

// assign slave2arbiter[0] =1'b0;
assign slave2arbiter[1] =1'b0;
assign slave2arbiter[2] =1'b0;
// assign slave2arbiter[3] =1'b0;
// assign slave2arbiter[4] =1'b0;
assign slave2arbiter[5] =1'b0;

// Connected masters
assign m_reqs[0]  = b_request0 ;  // b_request0;    // Master0
assign m_reqs[1]  = 1'b0       ;  // b_request1;    // Master1
assign m_reqs[2]  = 1'b0       ;  // b_request3;    // Master2
assign m_reqs[3]  = b_request3 ;  // b_request3;    // Master3
assign m_reqs[4]  = b_request4 ;  // b_request4;    // Master4
assign m_reqs[5]  = b_request5 ;  // b_request5;    // Master5
assign m_reqs[6]  = 1'b0       ;  // b_request6;    // Master6
assign m_reqs[7]  = 1'b0       ;  // b_request7;    // Master7
assign m_reqs[8]  = 1'b0       ;  // b_request8;    // Master8
assign m_reqs[9]  = 1'b0       ;  // b_request9;    // Master9
assign m_reqs[10] = 1'b0       ;  // b_request10;   // Master10
assign m_reqs[11] = 1'b0       ;  // b_request11;   // Master11



assign slave_busy = slave2arbiter|arbiter2slave;
assign current_m_bsy    = current_m_bsy_mux_out;
assign {hex2,hex1,hex0} = mux_out;


endmodule