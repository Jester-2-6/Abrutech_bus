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
    parameter SELF_ID = 3'b0
)(
    input clk, 
    input rstn, 
    input rd_wrt, 
    input bus_util, 
    input module_dv,
    input arbiter_cmd_in,
    input [DATA_WIDTH - 1:0] data_in_parellel,

    output reg write_en_internal                    = 1'b0, //make done bidirectional
    output reg req_int_data                         = 1'b0,
    output reg busy_out                             = 1'b0,
    output reg [DATA_WIDTH - 1:0] data_out_parellel = {DATA_WIDTH{1'b0}},
    output reg [ADDRESS_WIDTH -1:0] addr_buff       = {ADDRESS_WIDTH{1'b0}},

    inout data_bus_serial
);

    localparam IDLE                = 4'd0 ;
    localparam MATCH_SID1          = 4'd1 ;
    localparam MATCH_SID2          = 4'd2 ;
    localparam MATCH_SID3          = 4'd3 ;
    localparam WAIT_FOR_PEER       = 4'd4 ;
    localparam ADDR_READ           = 4'd5 ;
    localparam ADDR_ACK            = 4'd6 ;
    localparam RX_DATA_FROM_MS     = 4'd7 ;
    localparam TX_DATA_ACK         = 4'd8 ;
    localparam BUSY_WRT_TO_MEM     = 4'd9 ;
    localparam BUSY_RD_FROM_MEM    = 4'd10;
    localparam DATA_READY          = 4'd11;
    localparam TX_DATA_TO_MS       = 4'd12;
    localparam CLEANUP             = 4'd13;
    localparam WAIT_TIMEOUT        = 4'd14;
    localparam WAIT_1_CLK          = 4'd15;

    localparam DATA_WIDTH_LOG = $clog2(DATA_WIDTH);

    wire serial_dv, serial_tx_done;
    wire [ADDRESS_WIDTH - 1:0] parallel_port_wire;

    reg serial_rx_enable        = 1'b0;
    reg serial_tx_start         = 1'b0;
    reg data_dir_inv_s2p        = 1'b0;
    reg ack_counter             = 1'b0;
    reg serial_buff             = 1'bZ;

    reg [DATA_WIDTH - 1:0]      read_width       = {DATA_WIDTH{1'b0}};
    reg [3:0]                   state            = IDLE;
    reg [ADDRESS_WIDTH - 1:0]   parallel_buff    = {ADDRESS_WIDTH{1'b0}};
    reg [3:0]                   timeout_counter  = 4'b0;
    reg [3:0]                   temp_state_reg   = 4'b0;
    reg [1:0]                   slave_match_reg  = 2'b0;

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
    assign data_bus_serial = serial_buff;

    // main execution
    always @(posedge clk, negedge rstn) begin
        if (rstn == 1'b0) begin
            //reset logic
            read_width              <= {DATA_WIDTH{1'b0}};
            state                   <= IDLE;
            parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
            data_out_parellel       <= {DATA_WIDTH{1'b0}};
            addr_buff               <= {ADDRESS_WIDTH{1'b0}};
            timeout_counter         <= 4'b0;
            temp_state_reg          <= 4'b0;
            slave_match_reg         <= 2'b0;
            serial_rx_enable        <= 1'b0;
            serial_tx_start         <= 1'b0;
            data_dir_inv_s2p        <= 1'b0;
            ack_counter             <= 1'b0;
            serial_buff             <= 1'bZ;
            write_en_internal       <= 1'b0;
            req_int_data            <= 1'b0;
            busy_out                <= 1'b0;

        end else begin
            case (state)
                IDLE: begin
                    if (~data_bus_serial) begin
                        state                   <= MATCH_SID1;
                        read_width              <= {DATA_WIDTH{1'b0}};
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= 2'b0;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;

                    end else begin
                        // parallel_buff           <= {DATA_WIDTH{1'b0}};
                        // write_en_internal       <= 1'b0;
                        // data_dir_inv_s2p        <= 1'b0;
                        // addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        // data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        // serial_buff             <= 1'bZ;
                        // timeout_counter         <= 4'b0;
                        // temp_state_reg          <= 4'b0;
                        // req_int_data            <= 1'b0;
                        // busy_out                <= 1'b0;

                        //new reg list
                        read_width              <= {DATA_WIDTH{1'b0}};
                        state                   <= IDLE;
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= 2'b0;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end
                end

                MATCH_SID1: begin
                    if (~data_bus_serial) begin
                        state               <= MATCH_SID2;
                        read_width          <= ADDRESS_WIDTH;
                        serial_rx_enable    <= 1'b1;

                        //new reg list
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= 2'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                        
                    end else begin
                        state <= WAIT_FOR_PEER;
                        //new reg list
                        read_width              <= {DATA_WIDTH{1'b0}};
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= 2'b0;
                        serial_rx_enable        <= 1'b1;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end
                end

                MATCH_SID2: begin
                    if (ack_counter == 1'b0) begin 
                        slave_match_reg[1]      <= data_bus_serial;
                        ack_counter             <= 1'b1;
                        //new reg list
                        read_width              <= ADDRESS_WIDTH;
                        state                   <= MATCH_SID2;
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end else begin
                        state                   <= MATCH_SID3;
                        ack_counter             <= 1'b0;
                        slave_match_reg[0]      <= data_bus_serial;
                        //new reg list
                        read_width              <= ADDRESS_WIDTH;
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end
                end

                MATCH_SID3: begin
                    if ({slave_match_reg, data_bus_serial} == SELF_ID) begin
                        state                   <= ADDR_READ;
                        //new reg list
                        read_width              <= ADDRESS_WIDTH;
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= slave_match_reg;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end else begin
                        state                   <= WAIT_FOR_PEER;
                        //new reg list
                        read_width              <= ADDRESS_WIDTH;
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= 2'b0;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end
                end

                WAIT_FOR_PEER: begin
                    if (bus_util) begin
                        state <= IDLE;
                        //new reg list
                        read_width              <= {DATA_WIDTH{1'b0}};
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= 2'b0;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end
                end

                ADDR_READ: begin
                    if (serial_dv) begin
                        serial_rx_enable        <= 1'b0;
                        read_width              <= DATA_WIDTH;
                        addr_buff               <= parallel_port_wire;
                        state                   <= ADDR_ACK;
                        //new reg list
                        parallel_buff           <= {ADDRESS_WIDTH{1'b0}};
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        timeout_counter         <= 4'b0;
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= slave_match_reg
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
                    end
                end

                WAIT_TIMEOUT: begin   
                    if (timeout_counter[3]) begin
                        state <= temp_state_reg;
                        timeout_counter <= 4'b0;
                    end else begin
                        timeout_counter         <= timeout_counter + 1'b1;
                        //new reg list
                        read_width              <= read_width;
                        state                   <= WAIT_TIMEOUT;
                        parallel_buff           <= parallel_buff;
                        data_out_parellel       <= {DATA_WIDTH{1'b0}};
                        addr_buff               <= {ADDRESS_WIDTH{1'b0}};
                        temp_state_reg          <= 4'b0;
                        slave_match_reg         <= slave_match_reg;
                        serial_rx_enable        <= 1'b0;
                        serial_tx_start         <= 1'b0;
                        data_dir_inv_s2p        <= 1'b0;
                        ack_counter             <= 1'b0;
                        serial_buff             <= 1'bZ;
                        write_en_internal       <= 1'b0;
                        req_int_data            <= 1'b0;
                        busy_out                <= 1'b0;
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
                            

                            if (rd_wrt) begin
                                state                   <= RX_DATA_FROM_MS;
                                ack_counter             <= 1'b1;


                            end else begin
                                state                   <= BUSY_RD_FROM_MEM;
                                data_dir_inv_s2p        <= 1'b1;
                                req_int_data            <= 1'b1;
                                busy_out                <= 1'b1;

                            end
                        end
                    endcase
                end 

                RX_DATA_FROM_MS: begin
                    if (serial_buff == 0) begin 
                        serial_buff <= 1'bZ;

                    end else begin
                        ack_counter <= data_bus_serial;

                        if ({ack_counter, data_bus_serial} == 2'b01) begin
                            serial_rx_enable <= 1'b1;

                        end else if (serial_dv) begin
                            serial_rx_enable        <= 1'b0;
                            data_out_parellel       <= parallel_port_wire[ADDRESS_WIDTH - 1: ADDRESS_WIDTH - DATA_WIDTH];
                            state                   <= BUSY_WRT_TO_MEM;
                            ack_counter             <= 1'b0;
                            serial_buff             <= 1'bZ;
                            write_en_internal       <= 1'b1;
                            busy_out                <= 1'b1;

                        end
                    end
                end

                BUSY_WRT_TO_MEM: begin
                    write_en_internal           <= 1'b0;
                    serial_buff                 <= 1'bZ;
                    if (module_dv) begin
                        ack_counter             <= 1'b1;
                        busy_out                <= 1'b0;    

                    end else if ({ack_counter, arbiter_cmd_in} == 2'b11) begin
                        state                   <= TX_DATA_ACK;
                        ack_counter             <= 1'b0;

                    end
                end

                TX_DATA_ACK: begin
                    if (~ack_counter) begin
                        serial_buff             <= 1'b0;   
                        ack_counter             <= 1'b1; 

                    end else if (ack_counter) begin
                        state                   <= IDLE;
                        serial_buff             <= 1'b1;   
                        ack_counter             <= 1'b0; 

                    end
                end

                BUSY_RD_FROM_MEM: begin
                    serial_buff             <= 1'bZ;
                    req_int_data            <= 1'b0;


                    if (module_dv) begin
                        parallel_buff[ADDRESS_WIDTH - 1:ADDRESS_WIDTH-DATA_WIDTH]   <= data_in_parellel;
                        state               <= DATA_READY;
                        busy_out            <= 1'b0;
                    end else begin
                        parallel_buff       <= parallel_buff;
                        state               <= state;
                        busy_out            <= busy_out 
                    end
                end

                DATA_READY: if (arbiter_cmd_in) begin
                    state                   <= TX_DATA_TO_MS;
                    serial_tx_start         <= 1'b1;

                end

                TX_DATA_TO_MS: begin
                    serial_tx_start <= 1'b0;

                    if (serial_tx_done) state <= IDLE;
                    else state <= state;
                end
            endcase
        end
    end
endmodule 
