module 2_busses(
    input A_in_clk,       
    input A_rstn,          // Key0
    input A_rx0,
    input A_rx1,
    
    input A_master3_hold,  // SW0
    input A_master4_hold,  // SW2
    input A_master5_hold,  // SW4
    input A_master3_ex,    // Key1
    input A_master4_ex,    // Key2
    input A_master5_ex,    // Key3
    input A_master3_RW,    // SW1
    input A_master4_RW,    // SW3
    input A_master5_RW,    // SW5

    output BUS;
    output tx0;
    output tx1;
    output [11:0] requests;
    output utilization;
    output [5:0] slave_busy;
);





//instances

//Bus1

bus_top_module_without_pll(
    .rstn(),
    .in_clk(),
    .tx0(),  //handle
    .rx0(),  //handle
    .tx1(),  //handle
    .rx1(),  //handle
    .requests(),
    .utilization(),
    .slave_busy(),
    .master3_hold(),
    .master4_hold(),
    .master5_hold(),
    .master3_ex(),
    .master4_ex(),
    .master5_ex(),
    .master3_RW(),
    .master4_RW(),
    .BUS(),
    .master5_RW()
);
endmodule
