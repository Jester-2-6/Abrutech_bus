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
    input clk, rstn, rd_wrt, bus_req, module_dv,
    input [DATA_WIDTH - 1:0] data_in_parellel,

    output reg write_en_internal = 1'b0, //make done bidirectional
    output reg [DATA_WIDTH - 1:0] data_out_parellel,
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

    wire addr_valid, serial_dv, serial_tx_done;
    wire [ADDRESS_WIDTH - 1:0] parallel_port_wire;

    reg serial_rx_start = 1'b0;
    reg serial_tx_start = 1'b0;
    reg data_dir_inv_s2p = 1'b0;
    reg slave_busy_reg = 1'bZ;

    reg [DATA_WIDTH_LOG - 1:0] read_width           = {DATA_WIDTH_LOG{1'b0}};
    reg [3:0] state                                 = IDLE;
    reg [ADDRESS_WIDTH -1:0] addr_buff               = {ADDRESS_WIDTH{1'b0}};
    reg [ADDRESS_WIDTH - 1:0] parallel_buff         = {ADDRESS_WIDTH{1'b0}};
    reg [DATA_WIDTH_LOG - 1:0] serial_data_counter  = 0;

    serial_parallel_2way #(
        .PORT_WIDTH(ADDRESS_WIDTH),
        .BIT_LENGTH(DATA_WIDTH)
    )ser_des_inst(
        .clk(clk), 
        .rstn(rstn), 
        .dv_in(serial_tx_start), 
        .invert_s2p(data_dir_inv_s2p), 
        .en(serial_rx_start),
        .bit_length(read_width),
        .dv_out(serial_dv),
        .serial_tx_done(serial_tx_done),
        .parallel_port(parallel_port_wire),
        .serial_port(data_bus_serial)
    );

    // tristate buffers
    assign parallel_port_wire = data_dir_inv_s2p ? parallel_buff : {DATA_WIDTH{1'bZ}};
    assign slave_busy = slave_busy_reg ? 1'b1 :1'bZ;

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

        end else begin
            case (state)
            IDLE: begin
                if (bus_req) begin
                    state <= MATCH_SID;
                    read_width <= 4'd2;
                    serial_rx_start <= 1;
                    slave_busy_reg <= 1'b1; 
                end
            end

            MATCH_SID: begin
                serial_rx_start <= 1'b0;

                if (serial_dv) begin
                    if (parallel_port_wire[1:0] == SELF_ID) begin
                        state <= ADDR_READ;
                        serial_rx_start <= 1'b1;
                        read_width <= ADDRESS_WIDTH;
                    end
                
                end
            end

            ADDR_READ: begin
                serial_rx_start <= 1'b0;

                if (serial_dv) begin
                    read_width <= DATA_WIDTH;
                    addr_buff <= parallel_port_wire[ADDRESS_WIDTH - 1:0];
                    serial_rx_start <= 1'b1;

                    if (rd_wrt) state <= RX_DATA_FROM_MS;
                    else begin
                        state <= BUSY_RD_FROM_MEM;
                        data_dir_inv_s2p <= 1'b1;
                    end
                end
            end

            RX_DATA_FROM_MS: begin
                if (serial_dv) begin
                    data_out_parellel <= parallel_port_wire;
                    state <= BUSY_WRT_TO_MEM;
                    write_en_internal <= 1'b1;
                end
            end

            BUSY_WRT_TO_MEM: begin
                write_en_internal <= 1'b0;
                if (module_dv) state <= IDLE;
            end

            BUSY_RD_FROM_MEM: begin
                if (module_dv) begin
                    parallel_buff <= data_in_parellel;
                    state <= DATA_READY;
                    slave_busy_reg <= 1'b0;
                end
            end

            DATA_READY: if (slave_busy) begin
                state <= TX_DATA_TO_MS;
                slave_busy_reg <= 1'b1;
                serial_tx_start <= 1'b1;
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
force -freeze sim:/slave/bus_req 0 0
force -freeze sim:/slave/module_dv 0 0
force -freeze sim:/slave/data_in_parellel 0 0
run
force -freeze sim:/slave/rstn St1 0
run
force -freeze sim:/slave/bus_req St1 0
run
force -freeze sim:/slave/bus_req St0 0
run*/