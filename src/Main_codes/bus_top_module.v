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
    master2_hold,
    master4_hold,
    master5_hold,
    master2_ex,
    master4_ex,
    master5_ex,
    master2_RW,
    master4_RW,
    test,
    master5_RW
);
//assign test =slaves[3];
bi2bcd test_2(  // Display Current master's slave
    .din({3'b0,st}), // find a way to find its slave
    .dout2(),
    .dout1(),
    .dout0(hex3)
    );
///////////////////////////////// Parameters ///////////////////////////////
localparam DATA_WIDTH   = 8;
localparam ADDRS_WIDTH  = 15;
localparam TIMEOUT_LEN  = 6; //in bits 4 means 16 clocks
localparam BIT_LENGTH   = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD   = 10; //10ns 
localparam EXAMPLE_DATA = 8'd203;
localparam EXAMPLE_ADDR = 15'd27306;

localparam MSTR2_ADDRS  = {3'd3,12'b0};
localparam MSTR4_ADDRS  = {3'd4,12'd2564};
localparam MSTR5_ADDRS  = {3'd4,12'd1500};

localparam MSTR2_DIN    = 8'd231;
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
input master2_hold;  // SW0
input master4_hold;  // SW2
input master5_hold;  // SW4
input master2_ex;    // Key1
input master4_ex;    // Key2
input master5_ex;    // Key3
input master2_RW;    // SW1
input master4_RW;    // SW3
input master5_RW;    // SW5

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
wire (weak0,strong1)    b_bus_utilizing; // Pulldown
wire                    _10MHz;
wire                    _1Hz;
wire [20:0]             mux_out;
wire                    current_m_bsy_mux_out;

//Bus controller
wire                  [11:0] m_reqs;
wire                  [11:0] m_grants;
wire  (weak0,strong1) [5:0]  slaves; // Pulldown
wire                  [3:0]  mid_current;
//wire [3:0] state;


// Master0 Display master
//-//wire b_request0;


// Master2
wire deb_master2_hold;
wire deb_master2_ex;
wire pul_master2_ex;
wire deb_master2_RW;
wire [DATA_WIDTH-1:0] m_dout2;
wire m_dvalid2;
wire m_master_bsy2;
wire b_request2;
wire [6:0] dout0_m2;
wire [6:0] dout1_m2;
wire [6:0] dout2_m2;
//-//
//-//// Master4
//-//wire deb_master4_hold;
//-//wire deb_master4_ex;
//-//wire pul_master4_ex;
//-//wire deb_master4_RW;
//-//wire [DATA_WIDTH-1:0] m_dout4;
//-//wire m_dvalid4;
//-//wire m_master_bsy4;
//-//wire b_request4;
//-//wire [6:0] dout0_m4;
//-//wire [6:0] dout1_m4;
//-//wire [6:0] dout2_m4;
//-//
//-//// Master5
//-//wire deb_master5_hold;
//-//wire deb_master5_ex;
//-//wire pul_master5_ex;
//-//wire deb_master5_RW;
//-//wire [DATA_WIDTH-1:0] m_dout5;
//-//wire m_dvalid5;
//-//wire m_master_bsy5;
//-//wire b_request5;
//-//wire [6:0] dout0_m5;
//-//wire [6:0] dout1_m5;
//-//wire [6:0] dout2_m5;

// Slave000 0   display slave
//-//wire [6:0] dout0_s0;
//-//wire [6:0] dout1_s0;
//-//wire [6:0] dout2_s0;


// Slave001 1   Interface slave0 (receive)
// Slave010 2   Interface slave1 (tranmit)

// Slave011 3   
wire [6:0] dout0_s3;
wire [6:0] dout1_s3;
wire [6:0] dout2_s3;
//-//
//-//// Slave100 4
//-//wire [6:0] dout0_s4;
//-//wire [6:0] dout1_s4;
//-//wire [6:0] dout2_s4;
//-//
//-//// Slave101 5
//-//wire [6:0] dout0_s5;
//-//wire [6:0] dout1_s5;
//-//wire [6:0] dout2_s5;
//-//


////////////////////////////// Instantiations //////////////////////////////
//wire [5:0] tt;
//assign tt = 6'bZ;
/////// Bus controller
bus_controller Bus_Controller(
    .clk(clk),
    .rstn(deb_rstn),
    .m_reqs(m_reqs),
    .m_grants(m_grants),
    .slaves(slaves),
    .bus_util(b_bus_utilizing),
    .state(st),//.state(state),
    .mid_current(mid_current)
);

////////////////////////////////// Masters ////////////////////////////////

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
    //.state(st2), //remove
    .b_bus_utilizing(b_bus_utilizing)
);
    //wire [3:0] st2; //remove
//-//// Master4
//-//master #(
//-//    .DATA_WIDTH(DATA_WIDTH),
//-//    .ADDRS_WIDTH(ADDRS_WIDTH),
//-//    .TIMEOUT_LEN(TIMEOUT_LEN), //in bits 4 means 16 clocks
//-//    .BIT_LENGTH(BIT_LENGTH)
//-//)
//-//master_4(
//-//    .clk(clk),
//-//    .rstn(deb_rstn),
//-//
//-//    .m_hold(deb_master4_hold),
//-//    .m_execute(pul_master4_ex),
//-//    .m_RW(deb_master4_RW),
//-//    .m_address(MSTR4_ADDRS),
//-//    .m_din(MSTR4_DIN),
//-//    .m_dout(m_dout4),
//-//    .m_dvalid(m_dvalid4),
//-//    .m_master_bsy(m_master_bsy4),
//-//
//-//    .b_grant(m_grants[4]),
//-//    .b_BUS(b_BUS),
//-//    .b_request(b_request4),
//-//    .b_RW(b_RW),
//-//    .b_bus_utilizing(b_bus_utilizing)
//-//);
//-//
//-//// Master5
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

//////////////////////////////////// Slaves ////////////////////////////
//-//
//-//// Slave000 -0
//-//display_module display_slave000(
//-//    .clk(clk), 
//-//    .rstn(deb_rstn),
//-//    .b_grant(m_grants[0]), 
//-//
//-//    .bus_util(b_bus_utilizing),
//-//    .data_bus_serial(b_BUS), 
//-//    .b_RW(b_RW),
//-//    .slave_busy(slaves[0]),
//-//
//-//    .b_request(b_request0),
//-//    .dout0(dout0_s0),
//-//    .dout1(dout1_s0),
//-//    .dout2(dout2_s0)
//-//);
//-////////////////////////////////////////////////////////////////////


// Slave011 -3
memory_slave_4k #(
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

    .data_bus_serial(b_BUS), 
    .slave_busy(slaves[3])
);


