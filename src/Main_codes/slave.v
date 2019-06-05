/*
Module name  : slave.v
Author 	     : C.Wimalasuriya
Date Modified: 01/06/2019
Organization : ABruTECH
Description  : Slave module of the bus
*/
module slave #(
    parameter ADDRESS_WIDTH = 15,
    parameter DATA_WIDTH = 8,
    parameter SELF_ID = 2'b0
)(
    input clk, 
    input rstn, 
    input rd_wrt, 
    input bus_util, 
    input module_dv,
    input [DATA_WIDTH - 1:0] data_in_parellel,

    output reg write_en_internal = 1'b0, //make done bidirectional
    output reg [DATA_WIDTH - 1:0] data_out_parellel = {DATA_WIDTH{1'b0}},
    output reg [ADDRESS_WIDTH -1:0] addr_buff              = {ADDRESS_WIDTH{1'b0}},

    inout data_bus_serial, 
    inout slave_busy
);

    localparam IDLE                = 4'd0 ;
    localparam MATCH_SID1          = 4'd1 ;
    localparam MATCH_SID2          = 4'd2 ;
    localparam WAIT_FOR_PEER       = 4'd3 ;
    localparam ADDR_READ           = 4'd4 ;
    localparam ADDR_ACK            = 4'd5 ;
    localparam RX_DATA_FROM_MS     = 4'd6 ;
    localparam TX_DATA_ACK         = 4'd7 ;
    localparam BUSY_WRT_TO_MEM     = 4'd8 ;
    localparam BUSY_RD_FROM_MEM    = 4'd9 ;
    localparam DATA_READY          = 4'd10;
    localparam TX_DATA_TO_MS       = 4'd11;
    localparam CLEANUP             = 4'd12;
    localparam WAIT_TIMEOUT        = 4'd13;

    localparam DATA_WIDTH_LOG = $clog2(DATA_WIDTH);

    wire serial_dv, serial_tx_done;
    wire [ADDRESS_WIDTH - 1:0] parallel_port_wire;

    reg serial_rx_enable        = 1'b0;
    reg serial_tx_start         = 1'b0;
    reg data_dir_inv_s2p        = 1'b0;
    reg slave_busy_reg          = 1'b0;
    reg slave_match_reg         = 1'b0;
    reg ack_counter             = 1'b0;
    reg serial_buff             = 1'bZ;

    reg [DATA_WIDTH - 1:0] read_width               = {DATA_WIDTH{1'b0}};
    reg [3:0] state                                 = IDLE;
    reg [ADDRESS_WIDTH - 1:0] parallel_buff         = {ADDRESS_WIDTH{1'b0}};
    reg [DATA_WIDTH_LOG - 1:0] serial_data_counter  = {DATA_WIDTH_LOG{1'b0}};
    reg [3:0] timeout_counter                       = 4'b0;
    reg [3:0] temp_state_reg                        = 4'b0;

    serial_parallel_2way #(
        .PORT_WIDTH(ADDRESS_WIDTH),
        .BIT_LENGTH(DATA_WIDTH)
    )ser_des_inst(
        .clk(clk), 
        .rstn(rstn), 
        .dv_in(serial_tx_start), 
        .invert_s2p(data_dir_inv_s2p), 
        .en(serial_rx_enable),
        .bit_length(read_width),
        .dv_out(serial_dv),
        .serial_tx_done(serial_tx_done),
        .parallel_port(parallel_port_wire),
        .serial_port(data_bus_serial)
    );

    // tristate buffers
    assign parallel_port_wire = data_dir_inv_s2p ? parallel_buff : {ADDRESS_WIDTH{1'bZ}};
    assign slave_busy = slave_busy_reg ? 1'b1 : 1'bZ;
    assign data_bus_serial = serial_buff;

    // main execution
    always @(posedge clk, negedge rstn) begin
        if (rstn == 1'b0) begin
            //reset logic
            state                   <= IDLE;
            parallel_buff           <= {DATA_WIDTH{1'b0}};
            serial_data_counter     <= {DATA_WIDTH_LOG{1'b0}};
            write_en_internal       <= 1'b0;
            data_dir_inv_s2p        <= 1'b0;
            addr_buff               <= {ADDRESS_WIDTH{1'b0}};
            data_out_parellel       <= {DATA_WIDTH{1'b0}};
            slave_busy_reg          <= 1'b0;
            serial_buff             <= 1'bZ;
            timeout_counter         <= 4'b0;
            temp_state_reg          <= 4'b0;

        end else begin
            case (state)
                IDLE: begin
                    if (~data_bus_serial) begin
                        state                   <= MATCH_SID1;
                        slave_busy_reg          <= 1'b1;
                    end else begin
                        parallel_buff           <= {DATA_WIDTH{1'b0}};
                        serial_data_counter     <= {DATA_WIDTH_LOG{1'b0}};
                        write_en_internal       <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        slave_busy_reg          <= 1'b0;
                        serial_buff             <= 1'bZ;
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                    end
                end

                MATCH_SID1: begin
                    slave_match_reg <= data_bus_serial;
                    state           <= MATCH_SID2;
                end

                MATCH_SID2: begin
                    if ({slave_match_reg, data_bus_serial} == SELF_ID) begin
                        state               <= ADDR_READ;
                        read_width          <= ADDRESS_WIDTH - 2;
                        serial_rx_enable    <= 1'b1;
                    end else state <= WAIT_FOR_PEER;
                end

                WAIT_FOR_PEER: begin
                    if (~bus_util) state <= IDLE;
                end

                ADDR_READ: begin
                    if (serial_dv) begin
                        serial_rx_enable    <= 1'b0;
                        read_width          <= DATA_WIDTH;
                        addr_buff           <= {SELF_ID, parallel_port_wire[ADDRESS_WIDTH - 1:0]};
                        state               <= WAIT_TIMEOUT;
                        temp_state_reg      <= ADDR_ACK;
                    end
                end

                WAIT_TIMEOUT: begin
                    timeout_counter <= timeout_counter + 1'b1;

                    if (timeout_counter[3]) begin
                        state <= temp_state_reg;
                        timeout_counter <= 4'b0;
                    end
                end

                ADDR_ACK:begin
                    case (ack_counter)
                        1'b0: begin
                            serial_buff  <= 1'b0;
                            ack_counter  <= 1'b1;
                        end

                        1'b1: begin 
                            serial_buff  <= 1'b0;
                            ack_counter  <= 1'b0;

                            if (rd_wrt) state       <= RX_DATA_FROM_MS;
                            else begin
                                state               <= BUSY_RD_FROM_MEM;
                                data_dir_inv_s2p    <= 1'b1;
                            end
                        end
                    endcase
                end 

                RX_DATA_FROM_MS: begin
                    serial_rx_enable        <= 1'b1;
                    serial_buff             <= 1'bZ;

                    if (serial_dv) begin
                        serial_rx_enable    <= 1'b0;
                        data_out_parellel   <= parallel_port_wire;
                        state               <= WAIT_TIMEOUT;
                        temp_state_reg      <= TX_DATA_ACK;
                        write_en_internal   <= 1'b1;
                        serial_rx_enable    <= 1'b0;
                    end
                end

                TX_DATA_ACK: begin
                    case (ack_counter)
                        1'b0: begin
                            serial_buff         <= 1'b0;
                            ack_counter         <= 1'b1;
                        end

                        1'b1: begin 
                            serial_buff         <= 1'b1;
                            ack_counter         <= 1'b0;
                            state               <= BUSY_WRT_TO_MEM;
                            serial_rx_enable    <= 1'b0;
                            data_out_parellel   <= parallel_port_wire;
                            write_en_internal   <= 1'b1;
                            serial_rx_enable    <= 1'b0;
                        end
                    endcase
                end

                BUSY_WRT_TO_MEM: begin
                    serial_buff             <= 1'bZ;
                    write_en_internal       <= 1'b0;
                    if (module_dv) state    <= IDLE;
                end

                BUSY_RD_FROM_MEM: begin
                    serial_buff     <= 1'bZ;
                    if (module_dv) begin
                        parallel_buff[ADDRESS_WIDTH - 1:ADDRESS_WIDTH-DATA_WIDTH]   <= data_in_parellel;
                        state           <= DATA_READY;
                        slave_busy_reg  <= 1'b0;
                    end
                end

                DATA_READY: if (slave_busy) begin
                    state                   <= TX_DATA_TO_MS;
                    slave_busy_reg          <= 1'b1;
                    serial_tx_start         <= 1'b1;
                end

                TX_DATA_TO_MS: begin
                    serial_tx_start <= 1'b0;
                    if (serial_tx_done) state <= IDLE;
                end
            endcase
        end
    end
endmodule 

/*
force -freeze sim:/slave/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/slave/rstn 0 0
force -freeze sim:/slave/rd_wrt 0 0
force -freeze sim:/slave/data_bus_serial 1 0
force -freeze sim:/slave/bus_util 0 0
force -freeze sim:/slave/module_dv 0 0
force -freeze sim:/slave/data_in_parellel 0 0
run
force -freeze sim:/slave/rstn St1 0
run
force -freeze sim:/slave/bus_util St1 0
force -freeze sim:/slave/data_bus_serial 0 0
run
force -freeze sim:/slave/bus_util St0 0
run*/