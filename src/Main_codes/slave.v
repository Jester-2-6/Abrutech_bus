/*
Module name  : slave.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module of the bus
*/
module slave #(
    parameter MEM_OFFSET = 0,
    parameter MEM_SIZE = 2048,
    parameter ADDRESS_WIDTH = 12,
    parameter DATA_WIDTH = 8,
    parameter SELF_ID = 2'b0
)(
    input clk, rstn, rd_wrt, bus_req,
    input [DATA_WIDTH - 1:0] b_data_in_parellel,

    output reg ready = 1'b0, done = 1'b0, write_en_internal = 1'b0, //make done bidirectional
    output wire [DATA_WIDTH - 1:0] data_out_parellel,
    output wire [ADDRESS_WIDTH -1:0] addr_out,

    inout data_bus_serial, slave_busy
);

    localparam IDLE                = 4'd0;
    localparam MATCH_SID           = 4'd1;
    localparam ADDR_READ           = 4'd2;
    localparam RX_DATA_FROM_MS     = 4'd3;
    localparam BUSY_WRT_TO_MEM     = 4'd4;
    localparam BUSY_RD_FROM_MEM    = 4'd5;
    localparam DATA_READY          = 4'd6;
    localparam TX_DATA_TO_MS       = 4'd7;
    localparam CLEANUP             = 4'd8;

    localparam DATA_WIDTH_LOG = $clog2(DATA_WIDTH);

    wire addr_valid, serial_dv;
    reg data_dir_inv_s2p = 1'b0;
    reg [DATA_WIDTH_LOG - 1:0] read_width = {DATA_WIDTH_LOG{1'b0}};
    reg [3:0] state = IDLE;

    reg [DATA_WIDTH - 1:0] parallel_buff           = {DATA_WIDTH{1'b0}};

    reg [DATA_WIDTH_LOG - 1:0] serial_data_counter = 0;

    serial_parallel_2way #(
        .PORT_WIDTH(ADDRESS_WIDTH)
        .BIT_LENGTH(DATA_WIDTH)
    )ser_des_inst(
        .clk(clk), 
        .rstn(rstn), 
        .dv_in(), 
        .invert_s2p(), 
        .en(),
        .bit_lngt(read_width),
        .dv_out(serial_dv),
        .parallel_port(),
        .serial_port()
    );

    // address range checking
    addr_in_range #(
        .MEM_OFFSET(MEM_OFFSET), 
        .MEM_SIZE(MEM_SIZE)
    )
    range_checker
    (
        .addr_in(addr_in),
        .in_range(addr_valid)
    );

    // tristate buffers
    assign data_bus_serial = serial_out_enable ? serial_out_buff : 1'bZ;

    // assignments
    assign addr_out = addr_in & {ADDRESS_WIDTH{addr_valid}};
    assign data_out_parellel = parellel_out_buff;

    always @(posedge serial_dv) parallel_buff <= 

    // main execution
    always @(posedge clk, negedge rstn) begin
        if (rstn == 1'b0) begin
            //reset logic
            ready                   <= 1'b0;
            done                    <= 1'b0;
            state                   <= IDLE;
            parallel_buff           <= {DATA_WIDTH{1'b0}};
            serial_data_counter     <= {DATA_WIDTH_LOG{1'b0}};
            write_en_internal       <= 1'b0;
            data_dir_inv_s2p        <= 1'b0;

        end else begin
            case (state)
            IDLE: begin
                if (bus_req) begin
                    state <= MATCH_SID;
                    read_width <= 4'd2;
                end
            end

            MATCH_SID: begin
                if (serial_dv) begin
                    if ()
                end
            end
        end

    //     end else begin
    //         case(state)

    //             IDLE: begin
    //             // need util line?
    //                 if (addr_valid & rd_wrt) state <= WRITE_FETCH;
    //                 else if (addr_valid) state <= READ_FETCH;
    //             end

    //             WRITE_FETCH: begin

    //                 parellel_out_buff[serial_data_counter]  <= data_bus_serial;
    //                 serial_data_counter                     <= serial_data_counter + 1;
    //                 // pull up data bus

    //                 if (serial_data_counter == DATA_WIDTH - 1) state <= WRITE_EXEC;
    //             end

    //             WRITE_EXEC: begin
    //                 write_en_internal   <= 1'b1;
    //                 // add done 
    //                 state               <= CLEANUP;  
    //             end

    //             READ_FETCH: begin
    //                 parellel_in_buff    <= data_in_parellel;
    //                 state               <= DATA_READY;
    //             end

    //             DATA_READY: begin
    //                 ready                   <= 1'b1;
    //                 if (addr_valid) state   <= SERIAL_TX;
    //             end

    //             SERIAL_TX: begin
    //                 ready                   <= 1'b0;
    //                 serial_out_enable       <= 1'b1;
    //                 serial_out_buff         <= parellel_in_buff[serial_data_counter];
    //                 serial_data_counter     <= serial_data_counter + 1;

    //                 if (serial_data_counter == DATA_WIDTH - 1) begin
    //                     state <= CLEANUP;
    //                     done <= 1'b1;
    //                 end
    //             end

    //             CLEANUP: begin
    //                 parellel_out_buff       <= {DATA_WIDTH{1'b0}};
    //                 parellel_in_buff        <= {DATA_WIDTH{1'b0}};
    //                 serial_out_buff         <= 1'b0;
    //                 serial_data_counter     <= {DATA_WIDTH_LOG{1'b0}};
    //                 done                    <= 1'b0;
    //                 write_en_internal       <= 1'b0;
    //                 serial_out_enable       <= 1'b0;
    //                 state                   <= IDLE;
    //             end
    //         endcase
    //     end
    // end

endmodule 