// Slave100 -4
//-//memory_slave_4k #(
//-//    .ADDRESS_WIDTH(ADDRS_WIDTH),
//-//    .DATA_WIDTH(DATA_WIDTH),
//-//    .SELF_ID(SLAVE4_ID)
//-//    )
//-//slave_4
//-//(
//-//    .clk(clk), 
//-//    .rstn(deb_rstn),
//-//    .rd_wrt(b_RW),
//-//    .bus_util(b_bus_utilizing),
//-//
//-//    .disp_out2(dout2_s4), 
//-//    .disp_out1(dout1_s4), 
//-//    .disp_out0(dout0_s4),        
//-//
//-//    .data_bus_serial(b_BUS), 
//-//    .slave_busy(slaves[4])
//-//);
//-//
//-//
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

// Slave100 -4


///////////////////////// Debouncers /////////////////////////////
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








////////////////////////////////////// Clocks //////////////////////////////////
// clk_1hz clock_1HZ(
//     .clk_in, 
//     .rst,
//     .clk_1hz_out
// );
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

bi2bcd ssd54(  // Display Current master's slave
    .din({4'b0,mid_current}), // find a way to find its slave
    .dout2(),
    .dout1(hex5),
    .dout0(hex4)
    );

// master data decoding
bi2bcd master_data2(  
    .din(m_dout2), 
    .dout2(dout2_m2),
    .dout1(dout1_m2),
    .dout0(dout0_m2)
    );

//-//bi2bcd master_data4(  
//-//    .din(m_dout4), 
//-//    .dout2(dout2_m4),
//-//    .dout1(dout1_m4),
//-//    .dout0(dout0_m4)
//-//    );
//-//
//-//bi2bcd master_data5(  
//-//    .din(m_dout5), 
//-//    .dout2(dout2_m5),
//-//    .dout1(dout1_m5),
//-//    .dout0(dout0_m5)
//-//    );
//-//
///////////////////////// Muxes ///////////////////
mux_21_8 multiplexer(
    .data0x({dout2_s0,dout1_s0,dout0_s0}), // Slave 0 output 
    .data1x({dout2_s3,dout1_s3,dout0_s3}), // Slave 3 output
    .data2x({dout2_s4,dout1_s4,dout0_s4}), // Slave 4 output
    .data3x({dout2_s5,dout1_s5,dout0_s5}), // Slave 5 output
    .data4x({dout2_m2,dout1_m2,dout0_m2}), // Master 2 data 
    .data5x({dout2_m4,dout1_m4,dout0_m4}), // Master 4 data
    .data6x({dout2_m5,dout1_m5,dout0_m5}), // Master 5 data
    .data7x({dout2_s0,dout1_s0,dout0_s0}), // Slave 0 data
    .sel(mux_switch),
    .result(mux_out)
);

mux_1_1 clk_multiplexer(
    .data0(_10MHz),
    .data1(_1Hz),
    .sel(clk_mux),
    .result(clk)
);

mux_1_16 current_master_bsy_mux(
    .data0(1'b0),    
    .data1(1'b0),
    .data2(m_master_bsy2),
    .data3(1'b0),
    .data4(1'b0),//-//m_master_bsy4),
    .data5(1'b0),//-//m_master_bsy5),
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
assign utilization      = b_bus_utilizing;
assign slave_busy[0]       = slaves[0]?1'b1:1'b0;//slaves[0]?1'b1:1'b0;
assign slave_busy[1]       = slaves[1]?1'b1:1'b0;
assign slave_busy[2]       = slaves[2]?1'b1:1'b0;
assign slave_busy[3]       = slaves[3]?1'b1:1'b0;
assign slave_busy[4]       = slaves[4]?1'b1:1'b0;
assign slave_busy[5]       = slaves[5]?1'b1:1'b0;
assign current_m_bsy    = current_m_bsy_mux_out;// {0,0,0,0,0,0,m_master_bsy5,m_master_bsy4,0,m_master_bsy2,0,0}[mid_current];
assign m_reqs           = {9'b0,b_request2,2'b0};//-//{1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,b_request5,b_request4,1'b0,b_request2,1'b0,b_request0};
assign {hex2,hex1,hex0} = mux_out;//{dout2_s0,dout1_s0,dout0_s0};//?{dout2,dout1,dout0}:{,,};
// reg [20:0]
// always@(mux_switch)
// begin
//     case(mux_switch)
//         3'd0: 
//         3'd1:
//         3'd2:
//         3'd3:
//         3'd4:
//         3'd5:
//         3'd6:
//         3'd7:
//         default:
//     endcase
// end

endmodule