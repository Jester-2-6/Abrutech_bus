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
    parameter DATA_WIDTH = 8
)(
    input [ADDRESS_WIDTH - 1:0] addr_in,
    input clk, rstn, rd_wrt,
    input [DATA_WIDTH - 1:0] data_in_parellel,

    output reg ready = 1'b0, done = 1'b0, write_en_internal = 1'b0, //make done bidirectional
    output wire [DATA_WIDTH - 1:0] data_out_parellel,
    output wire [ADDRESS_WIDTH -1:0] addr_out,

    inout data_bus_serial
);

    localparam IDLE         = 3'd0;
    localparam WRITE_FETCH  = 3'd1;
    localparam WRITE_EXEC   = 3'd2;
    localparam READ_FETCH   = 3'd3;
    localparam DATA_READY   = 3'd4;
    localparam SERIAL_TX    = 3'd5;
    localparam CLEANUP      = 3'd6;

    localparam DATA_WIDTH_LOG = $clog2(DATA_WIDTH);

    wire addr_valid;
    reg [2:0] state = IDLE;

    reg serial_out_enable                              = 1'b0;
    reg serial_out_buff                                = 1'b0;

    reg [DATA_WIDTH - 1:0] parellel_out_buff           = {DATA_WIDTH{1'b0}};
    reg [DATA_WIDTH - 1:0] parellel_in_buff            = {DATA_WIDTH{1'b0}};

    reg [DATA_WIDTH_LOG - 1:0] serial_data_counter  = 0;

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

    // main execution
    always @(posedge clk, negedge rstn) begin
        if (rstn == 1'b0) begin
            //reset logic
            ready                   <= 1'b0;
            done                    <= 1'b0;
            serial_out_enable       <= 1'b0;
            state                   <= IDLE;
            parellel_out_buff       <= {DATA_WIDTH{1'b0}};
            parellel_in_buff        <= {DATA_WIDTH{1'b0}};
            serial_out_buff         <= 1'b0;
            serial_data_counter     <= {DATA_WIDTH_LOG{1'b0}};
            write_en_internal       <= 1'b0;

        end else begin
            case(state)

                IDLE: begin
                // need util line?
                    if (addr_valid & rd_wrt) state <= WRITE_FETCH;
                    else if (addr_valid) state <= READ_FETCH;
                end

                WRITE_FETCH: begin

                    parellel_out_buff[serial_data_counter]  <= data_bus_serial;
                    serial_data_counter                     <= serial_data_counter + 1;
                    // pull up data bus

                    if (serial_data_counter == DATA_WIDTH - 1) state <= WRITE_EXEC;
                end

                WRITE_EXEC: begin
                    write_en_internal   <= 1'b1;
                    // add done 
                    state               <= CLEANUP;  
                end

                READ_FETCH: begin
                    parellel_in_buff    <= data_in_parellel;
                    state               <= DATA_READY;
                end

                DATA_READY: begin
                    ready                   <= 1'b1;
                    if (addr_valid) state   <= SERIAL_TX;
                end

                SERIAL_TX: begin
                    ready                   <= 1'b0;
                    serial_out_enable       <= 1'b1;
                    serial_out_buff         <= parellel_in_buff[serial_data_counter];
                    serial_data_counter     <= serial_data_counter + 1;

                    if (serial_data_counter == DATA_WIDTH - 1) begin
                        state <= CLEANUP;
                        done <= 1'b1;
                    end
                end

                CLEANUP: begin
                    parellel_out_buff       <= {DATA_WIDTH{1'b0}};
                    parellel_in_buff        <= {DATA_WIDTH{1'b0}};
                    serial_out_buff         <= 1'b0;
                    serial_data_counter     <= {DATA_WIDTH_LOG{1'b0}};
                    done                    <= 1'b0;
                    write_en_internal       <= 1'b0;
                    serial_out_enable       <= 1'b0;
                    state                   <= IDLE;
                end
            endcase
        end
    end

endmodule 

// modelsim force vals
/*
force -freeze sim:/slave/addr_in 0 0
force -freeze sim:/slave/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/slave/rstn 1 0
force -freeze sim:/slave/rd_wrt 1 0
force -freeze sim:/slave/data_in_parellel 0 0*/