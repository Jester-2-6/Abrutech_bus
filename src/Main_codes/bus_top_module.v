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
    tx0,
    rx0,
    tx1,
    rx1,
    hex0,
    hex1,
    hex2,
    hex3,
    hex4,
    hex6,
    hex7,
    requests,
    utilization,
    slave_busy,
    mux_switch
    master2_req,
    master4_req,
    master5_req,
);

///////////////////////////////// Parameters ///////////////////////////////
localparam DATA_WIDTH   = 8;
localparam ADDRS_WIDTH  = 15;
localparam TIMEOUT_LEN  = 6; //in bits 4 means 16 clocks
localparam BIT_LENGTH   = 4; //size of bit_length port 4=> can
localparam CLK_PERIOD   = 10; //10ns 
localparam EXAMPLE_DATA = 8'd203;
localparam EXAMPLE_ADDR = 15'd27306;



////////////////////////////// Port declaration ////////////////////////////

input in_clk;
input rstn;
input rx0;
input rx1;
input [] mux_switch;
input master2_req;
input master4_req;
input master5_req;


output tx0;
output tx1;
output [6:0] hex0;
output [6:0] hex1;
output [6:0] hex2;
output [6:0] hex3;
output [6:0] hex4;
output [6:0] hex6;
output [6:0] hex7;
output [11:0] requests;
output utilization;
output [5:0] slave_busy;

////////////////////////////// Instantiations //////////////////////////////

/////// Bus controller
bus_controller Bus_Controller(
    .clk(clk),
    .rstn(deb_rstn),
    .m_reqs(m_reqs),
    .m_grants(m_grants),
    .slaves(slaves),
    .bus_util(b_bus_utilizing),
    .state(state),
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

///////// Slaves

// Slave000 -0
display_module(
    .clk(clk), 
    .rstn(deb_rstn),
    .b_grant(m_grants[0]), 

    .bus_util(b_bus_utilizing),
    .data_bus_serial(b_BUS), 
    .b_RW(b_RW),
    .slave_busy(slaves[0]),

    .b_request(),
    .dout0(),
    .dout1(),//mux
    .dout2()
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
debouncer debounce(
    .button_in(),
    .clk(clk),
    .button_out(deb_));


// Pulses

pulse pulse0(
    .din(deb_),
    .dout(pul_),
    .clk(clk),
    .rstn(deb_rstn)
);



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
assign hex7 <= {4'b0,mid_current};



endmodule